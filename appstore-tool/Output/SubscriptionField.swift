import Foundation

/// All available fields from a subscription status response.
enum SubscriptionField: String, CaseIterable, Hashable, Sendable {
    // Subscription-level
    case subscriptionGroupId = "subscription_group_id"
    case status

    // Transaction fields
    case transactionId = "transaction_id"
    case originalTransactionId = "original_transaction_id"
    case productId = "product_id"
    case productType = "product_type"
    case purchaseDate = "purchase_date"
    case expiresDate = "expires_date"
    case ownershipType = "ownership_type"
    case offerType = "offer_type"
    case offerId = "offer_id"
    case storefront
    case environment

    // Renewal fields
    case autoRenewStatus = "auto_renew_status"
    case autoRenewProductId = "auto_renew_product_id"
    case expirationIntent = "expiration_intent"
    case billingRetry = "billing_retry"
    case gracePeriodExpires = "grace_period_expires"
    case renewalDate = "renewal_date"
    case recentSubStart = "recent_sub_start"

    var header: String { rawValue.uppercased() }

    static let defaults: [SubscriptionField] = [
        .subscriptionGroupId, .status, .productId,
        .originalTransactionId, .purchaseDate, .expiresDate,
        .autoRenewStatus, .environment,
    ]
}
