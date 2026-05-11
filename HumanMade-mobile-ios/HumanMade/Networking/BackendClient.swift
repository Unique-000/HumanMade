import Foundation
import UIKit

struct BackendMessageResponse: Decodable, Hashable {
    let mess: String
    let login: String?
}

struct BackendUploadResponse: Decodable, Hashable {
    let mess: String
    let code: String
}

private struct BackendErrorResponse: Decodable {
    let mess: String?
    let error: String?
}

struct BackendCheckMatch: Decodable, Identifiable, Hashable {
    let code: String
    let url: URL
    let localization: String?
    let takenAt: Date?
    let sha256: String?
    let phash: String?
    let txSignature: String?
    let distance: Int?

    var id: String { code }

    private enum CodingKeys: String, CodingKey {
        case code
        case url
        case localization
        case takenAt
        case sha256
        case phash
        case txSignature
        case distance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        url = try container.decode(URL.self, forKey: .url)
        localization = try container.decodeIfPresent(String.self, forKey: .localization)
        sha256 = try container.decodeIfPresent(String.self, forKey: .sha256)
        phash = try container.decodeIfPresent(String.self, forKey: .phash)
        txSignature = try container.decodeIfPresent(String.self, forKey: .txSignature)
        distance = try container.decodeIfPresent(Int.self, forKey: .distance)

        if let takenAtString = try container.decodeIfPresent(String.self, forKey: .takenAt) {
            takenAt = BackendDateParser.shared.date(from: takenAtString)
        } else {
            takenAt = nil
        }
    }
}

struct BackendCheckResponse: Decodable, Hashable {
    let exactMatch: Bool
    let similarMatch: Bool
    let matches: [BackendCheckMatch]
}

private struct BackendCheckEnvelope: Decodable {
    let exactMatch: Bool?
    let similarMatch: Bool?
    let matches: [BackendCheckMatch]?
    let mess: String?
    let error: String?
}

struct BackendImageRecord: Decodable, Identifiable, Hashable {
    let code: String?
    let url: URL
    let takenAt: Date?
    let localization: String?
    let sha256: String?
    let phash: String?
    let txSignature: String?
    let distance: Int?

    var id: String { code ?? url.absoluteString }

    private enum CodingKeys: String, CodingKey {
        case code
        case url
        case takenAt
        case localization
        case sha256
        case phash
        case txSignature
        case distance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        url = try container.decode(URL.self, forKey: .url)
        localization = try container.decodeIfPresent(String.self, forKey: .localization)
        sha256 = try container.decodeIfPresent(String.self, forKey: .sha256)
        phash = try container.decodeIfPresent(String.self, forKey: .phash)
        txSignature = try container.decodeIfPresent(String.self, forKey: .txSignature)
        distance = try container.decodeIfPresent(Int.self, forKey: .distance)

        if let takenAtString = try container.decodeIfPresent(String.self, forKey: .takenAt) {
            takenAt = BackendDateParser.shared.date(from: takenAtString)
        } else {
            takenAt = nil
        }
    }

    init(
        code: String? = nil,
        url: URL,
        takenAt: Date?,
        localization: String?,
        sha256: String? = nil,
        phash: String? = nil,
        txSignature: String? = nil,
        distance: Int?
    ) {
        self.code = code
        self.url = url
        self.takenAt = takenAt
        self.localization = localization
        self.sha256 = sha256
        self.phash = phash
        self.txSignature = txSignature
        self.distance = distance
    }
}

final class BackendClient {
    private enum UploadLimit {
        static let maxBytes = 4 * 1024 * 1024
        static let initialCompressionQuality: CGFloat = 0.88
        static let minimumCompressionQuality: CGFloat = 0.28
        static let compressionStep: CGFloat = 0.08
        static let resizeStep: CGFloat = 0.82
        static let minimumResizeDimension: CGFloat = 1200
        static let maximumInitialDimension: CGFloat = 2400
    }

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = BackendEnvironment.shared.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchImageRecord(for code: String) async throws -> BackendImageRecord {
        let request = try makeGETRequest(code: code)
        let record: BackendImageRecord = try await performRequest(request)
        return BackendImageRecord(
            code: code,
            url: record.url,
            takenAt: record.takenAt,
            localization: record.localization,
            sha256: record.sha256,
            phash: record.phash,
            txSignature: record.txSignature,
            distance: record.distance
        )
    }

    func registerUser() async throws -> BackendMessageResponse {
        let request = try makeRegisterRequest()
        return try await performRequest(request)
    }

    func loginUser(login: String) async throws -> BackendMessageResponse {
        try await performJSONUserAction(path: "login", login: login)
    }

    func checkImage(_ image: UIImage) async throws -> BackendImageRecord {
        let imageData = try prepareJPEGData(for: image)

        let request = try makeUploadRequest(imageData: imageData)
        let envelope: BackendCheckEnvelope = try await performRequest(request)

        let exactMatch = envelope.exactMatch ?? false
        let similarMatch = envelope.similarMatch ?? false

        guard exactMatch || similarMatch else {
            if let mess = envelope.mess?.lowercased(), mess.contains("no match") {
                throw BackendClientError.noMatchFound
            }

            if let error = envelope.error?.lowercased(), error.contains("no match") {
                throw BackendClientError.noMatchFound
            }

            if envelope.matches == nil, envelope.mess == nil, envelope.error == nil {
                throw BackendClientError.invalidResponse
            }

            throw BackendClientError.noMatchFound
        }

        guard let match = envelope.matches?.first else {
            throw BackendClientError.invalidResponse
        }

        return BackendImageRecord(
            code: match.code,
            url: match.url,
            takenAt: match.takenAt,
            localization: match.localization,
            sha256: match.sha256,
            phash: match.phash,
            txSignature: match.txSignature,
            distance: match.distance ?? (exactMatch ? 0 : nil)
        )
    }

    func uploadCapturedPhoto(
        at fileURL: URL,
        latitude: Double?,
        longitude: Double?,
        takenAt: Date,
        login: String
    ) async throws -> BackendUploadResponse {
        let fileData = try Data(contentsOf: fileURL)
        let imageData = try prepareJPEGData(from: fileData)
        let request = try makePhotoUploadRequest(
            imageData: imageData,
            latitude: latitude,
            longitude: longitude,
            takenAt: takenAt,
            login: login
        )

        return try await performRequest(request)
    }

    private func makeGETRequest(code: String) throws -> URLRequest {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            throw BackendClientError.invalidCode
        }

        let url = baseURL.appendingPathComponent("api/images").appendingPathComponent(trimmedCode)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func makeJSONUserRequest(path: String, login: String) throws -> URLRequest {
        let trimmedLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedLogin.count == 16 else {
            throw BackendClientError.invalidLogin
        }

        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("users")
            .appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["login": trimmedLogin], options: [])
        return request
    }

    private func makeRegisterRequest() throws -> URLRequest {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("users")
            .appendingPathComponent("register")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func makeUploadRequest(imageData: Data) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("api/images/check")
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = makeMultipartBody(
            fieldName: "file",
            fileName: "image.jpg",
            mimeType: "image/jpeg",
            fileData: imageData,
            boundary: boundary
        )
        return request
    }

    private func makePhotoUploadRequest(
        imageData: Data,
        latitude: Double?,
        longitude: Double?,
        takenAt: Date,
        login: String
    ) throws -> URLRequest {
        let trimmedLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedLogin.count == 16 else {
            throw BackendClientError.invalidLogin
        }

        let url = baseURL.appendingPathComponent("api/images/upload")
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(trimmedLogin, forHTTPHeaderField: "x-login")
        request.httpBody = makeMultipartBody(
            fieldName: "file",
            fileName: "image.jpg",
            mimeType: "image/jpeg",
            fileData: imageData,
            boundary: boundary,
            extraFields: [
                "login": trimmedLogin,
                "lat": latitude.map { String($0) },
                "lng": longitude.map { String($0) },
                "takenAt": iso8601Formatter.string(from: takenAt)
            ]
        )
        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    private func performJSONUserAction(path: String, login: String) async throws -> BackendMessageResponse {
        let request = try makeJSONUserRequest(path: path, login: login)
        return try await performRequest(request)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendClientError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8)
            throw BackendClientError.serverError(statusCode: httpResponse.statusCode, body: body)
        }
    }

    private func makeMultipartBody(
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data,
        boundary: String,
        extraFields: [String: String?] = [:]
    ) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        body.appendString("--\(boundary)\(lineBreak)")
        body.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\(lineBreak)")
        body.appendString("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
        body.append(fileData)
        body.appendString(lineBreak)

        for (key, value) in extraFields {
            guard let value else { continue }
            body.appendString("--\(boundary)\(lineBreak)")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
            body.appendString("\(value)\(lineBreak)")
        }

        body.appendString("--\(boundary)--\(lineBreak)")

        return body
    }

    private func prepareJPEGData(for image: UIImage) throws -> Data {
        let normalizedImage = image.normalizedForUpload()
        let preparedImage = normalizedImage.resizedToFit(maxDimension: UploadLimit.maximumInitialDimension)

        guard let imageData = preparedImage.jpegData(compressionQuality: UploadLimit.initialCompressionQuality) else {
            throw BackendClientError.unableToEncodeImage
        }

        return try prepareJPEGData(from: imageData, fallbackImage: preparedImage)
    }

    private func prepareJPEGData(from fileData: Data) throws -> Data {
        try prepareJPEGData(from: fileData, fallbackImage: UIImage(data: fileData))
    }

    private func prepareJPEGData(from imageData: Data, fallbackImage: UIImage?) throws -> Data {
        if imageData.count <= UploadLimit.maxBytes {
            return imageData
        }

        guard let fallbackImage else {
            throw BackendClientError.unableToEncodeImage
        }

        var workingImage = fallbackImage.resizedToFit(maxDimension: UploadLimit.maximumInitialDimension)
        var compressionQuality = UploadLimit.initialCompressionQuality

        if let encoded = workingImage.jpegData(compressionQuality: compressionQuality),
           encoded.count <= UploadLimit.maxBytes {
            return encoded
        }

        while compressionQuality > UploadLimit.minimumCompressionQuality {
            compressionQuality -= UploadLimit.compressionStep

            if let encoded = workingImage.jpegData(compressionQuality: compressionQuality),
               encoded.count <= UploadLimit.maxBytes {
                return encoded
            }
        }

        var resizeAttempt = 0
        while resizeAttempt < 6, max(workingImage.size.width, workingImage.size.height) > UploadLimit.minimumResizeDimension {
            workingImage = workingImage.resizedForUpload(scale: UploadLimit.resizeStep)
            if let encoded = workingImage.jpegData(compressionQuality: UploadLimit.minimumCompressionQuality),
               encoded.count <= UploadLimit.maxBytes {
                return encoded
            }
            resizeAttempt += 1
        }

        guard let finalData = workingImage.jpegData(compressionQuality: UploadLimit.minimumCompressionQuality),
              finalData.count <= UploadLimit.maxBytes else {
            throw BackendClientError.imageStillTooLarge
        }

        return finalData
    }

    enum BackendClientError: LocalizedError {
        case invalidCode
        case invalidLogin
        case invalidResponse
        case unableToEncodeImage
        case imageStillTooLarge
        case noMatchFound
        case serverError(statusCode: Int, body: String?)

        var errorDescription: String? {
            switch self {
            case .invalidCode:
                return "The code cannot be empty."
            case .invalidLogin:
                return "The login must be exactly 16 characters."
            case .invalidResponse:
                return "The backend returned an invalid response."
            case .unableToEncodeImage:
                return "The selected image could not be converted for upload."
            case .imageStillTooLarge:
                return "The image could not be compressed below 4 MB."
            case .noMatchFound:
                return "No matching image was found."
            case .serverError(let statusCode, let body):
                if let body, !body.isEmpty {
                    if let parsedMessage = BackendClient.serverMessage(from: body) {
                        return "The backend returned \(statusCode): \(parsedMessage)"
                    }

                    return "The backend returned \(statusCode): \(body)"
                }
                return "The backend returned \(statusCode)."
            }
        }
    }
}

private final class BackendDateParser {
    static let shared = BackendDateParser()

    private let formatter: DateFormatter

    private init() {
        formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    }

    func date(from string: String) -> Date? {
        if let date = formatter.date(from: string) {
            return date
        }

        let isoFormatter = ISO8601DateFormatter()
        return isoFormatter.date(from: string)
    }
}

private let iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

private extension BackendClient {
    static func serverMessage(from body: String) -> String? {
        guard let data = body.data(using: .utf8) else {
            return nil
        }

        if let decoded = try? JSONDecoder().decode(BackendErrorResponse.self, from: data) {
            if let mess = decoded.mess, !mess.isEmpty {
                return mess
            }
            if let error = decoded.error, !error.isEmpty {
                return error
            }
        }

        if let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let mess = payload["mess"] as? String, !mess.isEmpty {
                return mess
            }
            if let error = payload["error"] as? String, !error.isEmpty {
                return error
            }
        }

        return nil
    }
}

private extension UIImage {
    func normalizedForUpload() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension, longestSide > 0 else {
            return self
        }

        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func resizedForUpload(scale: CGFloat) -> UIImage {
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
