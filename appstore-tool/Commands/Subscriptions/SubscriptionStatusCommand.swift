import ArgumentParser
import AppStoreServerLibrary

struct SubscriptionStatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Get all subscription statuses for a customer."
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "A transaction ID belonging to the customer.")
    var transactionId: String?

    @Option(help: "Filter by status: 1=active, 2=expired, 3=billingRetry, 4=billingGracePeriod, 5=revoked. Repeatable.")
    var status: [Int32] = []

    @Option(help: "Comma-separated list of fields for table/CSV output (see --list-fields).")
    var fields: String?

    @Flag(help: "Print all available field names and exit.")
    var listFields: Bool = false

    mutating func run() async throws {
        if listFields {
            FieldLister.printFields(SubscriptionField.self, defaults: SubscriptionField.defaults, configKey: "subscription_fields")
            return
        }
        guard let transactionId else {
            throw InputError("Missing required argument '<transaction-id>'.")
        }

        let config = try options.resolved()
        if config.verbose || config.debug { print(config) }

        let client = try APIClientFactory.makeClient(config: config)
        let verifier = try VerifierFactory.makeVerifier(config: config)

        let statusFilter: [Status]? = status.isEmpty ? nil : status.compactMap { Status(rawValue: $0) }
        let response = try await client.getAllSubscriptionStatuses(
            transactionId: transactionId,
            status: statusFilter
        ).unwrap(debug: config.debug)

        guard let groups = response.data, !groups.isEmpty else {
            if config.verbose { print("No results found.") }
            return
        }

        var allDisplays: [SubscriptionDisplay] = []

        for group in groups {
            let groupId = group.subscriptionGroupIdentifier ?? "—"
            for item in group.lastTransactions ?? [] {
                let statusLabel = item.status?.label ?? "—"

                var transaction: JWSTransactionDecodedPayload?
                var renewal: JWSRenewalInfoDecodedPayload?

                if let signedTxn = item.signedTransactionInfo {
                    transaction = try await TransactionDecoder.decodeTransaction(signedTxn, verifier: verifier)
                }
                if let signedRenewal = item.signedRenewalInfo {
                    renewal = try await TransactionDecoder.decodeRenewalInfo(signedRenewal, verifier: verifier)
                }

                allDisplays.append(SubscriptionDisplay(
                    groupId: groupId,
                    statusLabel: statusLabel,
                    transaction: transaction,
                    renewal: renewal
                ))
            }
        }

        let selectedFields = Config.resolveSubscriptionFields(flag: fields)

        switch config.outputFormat {
        case .json:
            try SubscriptionDisplay.renderJSON(allDisplays)
        case .table:
            SubscriptionDisplay.renderTable(allDisplays, fields: selectedFields)
        case .csv:
            SubscriptionDisplay.renderCSV(allDisplays, fields: selectedFields)
        }
    }

}
