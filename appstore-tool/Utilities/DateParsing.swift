import Foundation

enum DateParsing {
    static func parse(_ string: String) throws -> Date {
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime]
        if let date = iso8601.date(from: string) {
            return date
        }
        let dateOnly = ISO8601DateFormatter()
        dateOnly.formatOptions = [.withFullDate]
        if let date = dateOnly.date(from: string) {
            return date
        }
        throw InputError("Invalid date format '\(string)'. Use YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ (e.g., 2024-01-15 or 2024-01-15T10:30:00Z).")
    }
}

struct InputError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
