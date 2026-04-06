import ArgumentParser
import AppStoreServerLibrary

struct TransactionOrderCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "order",
        abstract: "Look up transactions by order ID."
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "The order ID to look up.")
    var orderId: String?

    @Option(help: "Comma-separated list of fields for table/CSV output (see --list-fields).")
    var fields: String?

    @Flag(help: "Print all available field names and exit.")
    var listFields: Bool = false

    mutating func run() async throws {
        if listFields {
            FieldLister.printFields(TransactionField.self, defaults: TransactionField.defaults, configKey: "transaction_fields")
            return
        }
        guard let orderId else {
            print("""
                Look up transactions by a customer's order ID.

                The order ID (e.g. MZxxxxxxxxxx) appears on the customer's Apple \
                receipt/invoice email. It is not included in App Store Server \
                Notifications or transaction payloads — it is only visible to \
                the customer. Use this command when a customer provides their \
                order ID for support purposes.

                Usage: appstore-tool transactions order <order-id>
                """)
            return
        }

        let config = try options.resolved()
        if config.verbose || config.debug { print(config) }

        let client = try APIClientFactory.makeClient(config: config)
        let verifier = try VerifierFactory.makeVerifier(config: config)

        let response = try await client.lookUpOrderId(orderId: orderId).unwrap(debug: config.debug)

        if let status = response.status {
            switch status {
            case .invalid:
                print("Order status: Invalid")
                return
            case .valid:
                break
            }
        }

        let signed = response.signedTransactions ?? []
        guard !signed.isEmpty else {
            if config.verbose { print("No results found.") }
            return
        }

        let transactions = try await TransactionDecoder.decodeTransactions(signed, verifier: verifier)
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
