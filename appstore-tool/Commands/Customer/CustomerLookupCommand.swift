import ArgumentParser
import AppStoreServerLibrary
import Foundation

struct CustomerLookupCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lookup",
        abstract: "Resolve a customer from a transaction and fetch all their data.",
        discussion: """
            Given any transaction ID, resolves the originalTransactionId and \
            fetches the customer's full transaction history, subscription statuses, \
            and refund history.
            """
    )

    @OptionGroup var options: GlobalOptions

    @Argument(help: "Any transaction ID belonging to the customer.")
    var transactionId: String

    @Flag(help: "Skip fetching transaction history.")
    var skipHistory: Bool = false

    @Flag(help: "Skip fetching subscription statuses.")
    var skipSubscriptions: Bool = false

    @Flag(help: "Skip fetching refund history.")
    var skipRefunds: Bool = false

    mutating func run() async throws {
        let config = try options.resolved()
        if config.verbose || config.debug { print(config) }

        let client = try APIClientFactory.makeClient(config: config)
        let verifier = try VerifierFactory.makeVerifier(config: config)
        let txnFields = Config.resolveTransactionFields(flag: nil)
        let subFields = Config.resolveSubscriptionFields(flag: nil)

        // Step 1: Resolve originalTransactionId
        print("Resolving customer from transaction \(transactionId)...")
        let infoResponse = try await client.getTransactionInfo(transactionId: transactionId).unwrap(debug: config.debug)
        guard let signedInfo = infoResponse.signedTransactionInfo else {
            if config.verbose { print("No results found.") }
            return
        }
        let seedTxn = try await TransactionDecoder.decodeTransaction(signedInfo, verifier: verifier)
        let originalId = seedTxn.originalTransactionId ?? transactionId

        print("Customer original transaction ID: \(originalId)")
        print("")

        // Transaction history
        if !skipHistory {
            print("── Transaction History ──")
            var request = makeTransactionHistoryRequest()
            request.sort = .descending
            do {
                let signed = try await Paginator.fetchAll(limit: nil) { token in
                    let result = try await client.getTransactionHistory(
                        transactionId: originalId,
                        revision: token,
                        transactionHistoryRequest: request
                    ).unwrap(debug: config.debug)
                    return (
                        items: result.signedTransactions ?? [],
                        nextToken: result.revision,
                        hasMore: result.hasMore ?? false
                    )
                }
                let transactions = try await TransactionDecoder.decodeTransactions(signed, verifier: verifier)
                var displays = transactions.map(TransactionDisplay.init)
                displays.sort { $0.sortDate > $1.sortDate }
                switch config.outputFormat {
                case .json: try TransactionDisplay.renderJSON(displays)
                case .table: TransactionDisplay.renderTable(displays, fields: txnFields)
                case .csv: TransactionDisplay.renderCSV(displays, fields: txnFields)
                }
            } catch {
                print("  Failed to fetch history: \(error.localizedDescription)")
            }
            print("")
        }

        // Subscription statuses
        if !skipSubscriptions {
            print("── Subscription Statuses ──")
            do {
                let response = try await client.getAllSubscriptionStatuses(transactionId: originalId).unwrap(debug: config.debug)
                if let groups = response.data, !groups.isEmpty {
                    var displays: [SubscriptionDisplay] = []
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
                            displays.append(SubscriptionDisplay(
                                groupId: groupId, statusLabel: statusLabel,
                                transaction: transaction, renewal: renewal
                            ))
                        }
                    }
                    switch config.outputFormat {
                    case .json: try SubscriptionDisplay.renderJSON(displays)
                    case .table: SubscriptionDisplay.renderTable(displays, fields: subFields)
                    case .csv: SubscriptionDisplay.renderCSV(displays, fields: subFields)
                    }
                } else {
                    print("  No subscriptions found.")
                }
            } catch {
                print("  Failed to fetch subscriptions: \(error.localizedDescription)")
            }
            print("")
        }

        // Refund history
        if !skipRefunds {
            print("── Refund History ──")
            do {
                let signed = try await Paginator.fetchAll(limit: nil) { token in
                    let result = try await client.getRefundHistory(
                        transactionId: originalId,
                        revision: token
                    ).unwrap(debug: config.debug)
                    return (
                        items: result.signedTransactions ?? [],
                        nextToken: result.revision,
                        hasMore: result.hasMore ?? false
                    )
                }
                if signed.isEmpty {
                    print("  No refunds found.")
                } else {
                    let transactions = try await TransactionDecoder.decodeTransactions(signed, verifier: verifier)
                    var displays = transactions.map(TransactionDisplay.init)
                    displays.sort { $0.sortDate > $1.sortDate }
                    switch config.outputFormat {
                    case .json: try TransactionDisplay.renderJSON(displays)
                    case .table: TransactionDisplay.renderTable(displays, fields: txnFields)
                    case .csv: TransactionDisplay.renderCSV(displays, fields: txnFields)
                    }
                }
            } catch {
                print("  Failed to fetch refunds: \(error.localizedDescription)")
            }
        }
    }

}
