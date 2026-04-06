import Foundation

/// All available fields from a decoded transaction.
enum TransactionField: String, CaseIterable, Hashable, Sendable {
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
    case environment

    var header: String { rawValue.uppercased() }

    static let defaults: [TransactionField] = [
        .transactionId, .originalTransactionId, .productId, .productType,
        .purchaseDate, .expiresDate, .environment, .storefront,
    ]
}
