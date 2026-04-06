import ArgumentParser
import AppStoreServerLibrary
import Foundation

struct NotificationHistoryCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "history",
        abstract: "List App Store Server Notification history.",
        discussion: """
            Retrieves up to 6 months of notification history.

            Use --fields to choose which columns appear in table/CSV output \
            (JSON always includes all fields). Run --list-fields to see all \
            available field names. Defaults can be set in ~/.appstore-tool/config.
            """
    )

    @OptionGroup var options: GlobalOptions

    @Option(help: "Start date (YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ, required).")
    var startDate: String?

    @Option(help: "End date (YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ). Default: now.")
    var endDate: String?

    @Option(help: "Filter by notification type (e.g., SUBSCRIBED, DID_RENEW, REFUND).")
    var notificationType: String?

    @Option(name: .long, help: "Filter by transaction ID.")
    var transactionId: String?

    @Flag(help: "Show only failed notification deliveries.")
    var onlyFailures: Bool = false

    @Option(help: "Maximum number of notifications to return.")
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

        let config = try options.resolved()
        if config.verbose || config.debug { print(config) }

        guard let startDate else {
            throw InputError("--start-date is required (unless using --list-fields).")
        }

        let selectedFields = Config.resolveNotificationFields(flag: fields)
        let rawClient = try RawAPIClient(config: config)
        let verifier = try VerifierFactory.makeVerifier(config: config)

        let parsedStart = try DateParsing.parse(startDate)
        let parsedEnd = try endDate.map(DateParsing.parse) ?? Date()

        var body = NotificationHistoryBody(
            startDate: Int64(parsedStart.timeIntervalSince1970 * 1000),
            endDate: Int64(parsedEnd.timeIntervalSince1970 * 1000)
        )
        if let nt = notificationType { body.notificationType = nt }
        body.transactionId = transactionId
        if onlyFailures { body.onlyFailures = true }

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

        // Decode all notifications, including inner signed payloads
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

        // Render
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
