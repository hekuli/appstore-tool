import ArgumentParser

struct TransactionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "transactions",
        abstract: "Query transaction data.",
        subcommands: [
            TransactionInfoCommand.self,
            TransactionHistoryCommand.self,
            TransactionOrderCommand.self,
        ]
    )
}
