import Foundation

/// Reads saved config from ~/.appstore-tool/config
enum StoredConfig {
    struct File: Decodable {
        var auth: Auth?
        var fields: Fields?
    }

    struct Auth: Decodable {
        var keyId: String?
        var issuerId: String?
        var keyPath: String?
        var bundleId: String?
        var appAppleId: Int64?
        var environment: String?
        var certsDir: String?

        enum CodingKeys: String, CodingKey {
            case keyId = "key_id"
            case issuerId = "issuer_id"
            case keyPath = "key_path"
            case bundleId = "bundle_id"
            case appAppleId = "app_apple_id"
            case environment
            case certsDir = "certs_dir"
        }
    }

    struct Fields: Decodable {
        var notificationFields: [String]?
        var transactionFields: [String]?
        var subscriptionFields: [String]?

        enum CodingKeys: String, CodingKey {
            case notificationFields = "notification_fields"
            case transactionFields = "transaction_fields"
            case subscriptionFields = "subscription_fields"
        }
    }

    static let configPath = NSString(string: "~/.appstore-tool/config").expandingTildeInPath

    private static let cached: File? = {
        guard let data = FileManager.default.contents(atPath: configPath) else { return nil }
        return try? JSONDecoder().decode(File.self, from: data)
    }()

    static func load() -> File? { cached }
}
