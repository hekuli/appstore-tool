import AppStoreServerLibrary
import Foundation

/// Clean Encodable request body for notification history.
/// Only encodes fields that are set — no null values in JSON.
struct NotificationHistoryBody: Encodable, Sendable {
    var startDate: Int64
    var endDate: Int64
    var notificationType: String?
    var notificationSubtype: String?
    var transactionId: String?
    var onlyFailures: Bool?

    enum CodingKeys: String, CodingKey {
        case startDate, endDate, notificationType, notificationSubtype, transactionId, onlyFailures
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encodeIfPresent(notificationType, forKey: .notificationType)
        try container.encodeIfPresent(notificationSubtype, forKey: .notificationSubtype)
        try container.encodeIfPresent(transactionId, forKey: .transactionId)
        try container.encodeIfPresent(onlyFailures, forKey: .onlyFailures)
    }
}
