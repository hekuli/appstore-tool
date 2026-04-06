import Foundation

enum FieldLister {
    static func printFields<F: RawRepresentable<String> & CaseIterable>(
        _ type: F.Type,
        defaults: [F],
        configKey: String
    ) where F: Equatable {
        print("Available fields (use with --fields or \"\(configKey)\" in ~/.appstore-tool/config):\n")
        for field in F.allCases {
            let marker = defaults.contains(field) ? " (default)" : ""
            print("  \(field.rawValue)\(marker)")
        }
    }
}
