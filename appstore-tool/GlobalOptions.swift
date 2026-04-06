import ArgumentParser
import AppStoreServerLibrary
import Foundation

struct GlobalOptions: ParsableArguments {
    @Option(name: [.long, .customShort("e")], help: "Environment: sandbox or production (default: production).")
    var environment: String?

    @Option(name: [.long, .customShort("k")], help: "Path to .p8 private key file.")
    var keyPath: String?

    @Option(name: .long, help: "App Store Connect API Key ID.")
    var keyId: String?

    @Option(name: .long, help: "Issuer ID from App Store Connect.")
    var issuerId: String?

    @Option(name: [.long, .customShort("b")], help: "App bundle identifier.")
    var bundleId: String?

    @Option(name: .long, help: "Numeric Apple ID of the app.")
    var appAppleId: Int64?

    @Option(name: [.long, .customShort("o")], help: "Output format: table, json, or csv (default: table).")
    var output: OutputFormat?

    @Flag(name: [.long, .customShort("v")], help: "Verbose output.")
    var verbose: Bool = false

    @Flag(name: .long, help: "Print request details and full error responses for troubleshooting.")
    var debug: Bool = false

    @Option(name: .long, help: "Path to directory containing Apple root .cer files.")
    var certsDir: String?

    /// Resolution order: CLI flag > environment variable > stored config (~/.appstore-tool/config)
    func resolved() throws -> ResolvedConfig {
        let env = ProcessInfo.processInfo.environment
        let auth = StoredConfig.load()?.auth

        let envString = environment ?? env["AST_ENVIRONMENT"] ?? auth?.environment ?? "production"
        guard let resolvedEnv = Environment(rawValue: envString.capitalized) else {
            throw AppStoreToolError.invalidEnvironment(envString)
        }

        let resolvedKeyPath = keyPath ?? env["AST_KEY_PATH"] ?? auth?.keyPath
        guard let keyFile = resolvedKeyPath else {
            throw AppStoreToolError.notConfigured("key-path")
        }
        let expandedKeyPath = NSString(string: keyFile).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedKeyPath) else {
            throw AppStoreToolError.keyFileNotFound(expandedKeyPath)
        }
        let signingKey: String
        do {
            signingKey = try String(contentsOfFile: expandedKeyPath, encoding: .utf8)
        } catch {
            throw AppStoreToolError.keyFileUnreadable(expandedKeyPath)
        }

        guard let resolvedKeyId = keyId ?? env["AST_KEY_ID"] ?? auth?.keyId else {
            throw AppStoreToolError.notConfigured("key-id")
        }
        guard let resolvedIssuerId = issuerId ?? env["AST_ISSUER_ID"] ?? auth?.issuerId else {
            throw AppStoreToolError.notConfigured("issuer-id")
        }
        guard let resolvedBundleId = bundleId ?? env["AST_BUNDLE_ID"] ?? auth?.bundleId else {
            throw AppStoreToolError.notConfigured("bundle-id")
        }

        let resolvedAppAppleId: Int64?
        if let id = appAppleId {
            resolvedAppAppleId = id
        } else if let idStr = env["AST_APP_APPLE_ID"], let id = Int64(idStr) {
            resolvedAppAppleId = id
        } else {
            resolvedAppAppleId = auth?.appAppleId
        }

        let resolvedCertsDir = certsDir ?? env["AST_CERTS_DIR"] ?? auth?.certsDir ?? "~/.appstore-tool/certs"
        let resolvedOutput = output ?? .table

        return ResolvedConfig(
            environment: resolvedEnv,
            signingKey: signingKey,
            keyId: resolvedKeyId,
            issuerId: resolvedIssuerId,
            bundleId: resolvedBundleId,
            appAppleId: resolvedAppAppleId,
            certsDir: resolvedCertsDir,
            outputFormat: resolvedOutput,
            verbose: verbose,
            debug: debug
        )
    }
}

enum OutputFormat: String, ExpressibleByArgument, Sendable {
    case table
    case json
    case csv
}
