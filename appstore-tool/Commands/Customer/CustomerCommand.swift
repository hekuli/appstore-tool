import ArgumentParser

struct CustomerCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "customer",
        abstract: "Look up a customer's complete profile.",
        subcommands: [
            CustomerLookupCommand.self,
        ]
    )
}
