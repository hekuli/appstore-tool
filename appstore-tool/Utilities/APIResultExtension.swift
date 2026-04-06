import AppStoreServerLibrary

extension APIResult {
    func unwrap(debug: Bool = false) throws -> T {
        switch self {
        case .success(let response):
            return response
        case .failure(let statusCode, let apiError, let causedBy):
            if debug {
                DebugLog.log("API FAILURE:")
                DebugLog.log("  Status code: \(statusCode.map(String.init) ?? "nil")")
                DebugLog.log("  API error:   \(apiError.map { "\($0) (raw: \($0.rawValue))" } ?? "nil (error code not in library's enum)")")
                DebugLog.log("  Caused by:   \(causedBy.map(String.init(describing:)) ?? "nil")")
                if apiError == nil, let code = statusCode {
                    DebugLog.log("  Hint: HTTP \(code) with no recognized error code.")
                    DebugLog.log("        The library (v0.1.0) may not include this error code.")
                    DebugLog.log("        Check https://developer.apple.com/documentation/appstoreserverapi for details.")
                }
            }
            throw AppStoreToolError.apiError(
                statusCode: statusCode,
                apiError: apiError,
                causedBy: causedBy
            )
        }
    }
}
