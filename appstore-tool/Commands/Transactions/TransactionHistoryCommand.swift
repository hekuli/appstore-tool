import ArgumentParser
import AppStoreServerLibrary
import Foundation

struct TransactionHistoryCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "history",
        abstract: "List paginated transaction history for a customer."
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "A transaction ID belonging to the customer.")
    var transactionId: String?

    @Option(help: "Start date (YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ).")
    var startDate: String?

    @Option(help: "End date (YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ). Default: now.")
    var endDate: String?

    @Option(help: "Filter by product ID.")
    var productId: [String] = []

    @Option(help: "Filter by product type: AUTO_RENEWABLE, NON_RENEWABLE, CONSUMABLE, NON_CONSUMABLE.")
    var productType: String?

    @Option(help: "Sort order: ASCENDING or DESCENDING (default: DESCENDING).")
    var sort: String?

    @Option(help: "Filter revoked transactions: true or false.")
    var revoked: String?

    @Option(help: "Maximum number of transactions to return.")
    var limit: Int?

    @Option(help: "Comma-separated list of fields for table/CSV output (see --list-fields).")
    var fields: String?

    @Flag(help: "Print all available field names and exit.")
    var listFields: Bool = false

    mutating func run() async throws {
        if listFields {
            FieldLister.printFields(TransactionField.self, defaults: TransactionField.defaults, configKey: "transaction_fields")
            return
        }
        guard let transactionId else {
            throw InputError("Missing required argument '<transaction-id>'.")
        }

        let config = try options.resolved()
        if config.verbose || config.debug { print(config) }

        let client = try APIClientFactory.makeClient(config: config)
        let verifier = try VerifierFactory.makeVerifier(config: config)

        var request = makeTransactionHistoryRequest()
        if let s = startDate { request.startDate = try DateParsing.parse(s) }
        request.endDate = try endDate.map(DateParsing.parse) ?? Date()
        if !productId.isEmpty { request.productIds = productId }
        if let pt = productType {
            request.productTypes = [TransactionHistoryRequest.ProductType(rawValue: pt)].compactMap { $0 }
        }
        if let s = sort {
            request.sort = TransactionHistoryRequest.Order(rawValue: s)
        } else {
            request.sort = .descending
        }
        if let r = revoked { request.revoked = (r == "true") }

        let signedTransactions = try await Paginator.fetchAll(limit: limit) { token in
            let result = try await client.getTransactionHistory(
                transactionId: transactionId,
                revision: token,
                transactionHistoryRequest: request
            ).unwrap(debug: config.debug)
            return (
                items: result.signedTransactions ?? [],
                nextToken: result.revision,
                hasMore: result.hasMore ?? false
            )
        }

        guard !signedTransactions.isEmpty else {
            if config.verbose { print("No results found.") }
            return
        }

        let transactions = try await TransactionDecoder.decodeTransactions(signedTransactions, verifier: verifier)
        var displays = transactions.map(TransactionDisplay.init)
        displays.sort { $0.sortDate > $1.sortDate }
        let selectedFields = Config.resolveTransactionFields(flag: fields)

        switch config.outputFormat {
        case .json:
            try TransactionDisplay.renderJSON(displays)
        case .table:
            TransactionDisplay.renderTable(displays, fields: selectedFields)
        case .csv:
            TransactionDisplay.renderCSV(displays, fields: selectedFields)
        }
    }
}

// MARK: - TransactionHistoryRequest factory (no public init in library v0.1.0)

func makeTransactionHistoryRequest() -> TransactionHistoryRequest {
    // TransactionHistoryRequest has no public init. All properties are public var Optional.
    // Create via zeroed memory then set all properties to nil via public setters.
    let ptr = UnsafeMutablePointer<TransactionHistoryRequest>.allocate(capacity: 1)
    defer { ptr.deallocate() }
    let raw = UnsafeMutableRawPointer(ptr)
    raw.initializeMemory(as: UInt8.self, repeating: 0, count: MemoryLayout<TransactionHistoryRequest>.size)
    var result = ptr.move()
    result.startDate = nil
    result.endDate = nil
    result.productIds = nil
    result.productTypes = nil
    result.sort = nil
    result.subscriptionGroupIdentifiers = nil
    result.inAppOwnershipType = nil
    result.revoked = nil
    return result
}
