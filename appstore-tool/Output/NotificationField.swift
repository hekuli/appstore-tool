import Foundation

/// All available fields from a decoded App Store Server Notification.
enum NotificationField: String, CaseIterable, Hashable, Sendable {
    // Notification-level
    case type
    case subtype
    case uuid
    case date
    case version

    // Data-level
    case environment
    case appAppleId = "app_apple_id"
    case bundleId = "bundle_id"
    case bundleVersion = "bundle_version"

    // Transaction fields (from signedTransactionInfo)
    case transactionId = "transaction_id"
    case originalTransactionId = "original_transaction_id"
    case productId = "product_id"
    case productType = "product_type"
    case purchaseDate = "purchase_date"
    case originalPurchaseDate = "original_purchase_date"
    case expiresDate = "expires_date"
    case quantity
    case appAccountToken = "app_account_token"
    case ownershipType = "ownership_type"
    case revocationDate = "revocation_date"
    case revocationReason = "revocation_reason"
    case isUpgraded = "is_upgraded"
    case offerType = "offer_type"
    case offerId = "offer_id"
    case storefront
    case storefrontId = "storefront_id"
    case transactionReason = "transaction_reason"
    case subscriptionGroupId = "subscription_group_id"
    case webOrderLineItemId = "web_order_line_item_id"

    // Renewal fields (from signedRenewalInfo)
    case autoRenewStatus = "auto_renew_status"
    case autoRenewProductId = "auto_renew_product_id"
    case expirationIntent = "expiration_intent"
    case billingRetry = "billing_retry"
    case gracePeriodExpires = "grace_period_expires"
    case renewalDate = "renewal_date"
    case recentSubStart = "recent_sub_start"

    // Send attempt fields
    case sendAttempts = "send_attempts"
    case lastSendResult = "last_send_result"
    case lastSendDate = "last_send_date"

    var header: String { rawValue.uppercased() }

    static let defaults: [NotificationField] = [
        .type, .subtype, .date, .productId,
        .transactionId, .originalTransactionId,
        .purchaseDate, .expiresDate, .environment,
    ]
}
