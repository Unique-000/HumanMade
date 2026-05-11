import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PhotoLibraryPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, onCancel: onCancel)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onImagePicked: (UIImage) -> Void
        private let onCancel: () -> Void

        init(onImagePicked: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                onCancel()
                return
            }

            let provider = result.itemProvider
            guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
                onCancel()
                return
            }

            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] url, error in
                guard let url else {
                    DispatchQueue.main.async {
                        self?.onCancel()
                    }
                    return
                }

                do {
                    let data = try Data(contentsOf: url)
                    guard let image = UIImage(data: data) else {
                        DispatchQueue.main.async {
                            self?.onCancel()
                        }
                        return
                    }

                    DispatchQueue.main.async {
                        self?.onImagePicked(image)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.onCancel()
                    }
                }
            }
        }

        func pickerDidCancel(_ picker: PHPickerViewController) {
            onCancel()
        }
    }
}
