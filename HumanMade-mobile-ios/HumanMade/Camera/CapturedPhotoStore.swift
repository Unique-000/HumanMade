import Combine
import Foundation
import UIKit

struct CapturedPhoto: Identifiable, Hashable {
    let url: URL
    let createdAt: Date
    let code: String?

    var id: URL { url }
}

private struct CapturedPhotoMetadata: Codable {
    let code: String?
}

final class CapturedPhotoStore: ObservableObject {
    @Published private(set) var photos: [CapturedPhoto] = []

    private let fileManager = FileManager.default
    private let applicationFolderName = "HumanMade"
    private let photosFolderName = "CapturedPhotos"

    init() {
        reload()
    }

    func reload() {
        do {
            let loadedPhotos = try loadPhotos()
            DispatchQueue.main.async {
                self.photos = loadedPhotos
            }
        } catch {
            DispatchQueue.main.async {
                self.photos = []
            }
        }
    }

    func savePhoto(data: Data) throws -> CapturedPhoto {
        let directoryURL = try ensurePhotosDirectory()
        let fileURL = directoryURL.appendingPathComponent(Self.makeFilename(), isDirectory: false)

        try data.write(to: fileURL, options: .atomic)
        try excludeFromBackup(at: fileURL)

        let photo = CapturedPhoto(
            url: fileURL,
            createdAt: (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date(),
            code: nil
        )

        reload()
        return photo
    }

    func updateCode(_ code: String, for photo: CapturedPhoto) throws -> CapturedPhoto {
        let metadataURL = metadataURL(for: photo.url)
        let metadata = CapturedPhotoMetadata(code: code)
        let encoded = try JSONEncoder().encode(metadata)
        try encoded.write(to: metadataURL, options: .atomic)
        try excludeFromBackup(at: metadataURL)

        let updatedPhoto = CapturedPhoto(url: photo.url, createdAt: photo.createdAt, code: code)
        reload()
        return updatedPhoto
    }

    func deletePhoto(_ photo: CapturedPhoto) throws {
        guard fileManager.fileExists(atPath: photo.url.path) else {
            reload()
            return
        }

        try fileManager.removeItem(at: photo.url)
        let metadataURL = metadataURL(for: photo.url)
        if fileManager.fileExists(atPath: metadataURL.path) {
            try? fileManager.removeItem(at: metadataURL)
        }
        reload()
    }

    private func loadPhotos() throws -> [CapturedPhoto] {
        let directoryURL = try ensurePhotosDirectory()
        let urls = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )

        return urls.compactMap { url in
            guard isSupportedPhotoFile(url) else { return nil }

            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
            let date = values?.contentModificationDate ?? values?.creationDate ?? Date.distantPast
            let code = loadCode(for: url)
            return CapturedPhoto(url: url, createdAt: date, code: code)
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    private func ensurePhotosDirectory() throws -> URL {
        guard let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw StoreError.missingApplicationSupportDirectory
        }

        let appDirectoryURL = applicationSupportURL.appendingPathComponent(applicationFolderName, isDirectory: true)
        let photosDirectoryURL = appDirectoryURL.appendingPathComponent(photosFolderName, isDirectory: true)

        if !fileManager.fileExists(atPath: photosDirectoryURL.path) {
            try fileManager.createDirectory(at: photosDirectoryURL, withIntermediateDirectories: true)
        }

        try excludeFromBackup(at: appDirectoryURL)
        try excludeFromBackup(at: photosDirectoryURL)

        return photosDirectoryURL
    }

    private func excludeFromBackup(at url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }

    private func isSupportedPhotoFile(_ url: URL) -> Bool {
        ["jpg", "jpeg", "heic", "png"].contains(url.pathExtension.lowercased())
    }

    private func loadCode(for photoURL: URL) -> String? {
        let metadataURL = metadataURL(for: photoURL)
        guard let data = try? Data(contentsOf: metadataURL) else {
            return nil
        }

        return try? JSONDecoder().decode(CapturedPhotoMetadata.self, from: data).code
    }

    private func metadataURL(for photoURL: URL) -> URL {
        photoURL.deletingPathExtension().appendingPathExtension("json")
    }

    private static func makeFilename() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return "capture-\(formatter.string(from: Date()))-\(UUID().uuidString).jpg"
    }

    private enum StoreError: LocalizedError {
        case missingApplicationSupportDirectory

        var errorDescription: String? {
            switch self {
            case .missingApplicationSupportDirectory:
                return "The Application Support directory could not be located."
            }
        }
    }
}
