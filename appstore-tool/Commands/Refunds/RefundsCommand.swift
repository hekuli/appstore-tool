import ArgumentParser

struct RefundsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "refunds",
        abstract: "Query refund data.",
        subcommands: [
            RefundListCommand.self,
            RefundHistoryCommand.self,
        ],
        defaultSubcommand: RefundListCommand.self
    )
}
