import AVFoundation
import SwiftUI
import UIKit

struct CameraView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var camera: CameraSessionManager

    init(photoStore: CapturedPhotoStore) {
        _camera = StateObject(wrappedValue: CameraSessionManager(photoStore: photoStore))
    }

    var body: some View {
        ZStack {
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.45), .black.opacity(0.15), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            overlayContent
        }
        .task {
            camera.refreshAuthorizationAndStartIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                camera.refreshAuthorizationAndStartIfNeeded()
            case .inactive, .background:
                camera.stopSession()
            @unknown default:
                break
            }
        }
        .onDisappear {
            camera.stopSession()
        }
        .background(Color.black)
    }

    @ViewBuilder
    private var overlayContent: some View {
        VStack(spacing: 0) {
            topControls
                .padding(.top, 12)
                .padding(.horizontal, 16)
            Spacer()
            bottomControls
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
    }

    private var topControls: some View {
        HStack(alignment: .center) {
            Button {
                camera.switchCamera()
            } label: {
                Image(systemName: "camera.rotate")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Switch camera")
            .disabled(!camera.canSwitchCameras)
            .opacity(camera.canSwitchCameras ? 1 : 0.45)

            Spacer()

            Menu {
                ForEach(CameraSessionManager.FlashMode.allCases) { mode in
                    Button {
                        camera.selectFlashMode(mode)
                    } label: {
                        Label(mode.title, systemImage: mode.symbolName)
                    }
                }
            } label: {
                Label(camera.selectedFlashMode.title, systemImage: camera.selectedFlashMode.symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .accessibilityLabel("Flash mode")
            .disabled(!camera.isFlashSupported)
            .opacity(camera.isFlashSupported ? 1 : 0.45)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 14) {
            statusMessage
            captureButton
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        if camera.authorizationStatus == .notDetermined {
            statusCard(title: "Requesting camera access", message: "Allow access to show the live camera feed.")
        } else if camera.authorizationStatus == .denied || camera.authorizationStatus == .restricted {
            permissionCard
        } else if !camera.isCameraAvailable {
            statusCard(title: "No camera available", message: "This device or simulator does not expose a usable camera.")
        } else if let message = camera.errorMessage {
            statusCard(title: "Camera error", message: message)
        } else if camera.isCapturingPhoto {
            hintCard("Capturing photo...")
        } else if camera.isUploadingToBackend {
            hintCard("Uploading...")
        } else if !camera.isConfigured || !camera.isSessionRunning {
            statusCard(title: "Starting camera", message: "Hold on while the live preview comes online.")
        } else if !camera.isFlashSupported {
            hintCard("Flash is only available with a back camera.")
        } else if let lastURL = camera.lastCapturedPhotoURL {
            hintCard("Saved \(lastURL.lastPathComponent)")
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Camera access is off")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Open Settings and allow camera access to use the live preview.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

            Button {
                openSettings()
            } label: {
                Text("Open Settings")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.16), in: Capsule())
            }
            .foregroundStyle(.white)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var captureButton: some View {
        Button {
            camera.capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.96))
                    .frame(width: 76, height: 76)

                Circle()
                    .stroke(.black.opacity(0.16), lineWidth: 4)
                    .frame(width: 76, height: 76)

                if camera.isCapturingPhoto {
                    ProgressView()
                        .tint(.black)
                } else {
                    Circle()
                        .fill(.black)
                        .frame(width: 28, height: 28)
                        .opacity(camera.canCapturePhoto ? 1 : 0.65)
                }
            }
            .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        }
        .disabled(!camera.canCapturePhoto)
        .opacity(camera.canCapturePhoto ? 1 : 0.55)
        .accessibilityLabel("Capture photo")
    }

    private func statusCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func hintCard(_ message: String) -> some View {
        Text(message)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white.opacity(0.95))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.black.opacity(0.45), in: Capsule())
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(photoStore: CapturedPhotoStore())
    }
}
