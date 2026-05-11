import Foundation

struct BackendEnvironment {
    let baseURL: URL

    static let shared = BackendEnvironment.load()

    private static func load() -> BackendEnvironment {
        if let override = ProcessInfo.processInfo.environment["BACKEND_URL"],
           let url = URL(string: override) {
            return BackendEnvironment(baseURL: url)
        }

        if let envURL = Bundle.main.url(forResource: ".env", withExtension: nil),
           let values = try? parseEnvFile(at: envURL),
           let rawBaseURL = values["BACKEND_URL"],
           let url = URL(string: rawBaseURL) {
            return BackendEnvironment(baseURL: url)
        }

        if let bundledURL = Bundle.main.url(forResource: "Backend", withExtension: "env"),
           let values = try? parseEnvFile(at: bundledURL),
           let rawBaseURL = values["BACKEND_URL"],
           let url = URL(string: rawBaseURL) {
            return BackendEnvironment(baseURL: url)
        }

        return BackendEnvironment(baseURL: URL(string: "http://localhost:5000")!)
    }

    private static func parseEnvFile(at url: URL) throws -> [String: String] {
        let contents = try String(contentsOf: url, encoding: .utf8)
        var values: [String: String] = [:]

        for rawLine in contents.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }

            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1]
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

            values[key] = value
        }

        return values
    }
}
