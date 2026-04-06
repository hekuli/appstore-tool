import Foundation

/// Resolves field configuration.
/// Priority: --fields flag > ~/.appstore-tool/config > defaults
enum Config {
    static func resolveNotificationFields(flag: String?) -> [NotificationField] {
        let configValue = StoredConfig.load()?.fields?.notificationFields
        return resolve(flag: flag, configValue: configValue, defaults: NotificationField.defaults)
    }

    static func resolveTransactionFields(flag: String?) -> [TransactionField] {
        let configValue = StoredConfig.load()?.fields?.transactionFields
        return resolve(flag: flag, configValue: configValue, defaults: TransactionField.defaults)
    }

    static func resolveSubscriptionFields(flag: String?) -> [SubscriptionField] {
        let configValue = StoredConfig.load()?.fields?.subscriptionFields
        return resolve(flag: flag, configValue: configValue, defaults: SubscriptionField.defaults)
    }

    private static func resolve<F: RawRepresentable<String>>(
        flag: String?,
        configValue: [String]?,
        defaults: [F]
    ) -> [F] {
        let raw: [String]?
        if let flag {
            raw = flag.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            raw = configValue
        }
        guard let raw else { return defaults }
        let resolved = raw.compactMap { F(rawValue: $0) }
        return resolved.isEmpty ? defaults : resolved
    }
}
