import AVFoundation
import Foundation

final class CameraPhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let photoStore: CapturedPhotoStore
    private let completion: (Result<CapturedPhoto, Error>) -> Void

    init(photoStore: CapturedPhotoStore, completion: @escaping (Result<CapturedPhoto, Error>) -> Void) {
        self.photoStore = photoStore
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            completion(.failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            completion(.failure(CaptureError.missingData))
            return
        }

        do {
            let savedPhoto = try photoStore.savePhoto(data: data)
            completion(.success(savedPhoto))
        } catch {
            completion(.failure(error))
        }
    }

    private enum CaptureError: LocalizedError {
        case missingData

        var errorDescription: String? {
            switch self {
            case .missingData:
                return "The captured photo data could not be read."
            }
        }
    }
}
