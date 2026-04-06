import ArgumentParser

struct NotificationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notifications",
        abstract: "Query App Store Server Notifications.",
        subcommands: [
            NotificationHistoryCommand.self,
        ]
    )
}
