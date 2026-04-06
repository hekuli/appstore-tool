import AppStoreServerLibrary

// The library predates Swift 6 strict concurrency.
// These types are used sequentially in our code and are safe to send.
extension SignedDataVerifier: @retroactive @unchecked Sendable {}
extension AppStoreServerAPIClient: @retroactive @unchecked Sendable {}
extension TransactionHistoryRequest: @retroactive @unchecked Sendable {}
extension NotificationHistoryRequest: @retroactive @unchecked Sendable {}
