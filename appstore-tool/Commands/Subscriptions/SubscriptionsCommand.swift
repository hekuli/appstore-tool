import ArgumentParser

struct SubscriptionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscriptions",
        abstract: "Query subscription data.",
        subcommands: [
            SubscriptionStatusCommand.self,
        ]
    )
}
