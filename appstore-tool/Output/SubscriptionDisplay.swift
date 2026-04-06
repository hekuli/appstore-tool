import AppStoreServerLibrary
import Foundation

struct SubscriptionDisplay: Encodable, Sendable {
    let values: [SubscriptionField: String]

    init(
        groupId: String,
        statusLabel: String,
        transaction: JWSTransactionDecodedPayload?,
        renewal: JWSRenewalInfoDecodedPayload?
    ) {
        var v: [SubscriptionField: String] = [:]
        v[.subscriptionGroupId] = groupId
        v[.status] = statusLabel

        if let t = transaction {
            v[.transactionId] = t.transactionId
            v[.originalTransactionId] = t.originalTransactionId
            v[.productId] = t.productId
            v[.productType] = t.type?.rawValue
            v[.purchaseDate] = t.purchaseDate.map(DateFormatting.format)
            v[.expiresDate] = t.expiresDate.map(DateFormatting.format)
            v[.ownershipType] = t.inAppOwnershipType?.rawValue
            v[.offerType] = t.offerType.map { o in
                switch o {
                case .introductoryOffer: "Introductory"
                case .promotionalOffer: "Promotional"
                case .subscriptionOfferCode: "Offer Code"
                }
            }
            v[.offerId] = t.offerIdentifier
            v[.storefront] = t.storefront
            v[.environment] = t.environment?.rawValue
        }

        if let r = renewal {
            v[.autoRenewStatus] = r.autoRenewStatus.map { s in
                switch s { case .off: "Off"; case .on: "On" }
            }
            v[.autoRenewProductId] = r.autoRenewProductId
            v[.expirationIntent] = r.expirationIntent.map { i in
                switch i {
                case .customerCancelled: "Customer cancelled"
                case .billingError: "Billing error"
                case .customerDidNotConsentToPriceIncrease: "Price increase declined"
                case .productNotAvailable: "Product unavailable"
                case .other: "Other"
                }
            }
            v[.billingRetry] = r.isInBillingRetryPeriod.map { $0 ? "true" : "false" }
            v[.gracePeriodExpires] = r.gracePeriodExpiresDate.map(DateFormatting.format)
            v[.renewalDate] = r.renewaldate.map(DateFormatting.format)
            v[.recentSubStart] = r.recentSubscriptionStartDate.map(DateFormatting.format)
        }

        self.values = v
    }

    func value(for field: SubscriptionField) -> String {
        values[field] ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        for field in SubscriptionField.allCases {
            if let val = values[field] {
                try container.encode(val, forKey: DynamicKey(field.rawValue))
            }
        }
    }

    static func renderTable(_ items: [SubscriptionDisplay], fields: [SubscriptionField]) {
        TableRenderer.render(
            items: items.map { item in (fields: fields, values: { item.value(for: $0) }) },
            fields: fields
        )
    }

    static func renderCSV(_ items: [SubscriptionDisplay], fields: [SubscriptionField]) {
        func esc(_ value: String) -> String {
            if value.contains(",") || value.contains("\"") || value.contains("\n") {
                return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
            }
            return value
        }
        print(fields.map { esc($0.header) }.joined(separator: ","))
        for item in items {
            print(fields.map { esc(item.value(for: $0)) }.joined(separator: ","))
        }
    }

    static func renderJSON(_ items: [SubscriptionDisplay]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        if let str = String(data: data, encoding: .utf8) { print(str) }
    }
}
