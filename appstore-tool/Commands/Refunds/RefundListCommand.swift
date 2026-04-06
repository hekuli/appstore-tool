import ArgumentParser
import AppStoreServerLibrary
import Foundation

struct RefundListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List refunds across all customers for a time period.",
        discussion: """
            Queries notification history for refund-related events. \
            By default shows issued refunds (REFUND). Use --type to include \
            other refund events: CONSUMPTION_REQUEST (incoming requests), \
            REFUND_DECLINED, REFUND_REVERSED.
            """
    )

    @OptionGroup var options: GlobalOptions

    @Option(help: "Start date (YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ, required).")
    var startDate: String?

    @Option(help: "End date (YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ). Default: now.")
    var endDate: String?

    @Option(help: "Notification type: REFUND (default), CONSUMPTION_REQUEST, REFUND_DECLINED, REFUND_REVERSED.")
    var type: String?

    @Option(help: "Maximum number of results to return.")
    var limit: Int?

    @Option(help: "Comma-separated list of fields for table/CSV output (see --list-fields).")
    var fields: String?

    @Flag(help: "Print all available field names and exit.")
    var listFields: Bool = false

    mutating func run() async throws {
        if listFields {
            FieldLister.printFields(NotificationField.self, defaults: NotificationField.defaults, configKey: "notification_fields")
            return
        }
        guard let startDate else {
            throw InputError("Missing required option '--start-date'.")
        }

        let config = try options.resolved()
        if config.verbose || config.debug { print(config) }

        let selectedFields = Config.resolveNotificationFields(flag: fields)
        let rawClient = try RawAPIClient(config: config)
        let verifier = try VerifierFactory.makeVerifier(config: config)

        let parsedStart = try DateParsing.parse(startDate)
        let parsedEnd = try endDate.map(DateParsing.parse) ?? Date()

        let notifType = type ?? "REFUND"

        var body = NotificationHistoryBody(
            startDate: Int64(parsedStart.timeIntervalSince1970 * 1000),
            endDate: Int64(parsedEnd.timeIntervalSince1970 * 1000)
        )
        body.notificationType = notifType

        var allItems: [NotificationHistoryResponseItem] = []
        var paginationToken: String? = nil
        var hasMore = true

        while hasMore {
            var path = "/inApps/v1/notifications/history"
            if let token = paginationToken {
                path += "?paginationToken=\(token)"
            }

            let response = try await rawClient.post(path: path, body: body, debug: config.debug)

            try response.throwOnError()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let page = try decoder.decode(NotificationHistoryResponse.self, from: response.body)

            allItems.append(contentsOf: page.notificationHistory ?? [])
            paginationToken = page.paginationToken
            hasMore = page.hasMore ?? false

            if let cap = limit, allItems.count >= cap {
                allItems = Array(allItems.prefix(cap))
                break
            }
        }

        guard !allItems.isEmpty else {
            if config.verbose { print("No results found.") }
            return
        }

        var displays: [NotificationDisplay] = []
        for item in allItems {
            guard let signedPayload = item.signedPayload else { continue }
            let payload = try await TransactionDecoder.decodeNotification(signedPayload, verifier: verifier)

            var transaction: JWSTransactionDecodedPayload?
            var renewal: JWSRenewalInfoDecodedPayload?

            if let signedTxn = payload.data?.signedTransactionInfo {
                transaction = try await TransactionDecoder.decodeTransaction(signedTxn, verifier: verifier)
            }
            if let signedRenewal = payload.data?.signedRenewalInfo {
                renewal = try await TransactionDecoder.decodeRenewalInfo(signedRenewal, verifier: verifier)
            }

            displays.append(NotificationDisplay(
                from: payload,
                transaction: transaction,
                renewal: renewal,
                sendAttempts: item.sendAttempts
            ))
        }

        displays.sort { $0.sortDate > $1.sortDate }

        switch config.outputFormat {
        case .json:
            try NotificationDisplay.renderJSON(displays)
        case .table:
            NotificationDisplay.renderTable(displays, fields: selectedFields)
        case .csv:
            NotificationDisplay.renderCSV(displays, fields: selectedFields)
        }
    }
}
