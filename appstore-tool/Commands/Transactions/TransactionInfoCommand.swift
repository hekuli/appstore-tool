import ArgumentParser
import AppStoreServerLibrary

struct TransactionInfoCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Get full details for a single transaction."
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "The transaction ID to look up.")
    var transactionId: String?

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

        let response = try await client.getTransactionInfo(transactionId: transactionId).unwrap(debug: config.debug)

        guard let signedInfo = response.signedTransactionInfo else {
            if config.verbose { print("No results found.") }
            return
        }

        let payload = try await TransactionDecoder.decodeTransaction(signedInfo, verifier: verifier)
        let display = TransactionDisplay(from: payload)

        switch config.outputFormat {
        case .json:
            try TransactionDisplay.renderJSON([display])
        case .table:
            TransactionDisplay.renderDetail(display)
        case .csv:
            let selectedFields = Config.resolveTransactionFields(flag: fields)
            TransactionDisplay.renderCSV([display], fields: selectedFields)
        }
    }
}
