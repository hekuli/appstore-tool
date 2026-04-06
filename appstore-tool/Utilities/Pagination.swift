import AppStoreServerLibrary

enum Paginator {
    /// Generic pagination for APIs that use a revision token and hasMore flag.
    static func fetchAll<T>(
        limit: Int?,
        fetch: (_ token: String?) async throws -> (items: [T], nextToken: String?, hasMore: Bool)
    ) async throws -> [T] {
        var allItems: [T] = []
        var token: String? = nil
        var hasMore = true

        while hasMore {
            let page = try await fetch(token)
            allItems.append(contentsOf: page.items)
            token = page.nextToken
            hasMore = page.hasMore && token != nil

            if let cap = limit, allItems.count >= cap {
                allItems = Array(allItems.prefix(cap))
                break
            }
        }
        return allItems
    }
}
