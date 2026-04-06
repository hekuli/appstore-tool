@preconcurrency import AppStoreServerLibrary
import Foundation

enum AppStoreToolError: LocalizedError {
    case notConfigured(String)
    case missingRequiredOption(String)
    case invalidEnvironment(String)
    case keyFileNotFound(String)
    case keyFileUnreadable(String)
    case certificateLoadFailed(String)
    case apiError(statusCode: Int?, apiError: APIError?, causedBy: Error?)
    case verificationFailed(VerificationError)
    case paginationFailed(String)
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured(let name):
            return "Missing required setting: \(name). Run 'appstore-tool config' to set up, or provide via --\(name) flag / environment variable."
        case .missingRequiredOption(let name):
            return "Missing required option: \(name). Provide via flag or environment variable."
        case .invalidEnvironment(let value):
            return "Invalid environment '\(value)'. Must be 'sandbox' or 'production'."
        case .keyFileNotFound(let path):
            return "Private key file not found: \(path)"
        case .keyFileUnreadable(let path):
            return "Could not read private key file: \(path)"
        case .certificateLoadFailed(let detail):
            return "Failed to load Apple root certificates: \(detail)"
        case .apiError(let statusCode, let apiError, let causedBy):
            var parts: [String] = ["App Store Server API error"]
            if let code = statusCode { parts.append("HTTP \(code)") }
            if let err = apiError { parts.append("\(err)") }
            if let cause = causedBy { parts.append(cause.localizedDescription) }
            if apiError == nil, statusCode != nil {
                parts.append("(run with --debug for details)")
            }
            return parts.joined(separator: " - ")
        case .verificationFailed(let error):
            return "JWS verification failed: \(error)"
        case .paginationFailed(let detail):
            return "Pagination error: \(detail)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        }
    }
}

struct GenericError: LocalizedError {
    let msg: String
    init(_ msg: String) { self.msg = msg }
    var errorDescription: String? { msg }
}
