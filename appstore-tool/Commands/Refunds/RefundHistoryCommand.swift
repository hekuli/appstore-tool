import ArgumentParser
import AppStoreServerLibrary

struct RefundHistoryCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "history",
        abstract: "List refund history for a customer."
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "A transaction ID belonging to the customer.")
    var transactionId: String?

    @Option(help: "Maximum number of refunds to return.")
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

        let signedTransactions = try await Paginator.fetchAll(limit: limit) { token in
            let result = try await client.getRefundHistory(
                transactionId: transactionId,
                revision: token
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
