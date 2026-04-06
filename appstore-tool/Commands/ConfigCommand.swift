import ArgumentParser
import Foundation

struct ConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Interactive setup for appstore-tool credentials and certificates."
    )

    mutating func run() async throws {
        print("appstore-tool configuration")
        print("===========================\n")

        // Key ID
        print("""
        Step 1: API Key ID
          1. Go to App Store Connect: https://appstoreconnect.apple.com
          2. Navigate to Users and Access > Integrations > In-App Purchase
          3. Create or select an API key
          4. The Key ID is the alphanumeric identifier shown next to the key name
        """)
        let keyId = prompt("Key ID")

        // Issuer ID
        print("""

        Step 2: Issuer ID
          On the same Integrations page in App Store Connect, the Issuer ID
          is shown at the top of the page. It looks like a UUID:
          xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        """)
        let issuerId = prompt("Issuer ID")

        // Key file path
        print("""

        Step 3: Private Key File (.p8)
          When you created the API key, Apple let you download a .p8 file once.
          Enter the full path to that file on your machine.
          Example: ~/keys/AuthKey_YOURKEYID.p8
        """)
        let keyPath = prompt("Key file path")
        let expandedKeyPath = NSString(string: keyPath).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedKeyPath) else {
            throw AppStoreToolError.keyFileNotFound(expandedKeyPath)
        }

        // Bundle ID
        print("""

        Step 4: Bundle ID
          Your app's bundle identifier, as shown in Xcode or App Store Connect.
          Example: com.company.appname
        """)
        let bundleId = prompt("Bundle ID")

        // App Apple ID
        print("""

        Step 5: App Apple ID
          A numeric ID for your app. Find it in App Store Connect:
          My Apps > select your app > App Information > Apple ID (in the sidebar)
          Example: 1234567890
        """)
        let appAppleIdStr = prompt("App Apple ID")
        guard let appAppleId = Int64(appAppleIdStr) else {
            print("Error: App Apple ID must be a number.")
            return
        }

        // Environment
        print("""

        Step 6: Default Environment
          Choose which App Store environment to query by default.
          Use 'production' for live data, 'sandbox' for testing.
        """)
        let envInput = prompt("Environment (production/sandbox)", defaultValue: "production")
        guard envInput == "production" || envInput == "sandbox" else {
            print("Error: Must be 'production' or 'sandbox'.")
            return
        }

        // Confirmation
        let configDir = NSString(string: "~/.appstore-tool").expandingTildeInPath
        let configFile = configDir + "/config"
        let certsDir = configDir + "/certs"

        let notifDefaults = NotificationField.defaults.map { "\"\($0.rawValue)\"" }.joined(separator: ", ")
        let txnDefaults = TransactionField.defaults.map { "\"\($0.rawValue)\"" }.joined(separator: ", ")
        let subDefaults = SubscriptionField.defaults.map { "\"\($0.rawValue)\"" }.joined(separator: ", ")

        print("""

        ===========================
        Configuration Summary
        ===========================
          Key ID:        \(keyId)
          Issuer ID:     \(issuerId)
          Key Path:      \(keyPath)
          Bundle ID:     \(bundleId)
          App Apple ID:  \(appAppleId)
          Environment:   \(envInput)
          Fields:        defaults for all types (editable in config)

        This will:
          - Create directory: ~/.appstore-tool/
          - Write config to:  ~/.appstore-tool/config
          - Download Apple root certificates to: ~/.appstore-tool/certs/
        """)

        if FileManager.default.fileExists(atPath: configFile) {
            print("  WARNING: This will overwrite your existing config at \(configFile)\n")
        }

        let confirm = prompt("Proceed? (y/n)", defaultValue: "y")
        guard confirm.lowercased() == "y" || confirm.lowercased() == "yes" else {
            print("Aborted.")
            return
        }

        // Write config
        try FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: certsDir, withIntermediateDirectories: true)

        let configContent = """
        {
          "auth": {
            "key_id": "\(keyId)",
            "issuer_id": "\(issuerId)",
            "key_path": "\(keyPath)",
            "bundle_id": "\(bundleId)",
            "app_apple_id": \(appAppleId),
            "environment": "\(envInput)",
            "certs_dir": "~/.appstore-tool/certs"
          },
          "fields": {
            "notification_fields": [\(notifDefaults)],
            "transaction_fields": [\(txnDefaults)],
            "subscription_fields": [\(subDefaults)]
          }
        }
        """
        try configContent.write(toFile: configFile, atomically: true, encoding: .utf8)
        print("Wrote config to \(configFile)")

        // Download Apple root certificates
        let certURLs: [(String, String)] = [
            ("https://www.apple.com/appleca/AppleIncRootCertificate.cer", "AppleIncRootCertificate.cer"),
            ("https://www.apple.com/certificateauthority/AppleRootCA-G2.cer", "AppleRootCA-G2.cer"),
            ("https://www.apple.com/certificateauthority/AppleRootCA-G3.cer", "AppleRootCA-G3.cer"),
        ]

        print("Downloading Apple root certificates...")
        for (urlString, filename) in certURLs {
            let destPath = certsDir + "/" + filename
            if FileManager.default.fileExists(atPath: destPath) {
                print("  \(filename) (already exists, skipping)")
                continue
            }
            guard let url = URL(string: urlString) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                try data.write(to: URL(fileURLWithPath: destPath))
                print("  \(filename) (\(data.count) bytes)")
            } catch {
                print("  \(filename) FAILED: \(error.localizedDescription)")
            }
        }

        // Shell completions
        installCompletionsIfWanted()

        print("\nConfiguration complete. You can now run commands like:")
        print("  appstore-tool notifications history --start-date 2024-01-01")
        print("\nTo customize fields, edit: ~/.appstore-tool/config")
        print("To reconfigure, run: appstore-tool config")
    }

    private func installCompletionsIfWanted() {
        let shellPath = ProcessInfo.processInfo.environment["SHELL"] ?? ""
        let shellName: String
        if shellPath.hasSuffix("zsh") { shellName = "zsh" }
        else if shellPath.hasSuffix("bash") { shellName = "bash" }
        else if shellPath.hasSuffix("fish") { shellName = "fish" }
        else {
            print("\nCould not detect shell for completions (SHELL=\(shellPath)).")
            return
        }

        guard let shell = CompletionShell(rawValue: shellName) else { return }

        let home = NSString(string: "~").expandingTildeInPath
        let (dir, file): (String, String)
        switch shellName {
        case "zsh":
            dir = home + "/.zsh/completions"
            file = dir + "/_appstore-tool"
        case "bash":
            dir = home + "/.local/share/bash-completion/completions"
            file = dir + "/appstore-tool"
        case "fish":
            dir = home + "/.config/fish/completions"
            file = dir + "/appstore-tool.fish"
        default:
            return
        }

        print("\nShell completions for \(shellName)")
        print("  This will write: \(file)")
        let answer = prompt("Install shell completions? (y/n)", defaultValue: "y")
        guard answer.lowercased() == "y" || answer.lowercased() == "yes" else {
            print("  Skipped.")
            return
        }

        do {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            let script = AppStoreTool.completionScript(for: shell)
            try script.write(toFile: file, atomically: true, encoding: .utf8)
            print("  Installed to \(file)")

            if shellName == "zsh" {
                let zshrc = home + "/.zshrc"
                let zshrcContent = (try? String(contentsOfFile: zshrc, encoding: .utf8)) ?? ""
                if !zshrcContent.contains(".zsh/completions") {
                    print("\n  Add this to your ~/.zshrc to enable completions:")
                    print("    fpath=(~/.zsh/completions $fpath)")
                    print("    autoload -Uz compinit && compinit")
                }
            }
            print("  Restart your shell or run: exec $SHELL")
        } catch {
            print("  Failed to install: \(error.localizedDescription)")
        }
    }

    private func prompt(_ label: String, defaultValue: String? = nil) -> String {
        if let d = defaultValue {
            print("\(label) [\(d)]: ", terminator: "")
        } else {
            print("\(label): ", terminator: "")
        }
        fflush(stdout)
        guard let line = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty else {
            return defaultValue ?? ""
        }
        return line
    }
}
