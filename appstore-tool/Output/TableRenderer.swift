import Foundation

/// Shared table rendering that auto-switches to vertical (record) layout
/// when the table is wider than the terminal.
enum TableRenderer {
    static func render<F: RawRepresentable<String>>(
        items: [(fields: [F], values: (F) -> String)],
        fields: [F]
    ) {
        guard !items.isEmpty else { return }

        let headerStrings = fields.map { $0.rawValue.uppercased() }
        var columns: [[String]] = headerStrings.map { [$0] }
        for item in items {
            for (i, field) in fields.enumerated() {
                columns[i].append(item.values(field))
            }
        }
        let widths = columns.map { col in col.map(\.count).max() ?? 0 }
        let totalWidth = widths.reduce(0, +) + (widths.count - 1) * 2

        let termWidth = Self.terminalWidth()

        if totalWidth > termWidth {
            // Vertical record layout
            renderVertical(items: items, fields: fields)
        } else {
            // Horizontal table
            renderHorizontal(items: items, fields: fields, headerStrings: headerStrings, widths: widths)
        }
    }

    private static func renderHorizontal<F: RawRepresentable<String>>(
        items: [(fields: [F], values: (F) -> String)],
        fields: [F],
        headerStrings: [String],
        widths: [Int]
    ) {
        let headerLine = zip(headerStrings, widths).map { $0.padding(toLength: $1, withPad: " ", startingAt: 0) }
        print(headerLine.joined(separator: "  "))
        print(widths.map { String(repeating: "\u{2500}", count: $0) }.joined(separator: "  "))
        for item in items {
            let row = fields.map { item.values($0) }
            let line = zip(row, widths).map { $0.padding(toLength: $1, withPad: " ", startingAt: 0) }
            print(line.joined(separator: "  "))
        }
    }

    private static func renderVertical<F: RawRepresentable<String>>(
        items: [(fields: [F], values: (F) -> String)],
        fields: [F]
    ) {
        let labels = fields.map { $0.rawValue.uppercased() + ":" }
        let maxLabel = labels.map(\.count).max() ?? 0

        for (i, item) in items.enumerated() {
            if i > 0 { print("") }
            if items.count > 1 {
                print("--- [\(i + 1)/\(items.count)] ---")
            }
            for (j, field) in fields.enumerated() {
                let val = item.values(field)
                if !val.isEmpty {
                    let padded = labels[j].padding(toLength: maxLabel, withPad: " ", startingAt: 0)
                    print("\(padded)  \(val)")
                }
            }
        }
    }

    static func terminalWidth() -> Int {
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0, w.ws_col > 0 {
            return Int(w.ws_col)
        }
        return 120 // fallback
    }
}
