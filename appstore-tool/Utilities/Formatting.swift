import AppStoreServerLibrary
import Foundation

func escapeCSV(_ value: String) -> String {
    if value.contains(",") || value.contains("\"") || value.contains("\n") {
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    return value
}

enum DateFormatting {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        f.timeZone = TimeZone.current
        return f
    }()

    static func format(_ date: Date) -> String {
        formatter.string(from: date)
    }
}

extension Status {
    var label: String {
        switch self {
        case .active: "Active"
        case .expired: "Expired"
        case .billingRetry: "Billing Retry"
        case .billingGracePeriod: "Billing Grace Period"
        case .revoked: "Revoked"
        }
    }
}
