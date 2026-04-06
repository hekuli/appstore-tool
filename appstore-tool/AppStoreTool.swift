import ArgumentParser

@main
struct AppStoreTool: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "appstore-tool",
        abstract: "Query the Apple App Store Server API.",
        discussion: """
            Read-only CLI for inspecting App Store transactions, subscriptions, \
            refunds, and customer data.

            Run 'appstore-tool config' for interactive setup, or provide \
            credentials via flags, environment variables (AST_KEY_PATH, \
            AST_KEY_ID, AST_ISSUER_ID, AST_BUNDLE_ID, AST_APP_APPLE_ID, \
            AST_ENVIRONMENT), or stored config (~/.appstore-tool/config).
            """,
        version: "0.1.0",
        subcommands: [
            ConfigCommand.self,
            TransactionsCommand.self,
            SubscriptionsCommand.self,
            RefundsCommand.self,
            CustomerCommand.self,
            NotificationsCommand.self,
        ]
    )
}
