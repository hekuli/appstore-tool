import AppStoreServerLibrary

enum APIClientFactory {
    static func makeClient(config: ResolvedConfig) throws -> AppStoreServerAPIClient {
        try AppStoreServerAPIClient(
            signingKey: config.signingKey,
            keyId: config.keyId,
            issuerId: config.issuerId,
            bundleId: config.bundleId,
            environment: config.environment
        )
    }
}
