import SwiftUI
import UIKit

struct LoginRegisterOnboardingPage: View {
    let onAuthenticated: () -> Void

    private let backendClient = BackendClient()

    @AppStorage("userLogin") private var userLogin = ""
    @AppStorage("isAuthenticated") private var isAuthenticated = false

    @State private var login = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var generatedLogin: String?
    @State private var copiedConfirmationMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer(minLength: 20)

            Text("Sign in")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color(.label))

            Text("Use your 16 digit login to continue, or create a new one.")
                .font(.subheadline)
                .foregroundStyle(Color(.label).opacity(0.75))

            if let generatedLogin {
                generatedLoginCard(loginCode: generatedLogin)
            } else {
                loginEntryCard
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            if let copiedConfirmationMessage {
                Text(copiedConfirmationMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 12) {
                Button {
                    Task {
                        await performLogin()
                    }
                } label: {
                    actionButtonLabel(title: "Log In", isPrimary: true)
                }
                .disabled(!canSubmitLogin || isLoading || generatedLogin != nil)

                Button {
                    Task {
                        await performRegister()
                    }
                } label: {
                    actionButtonLabel(title: "Create Login", isPrimary: false)
                }
                .disabled(isLoading || generatedLogin != nil)
            }

            if isLoading {
                ProgressView()
                    .tint(Color(.label))
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .onChange(of: login) {
            sanitizeLogin()
            errorMessage = nil
            copiedConfirmationMessage = nil
        }
    }

    private var canSubmitLogin: Bool {
        login.count == 16
    }

    @MainActor
    private func performLogin() async {
        guard generatedLogin == nil else { return }

        guard canSubmitLogin else {
            errorMessage = "The login must be exactly 16 digits."
            return
        }

        isLoading = true
        errorMessage = nil
        copiedConfirmationMessage = nil

        do {
            let trimmedLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await backendClient.loginUser(login: trimmedLogin)

            userLogin = trimmedLogin
            isAuthenticated = true
            onAuthenticated()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func performRegister() async {
        guard generatedLogin == nil else { return }

        isLoading = true
        errorMessage = nil
        copiedConfirmationMessage = nil

        do {
            let response = try await backendClient.registerUser()

            guard let createdLogin = response.login?.trimmingCharacters(in: .whitespacesAndNewlines), createdLogin.count == 16 else {
                throw AuthRequestError.invalidResponse
            }

            generatedLogin = createdLogin
            login = createdLogin
            userLogin = createdLogin
            copiedConfirmationMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func continueAfterRegister() {
        guard let generatedLogin else { return }

        userLogin = generatedLogin
        isAuthenticated = true
        onAuthenticated()
    }

    private func copyGeneratedLogin(_ loginCode: String) {
        UIPasteboard.general.string = loginCode
        copiedConfirmationMessage = "Login code copied to clipboard."
    }

    private var loginEntryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            inputField(
                title: "Login",
                text: $login,
                keyboardType: .numberPad
            )

            Text("\(login.count)/16 digits")
                .font(.footnote)
                .foregroundStyle(login.count == 16 ? .green : Color(.label).opacity(0.6))

            Text("This 16 digit code is your only login. Do not share it with anyone.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.label).opacity(0.8))
        }
        .padding(18)
        .background(Color(.label).opacity(0.10), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func generatedLoginCard(loginCode: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your login code")
                .font(.headline)
                .foregroundStyle(Color(.label))

            Text(loginCode)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)

            Text("This code is the only way to log in. Keep it private and do not share it.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.label).opacity(0.8))

            HStack(spacing: 12) {
                Button {
                    copyGeneratedLogin(loginCode)
                } label: {
                    Text("Copy Code")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(Color(.label))
                        .background(Color(.label).opacity(0.14), in: Capsule())
                }

                Button {
                    continueAfterRegister()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(Color(.systemBackground))
                        .background(Color(.label), in: Capsule())
                }
            }
        }
        .padding(18)
        .background(Color(.label).opacity(0.10), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func sanitizeLogin() {
        let filtered = String(login.filter { !$0.isWhitespace })
        if filtered.count > 16 {
            login = String(filtered.prefix(16))
        } else if filtered != login {
            login = filtered
        }
    }

    private func inputField(
        title: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(keyboardType)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .foregroundStyle(Color(.label))
            .background(Color(.label).opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func actionButtonLabel(title: String, isPrimary: Bool) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(isPrimary ? Color(.systemBackground) : Color(.label))
            .background(isPrimary ? Color(.label) : Color(.label).opacity(0.14), in: Capsule())
    }

    private enum AuthRequestError: LocalizedError {
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "The backend returned an invalid response."
            }
        }
    }
}

struct OnboardingView1_Previews: PreviewProvider {
    static var previews: some View {
        LoginRegisterOnboardingPage(onAuthenticated: {})
    }
}
