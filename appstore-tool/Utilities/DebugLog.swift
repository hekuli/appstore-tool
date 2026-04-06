import Foundation

enum DebugLog {
    static func log(_ message: String) {
        FileHandle.standardError.write(Data("[debug] \(message)\n".utf8))
    }
}
