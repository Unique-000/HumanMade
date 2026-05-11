import AVFoundation
import CoreLocation
import Combine
import Foundation

final class CameraSessionManager: NSObject, ObservableObject {
    enum FlashMode: String, CaseIterable, Identifiable {
        case auto
        case on
        case off

        var id: String { rawValue }

        var title: String {
            switch self {
            case .auto: return "Auto"
            case .on: return "On"
            case .off: return "Off"
            }
        }

        var symbolName: String {
            switch self {
            case .auto: return "sparkles"
            case .on: return "bolt.fill"
            case .off: return "bolt.slash.fill"
            }
        }

        var avFlashMode: AVCaptureDevice.FlashMode {
            switch self {
            case .auto: return .auto
            case .on: return .on
            case .off: return .off
            }
        }
    }

    @Published private(set) var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published private(set) var isSessionRunning = false
    @Published private(set) var isConfigured = false
    @Published private(set) var activeCameraPosition: AVCaptureDevice.Position = .back
    @Published private(set) var isFlashSupported = false
    @Published private(set) var isCapturingPhoto = false
    @Published private(set) var isUploadingToBackend = false
    @Published private(set) var lastCapturedPhotoURL: URL?
    @Published private(set) var currentLocation: CLLocation?
    @Published var selectedFlashMode: FlashMode = .auto
    @Published var errorMessage: String?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.unique-000.humanmade.camera.session")
    private let locationManager = CLLocationManager()
    private let photoOutput = AVCapturePhotoOutput()
    private let photoStore: CapturedPhotoStore
    private let backendClient = BackendClient()
    private var videoInput: AVCaptureDeviceInput?
    private var currentDevice: AVCaptureDevice?
    private var isSessionConfigured = false
    private var captureDelegates: [CameraPhotoCaptureDelegate] = []

    init(photoStore: CapturedPhotoStore) {
        self.photoStore = photoStore
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var canSwitchCameras: Bool {
        hasCamera(for: .front) && hasCamera(for: .back)
    }

    var isCameraAvailable: Bool {
        hasCamera(for: .front) || hasCamera(for: .back)
    }

    var canCapturePhoto: Bool {
        authorizationStatus == .authorized && isConfigured && isSessionRunning && !isCapturingPhoto
    }

    func refreshAuthorizationAndStartIfNeeded() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        requestLocationAuthorizationIfNeeded()

        switch status {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self.startSession()
                    } else {
                        self.errorMessage = "Camera access was denied."
                    }
                }
            }
        case .denied, .restricted:
            stopSession()
            DispatchQueue.main.async {
                self.errorMessage = "Camera access is unavailable."
            }
        @unknown default:
            stopSession()
            DispatchQueue.main.async {
                self.errorMessage = "Unknown camera authorization state."
            }
        }
    }

    func startSession() {
        guard authorizationStatus == .authorized else { return }
        requestLocationAuthorizationIfNeeded()

        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.isSessionConfigured {
                self.configureSession()
            }

            guard self.isSessionConfigured else { return }

            if !self.session.isRunning {
                self.session.startRunning()
            }

            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if self.session.isRunning {
                self.session.stopRunning()
            }

            DispatchQueue.main.async {
                self.isSessionRunning = false
                self.isCapturingPhoto = false
            }
        }
    }

    func switchCamera() {
        guard canSwitchCameras else {
            DispatchQueue.main.async {
                self.errorMessage = "This device only exposes one camera."
            }
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            let targetPosition: AVCaptureDevice.Position = self.activeCameraPosition == .back ? .front : .back
            self.reconfigureSession(for: targetPosition)
        }
    }

    func selectFlashMode(_ mode: FlashMode) {
        DispatchQueue.main.async {
            self.selectedFlashMode = mode
        }
    }

    func capturePhoto() {
        guard canCapturePhoto else {
            DispatchQueue.main.async {
                self.errorMessage = "The camera is not ready yet."
            }
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            guard !self.isCapturingPhoto else { return }

            let settings = AVCapturePhotoSettings()
            settings.flashMode = self.isFlashSupported ? self.selectedFlashMode.avFlashMode : .off

            DispatchQueue.main.async {
                self.isCapturingPhoto = true
                self.errorMessage = nil
            }

            var delegate: CameraPhotoCaptureDelegate?
            delegate = CameraPhotoCaptureDelegate(photoStore: self.photoStore) { [weak self, weak delegate] result in
                guard let self else { return }

                self.sessionQueue.async {
                    if let delegate {
                        self.captureDelegates.removeAll { $0 === delegate }
                    }
                }

                DispatchQueue.main.async {
                    self.isCapturingPhoto = false

                    switch result {
                    case .success(let photo):
                        self.lastCapturedPhotoURL = photo.url
                        self.errorMessage = nil
                        self.uploadSavedPhoto(photo)
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }

            guard let delegate else { return }

            self.captureDelegates.append(delegate)
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    private func requestLocationAuthorizationIfNeeded() {
        let status = locationManager.authorizationStatus

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            DispatchQueue.main.async {
                self.currentLocation = self.locationManager.location
            }
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationManager.stopUpdatingLocation()
        @unknown default:
            locationManager.stopUpdatingLocation()
        }
    }

    private func uploadSavedPhoto(_ photo: CapturedPhoto) {
        let location = currentLocation
        let login = UserDefaults.standard.string(forKey: "userLogin")?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let login, login.count == 16 else {
            DispatchQueue.main.async {
                self.isUploadingToBackend = false
                self.errorMessage = "You need to log in again before uploading photos."
            }
            return
        }

        DispatchQueue.main.async {
            self.isUploadingToBackend = true
        }

        Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await backendClient.uploadCapturedPhoto(
                    at: photo.url,
                    latitude: location?.coordinate.latitude,
                    longitude: location?.coordinate.longitude,
                    takenAt: photo.createdAt,
                    login: login
                )

                let updatedPhoto = try photoStore.updateCode(response.code, for: photo)

                await MainActor.run {
                    self.isUploadingToBackend = false
                    self.lastCapturedPhotoURL = updatedPhoto.url
                }
            } catch {
                await MainActor.run {
                    self.isUploadingToBackend = false
                    self.errorMessage = "Saved locally, but backend upload failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        defer {
            session.commitConfiguration()
        }

        guard let device = initialCameraDevice() else {
            DispatchQueue.main.async {
                self.errorMessage = "No camera hardware is available on this device."
                self.isConfigured = false
            }
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            guard session.canAddInput(input) else {
                throw CameraError.cannotAddInput
            }

            guard session.canAddOutput(photoOutput) else {
                throw CameraError.cannotAddOutput
            }

            session.addInput(input)
            session.addOutput(photoOutput)

            videoInput = input
            currentDevice = device
            isSessionConfigured = true

            DispatchQueue.main.async {
                self.activeCameraPosition = device.position
                self.isFlashSupported = device.hasFlash
                self.isConfigured = true
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isConfigured = false
            }
            isSessionConfigured = false
        }
    }

    private func reconfigureSession(for position: AVCaptureDevice.Position) {
        let previousInput = videoInput
        let previousDevice = currentDevice
        let previousFlashSupport = isFlashSupported

        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        if let input = previousInput {
            session.removeInput(input)
        }

        guard let device = bestCameraDevice(for: position) else {
            restorePreviousCameraInput(previousInput, previousDevice: previousDevice, previousFlashSupport: previousFlashSupport)
            DispatchQueue.main.async {
                self.errorMessage = "The requested camera is not available."
            }
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            guard session.canAddInput(input) else {
                throw CameraError.cannotAddInput
            }

            session.addInput(input)
            videoInput = input
            currentDevice = device

            DispatchQueue.main.async {
                self.activeCameraPosition = device.position
                self.isFlashSupported = device.hasFlash
                self.errorMessage = nil
            }
        } catch {
            restorePreviousCameraInput(previousInput, previousDevice: previousDevice, previousFlashSupport: previousFlashSupport)
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func bestCameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            return device
        }

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera,
                .builtInTrueDepthCamera,
                .builtInUltraWideCamera
            ],
            mediaType: .video,
            position: position
        )

        return discovery.devices.first
    }

    private func initialCameraDevice() -> AVCaptureDevice? {
        bestCameraDevice(for: .back) ?? bestCameraDevice(for: .front)
    }

    private func hasCamera(for position: AVCaptureDevice.Position) -> Bool {
        bestCameraDevice(for: position) != nil
    }

    private func restorePreviousCameraInput(
        _ input: AVCaptureDeviceInput?,
        previousDevice: AVCaptureDevice?,
        previousFlashSupport: Bool
    ) {
        guard let input, let previousDevice else { return }

        if session.canAddInput(input) {
            session.addInput(input)
            videoInput = input
            currentDevice = previousDevice

            DispatchQueue.main.async {
                self.activeCameraPosition = previousDevice.position
                self.isFlashSupported = previousFlashSupport
            }
        }
    }

    private enum CameraError: LocalizedError {
        case cannotAddInput
        case cannotAddOutput

        var errorDescription: String? {
            switch self {
            case .cannotAddInput:
                return "The camera input could not be added to the session."
            case .cannotAddOutput:
                return "The photo output could not be added to the session."
            }
        }
    }
}

extension CameraSessionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocationAuthorizationIfNeeded()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Location unavailable: \(error.localizedDescription)"
        }
    }
}
