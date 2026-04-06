import AppStoreServerLibrary
import Foundation

/// Holds all decoded data from a single notification for rendering.
struct NotificationDisplay: Encodable, Sendable {
    let values: [NotificationField: String]
    let sortDate: Date

    init(
        from payload: ResponseBodyV2DecodedPayload,
        transaction: JWSTransactionDecodedPayload?,
        renewal: JWSRenewalInfoDecodedPayload?,
        sendAttempts: [SendAttemptItem]?
    ) {
        var v: [NotificationField: String] = [:]

        // Notification-level
        v[.type] = payload.notificationType?.rawValue
        v[.subtype] = payload.subtype?.rawValue
        v[.uuid] = payload.notificationUUID
        v[.date] = payload.signedDate.map(DateFormatting.format)
        v[.version] = payload.version

        // Data-level
        let data = payload.data
        v[.environment] = data?.environment?.rawValue
        v[.appAppleId] = data?.appAppleId.map(String.init)
        v[.bundleId] = data?.bundleId
        v[.bundleVersion] = data?.bundleVersion

        // Transaction
        if let t = transaction {
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
        }

        // Renewal
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

        // Send attempts
        v[.sendAttempts] = sendAttempts.map { String($0.count) }
        if let last = sendAttempts?.last {
            v[.lastSendResult] = last.sendAttemptResult?.rawValue
            v[.lastSendDate] = last.attemptDate.map(DateFormatting.format)
        }

        self.values = v
        self.sortDate = payload.signedDate ?? transaction?.purchaseDate ?? .distantPast
    }

    // MARK: - Encodable (JSON always outputs all non-nil fields; sortDate excluded)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        for field in NotificationField.allCases {
            if let val = values[field] {
                try container.encode(val, forKey: DynamicKey(field.rawValue))
            }
        }
    }

    // MARK: - Rendering

    func value(for field: NotificationField) -> String {
        values[field] ?? ""
    }

    static func renderTable(_ items: [NotificationDisplay], fields: [NotificationField]) {
        TableRenderer.render(
            items: items.map { item in (fields: fields, values: { item.value(for: $0) }) },
            fields: fields
        )
    }

    static func renderCSV(_ items: [NotificationDisplay], fields: [NotificationField]) {
        print(fields.map { escapeCSV($0.header) }.joined(separator: ","))
        for item in items {
            print(fields.map { escapeCSV(item.value(for: $0)) }.joined(separator: ","))
        }
    }

    static func renderJSON(_ items: [NotificationDisplay]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        if let str = String(data: data, encoding: .utf8) { print(str) }
    }

}
