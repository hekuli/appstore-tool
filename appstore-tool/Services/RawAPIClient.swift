import AppStoreServerLibrary
import CryptoKit
import Foundation

/// Lightweight API client that makes direct HTTP requests to the App Store Server API.
/// Bypasses the library for endpoints where we need full error details.
struct RawAPIClient: Sendable {
    let baseURL: String
    let token: String

    init(config: ResolvedConfig) throws {
        self.baseURL = config.environment == .production
            ? "https://api.storekit.itunes.apple.com"
            : "https://api.storekit-sandbox.itunes.apple.com"
        self.token = try JWTSigner.sign(
            keyPEM: config.signingKey,
            keyId: config.keyId,
            issuerId: config.issuerId,
            bundleId: config.bundleId
        )
    }

    struct RawResponse: Sendable {
        let statusCode: Int
        let body: Foundation.Data
        var bodyString: String { String(data: body, encoding: .utf8) ?? "<binary>" }
    }

    func post(path: String, body: any Encodable & Sendable, debug: Bool = false) async throws -> RawResponse {
        let urlString = baseURL + path
        guard let url = URL(string: urlString) else {
            throw AppStoreToolError.invalidURL(urlString)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(body)
        request.httpBody = bodyData

        if debug {
            DebugLog.log("POST \(url.absoluteString)")
            if let str = String(data: bodyData, encoding: .utf8) {
                DebugLog.log("Body: \(str)")
            }
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppStoreToolError.apiError(statusCode: nil, apiError: nil, causedBy: nil)
        }

        if debug {
            DebugLog.log("Response: HTTP \(httpResponse.statusCode)")
            if httpResponse.statusCode >= 400, let str = String(data: data, encoding: .utf8) {
                DebugLog.log("Response body: \(str)")
            }
        }

        return RawResponse(statusCode: httpResponse.statusCode, body: data)
    }
}

extension RawAPIClient.RawResponse {
    func throwOnError() throws {
        guard statusCode < 200 || statusCode >= 300 else { return }
        if let errorInfo = try? JSONDecoder().decode(ErrorPayload.self, from: body) {
            let codeStr = errorInfo.errorCode.map { "code \($0)" } ?? "no code"
            let msg = errorInfo.errorMessage ?? "no message"
            throw AppStoreToolError.apiError(
                statusCode: statusCode,
                apiError: errorInfo.errorCode.flatMap { APIError(rawValue: $0) },
                causedBy: GenericError("\(codeStr): \(msg)")
            )
        }
        throw AppStoreToolError.apiError(statusCode: statusCode, apiError: nil, causedBy: GenericError(bodyString))
    }
}

// MARK: - ES256 JWT signer using CryptoKit

private enum JWTSigner {
    static func sign(keyPEM: String, keyId: String, issuerId: String, bundleId: String) throws -> String {
        let privateKey = try P256.Signing.PrivateKey(pemRepresentation: keyPEM)
        let now = Int(Date().timeIntervalSince1970)

        let header = #"{"alg":"ES256","kid":"\#(keyId)","typ":"JWT"}"#
        let payload = #"{"iss":"\#(issuerId)","iat":\#(now),"exp":\#(now + 300),"aud":"appstoreconnect-v1","bid":"\#(bundleId)"}"#

        let headerB64 = base64url(Foundation.Data(header.utf8))
        let payloadB64 = base64url(Foundation.Data(payload.utf8))
        let signingInput = Foundation.Data("\(headerB64).\(payloadB64)".utf8)

        let signature = try privateKey.signature(for: signingInput)
        let sigB64 = base64url(signature.rawRepresentation)

        return "\(headerB64).\(payloadB64).\(sigB64)"
    }

    private static func base64url(_ data: Foundation.Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
