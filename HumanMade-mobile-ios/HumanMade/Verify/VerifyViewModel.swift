import Combine
import Foundation
import UIKit

@MainActor
final class VerifyViewModel: ObservableObject {
    @Published var code: String = ""
    @Published var verificationRecord: BackendImageRecord?
    @Published var isLoadingCode = false
    @Published var isUploadingImage = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let backendClient: BackendClient
    private var codeLookupTask: Task<Void, Never>?
    private var imageUploadTask: Task<Void, Never>?
    private var lastRequestedCode: String?

    init(backendClient: BackendClient = BackendClient()) {
        self.backendClient = backendClient
    }

    func updateCode(_ newValue: String) {
        let normalized = normalizeCode(newValue)
        guard normalized != code else { return }

        code = normalized
        errorMessage = nil
        infoMessage = nil
        verificationRecord = nil

        if normalized.count == 6 {
            scheduleCodeLookup()
        } else {
            codeLookupTask?.cancel()
            lastRequestedCode = nil
        }
    }

    func submitCodeIfPossible() {
        guard code.count == 6 else { return }
        scheduleCodeLookup()
    }

    func handlePickedImage(_ image: UIImage) {
        errorMessage = nil
        uploadImage(image)
    }

    private func scheduleCodeLookup() {
        guard lastRequestedCode != code else { return }

        codeLookupTask?.cancel()
        let currentCode = code

        codeLookupTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await self?.fetchCodeResult(for: currentCode)
        }
    }

    private func fetchCodeResult(for code: String) async {
        guard lastRequestedCode != code else { return }

        isLoadingCode = true
        errorMessage = nil
        infoMessage = nil
        lastRequestedCode = code

        do {
            let record = try await backendClient.fetchImageRecord(for: code)
            verificationRecord = record
            isLoadingCode = false
        } catch {
            isLoadingCode = false
            if isNotFound(error) {
                verificationRecord = nil
                infoMessage = "No image found for that code."
                return
            }

            errorMessage = error.localizedDescription
        }
    }

    private func uploadImage(_ image: UIImage) {
        imageUploadTask?.cancel()
        isUploadingImage = true
        errorMessage = nil
        infoMessage = nil

        imageUploadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let record = try await backendClient.checkImage(image)
                self.verificationRecord = record
                self.isUploadingImage = false
            } catch {
                self.isUploadingImage = false
                if self.isNoMatch(error) {
                    self.verificationRecord = nil
                    self.infoMessage = "No matching image was found for that photo."
                    return
                }

                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func normalizeCode(_ value: String) -> String {
        let lettersAndDigits = value
            .filter { $0.isLetter || $0.isNumber }

        return String(lettersAndDigits.prefix(6))
    }

    private func isNoMatch(_ error: Error) -> Bool {
        guard let backendError = error as? BackendClient.BackendClientError else { return false }
        if case .noMatchFound = backendError {
            return true
        }
        return false
    }

    private func isNotFound(_ error: Error) -> Bool {
        guard let backendError = error as? BackendClient.BackendClientError else { return false }
        if case .serverError(let statusCode, _) = backendError, statusCode == 404 {
            return true
        }
        return false
    }
}
