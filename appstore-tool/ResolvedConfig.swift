import AppStoreServerLibrary

struct ResolvedConfig: @unchecked Sendable {
    let environment: Environment
    let signingKey: String
    let keyId: String
    let issuerId: String
    let bundleId: String
    let appAppleId: Int64?
    let certsDir: String
    let outputFormat: OutputFormat
    let verbose: Bool
    let debug: Bool
}

extension ResolvedConfig: CustomStringConvertible {
    var description: String {
        """
        Environment:  \(environment.rawValue)
        Key ID:       \(keyId)
        Issuer ID:    \(issuerId)
        Bundle ID:    \(bundleId)
        App Apple ID: \(appAppleId.map(String.init) ?? "not set")
        Certs Dir:    \(certsDir)
        Signing Key:  <REDACTED>
        """
    }
}
