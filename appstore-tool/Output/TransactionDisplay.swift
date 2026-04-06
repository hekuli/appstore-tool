import AppStoreServerLibrary
import Foundation

struct TransactionDisplay: Encodable, Sendable {
    let values: [TransactionField: String]
    let sortDate: Date

    init(from t: JWSTransactionDecodedPayload) {
        var v: [TransactionField: String] = [:]
        v[.transactionId] = t.transactionId
        v[.originalTransactionId] = t.originalTransactionId
        v[.productId] = t.productId
        v[.productType] = t.type?.rawValue
        v[.purchaseDate] = t.purchaseDate.map(DateFormatting.format)
        v[.originalPurchaseDate] = t.originalPurchaseDate.map(DateFormatting.format)
        v[.expiresDate] = t.expiresDate.map(DateFormatting.format)
        v[.quantity] = t.quantity.map(String.init)
        v[.appAccountToken] = t.appAccountToken?.uuidString
        v[.ownershipType] = t.inAppOwnershipType?.rawValue
        v[.revocationDate] = t.revocationDate.map(DateFormatting.format)
        v[.revocationReason] = t.revocationReason.map { r in
            switch r {
            case .refundedDueToIssue: "Issue with app"
            case .refundedForOtherReason: "Other reason"
            }
        }
        v[.isUpgraded] = t.isUpgraded.map { $0 ? "true" : "false" }
        v[.offerType] = t.offerType.map { o in
            switch o {
            case .introductoryOffer: "Introductory"
            case .promotionalOffer: "Promotional"
            case .subscriptionOfferCode: "Offer Code"
            }
        }
        v[.offerId] = t.offerIdentifier
        v[.storefront] = t.storefront
        v[.storefrontId] = t.storefrontId
        v[.transactionReason] = t.transactionReason?.rawValue
        v[.subscriptionGroupId] = t.subscriptionGroupIdentifier
        v[.webOrderLineItemId] = t.webOrderLineItemId
        v[.environment] = t.environment?.rawValue
        self.values = v
        self.sortDate = t.purchaseDate ?? .distantPast
    }

    func value(for field: TransactionField) -> String {
        values[field] ?? ""
    }

    // MARK: - Encodable (JSON always outputs all non-nil fields)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        for field in TransactionField.allCases {
            if let val = values[field] {
                try container.encode(val, forKey: DynamicKey(field.rawValue))
            }
        }
    }

    // MARK: - Rendering

    static func renderTable(_ items: [TransactionDisplay], fields: [TransactionField]) {
        TableRenderer.render(
            items: items.map { item in (fields: fields, values: { item.value(for: $0) }) },
            fields: fields
        )
    }

    static func renderDetail(_ item: TransactionDisplay) {
        // Single item always uses vertical layout
        TableRenderer.render(
            items: [(fields: TransactionField.allCases, values: { item.value(for: $0) })],
            fields: TransactionField.allCases.filter { item.values[$0] != nil }
        )
    }

    static func renderCSV(_ items: [TransactionDisplay], fields: [TransactionField]) {
        print(fields.map { escapeCSV($0.header) }.joined(separator: ","))
        for item in items {
            print(fields.map { escapeCSV(item.value(for: $0)) }.joined(separator: ","))
        }
    }

    static func renderJSON(_ items: [TransactionDisplay]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        if let str = String(data: data, encoding: .utf8) { print(str) }
    }

}

struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { self.stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}
