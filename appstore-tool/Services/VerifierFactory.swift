import AppStoreServerLibrary
import Foundation

enum VerifierFactory {
    static func makeVerifier(config: ResolvedConfig) throws -> SignedDataVerifier {
        let certsPath = NSString(string: config.certsDir).expandingTildeInPath
        let certsURL = URL(fileURLWithPath: certsPath, isDirectory: true)

        guard FileManager.default.fileExists(atPath: certsPath) else {
            throw AppStoreToolError.certificateLoadFailed("Directory not found: \(certsPath)")
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: certsURL,
            includingPropertiesForKeys: nil
        )
        let cerFiles = contents.filter { $0.pathExtension == "cer" }
        guard !cerFiles.isEmpty else {
            throw AppStoreToolError.certificateLoadFailed("No .cer files found in \(certsPath)")
        }

        let certData = try cerFiles.map { try Data(contentsOf: $0) }

        return try SignedDataVerifier(
            rootCertificates: certData,
            bundleId: config.bundleId,
            appAppleId: config.appAppleId,
            environment: config.environment,
            enableOnlineChecks: true
        )
    }
}
