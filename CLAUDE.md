# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Read-only macOS CLI tool for querying the Apple App Store Server API (transactions, subscriptions, refunds, customer data). Uses [app-store-server-library-swift](https://github.com/apple/app-store-server-library-swift) v0.1.0.

## Build

Xcode-managed project (no Package.swift). Dependencies resolved via Xcode's SPM integration.

```bash
./build              # Release build -> ./bin/appstore-tool
./build Debug        # Debug build
```

## Key Details

- Swift 6 with strict concurrency (`SWIFT_APPROACHABLE_CONCURRENCY`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`)
- macOS 26.4 deployment target, hardened runtime
- Entry point: `appstore-tool/AppStoreTool.swift` (`@main` attribute)
- Config stored at `~/.appstore-tool/config` (auth + field settings); run `appstore-tool config` to set up
- Apple root certs downloaded to `~/.appstore-tool/certs/` during config setup
- Auth resolution: CLI flags > env vars (`AST_*`) > stored config

## Architecture

- **Commands/**: ArgumentParser subcommands organized by domain (Transactions, Subscriptions, Refunds, Customer, Notifications, Config)
- **Services/**: `APIClientFactory`, `VerifierFactory`, `TransactionDecoder`, `RawAPIClient` (direct HTTP for notification endpoints)
- **Output/**: `TableRenderer` (auto-switches horizontal/vertical based on terminal width), `TransactionDisplay`, `SubscriptionDisplay`, `NotificationDisplay` with configurable fields
- **Utilities/**: Pagination, date parsing, error types, Sendable conformances, `StoredConfig` + `Config` for settings resolution

## Library Quirks (v0.1.0)

- `TransactionHistoryRequest` has no public init -- use `makeTransactionHistoryRequest()` factory function
- `NotificationHistoryRequest` has no public init -- use `makeNotificationHistoryRequest()` (JSONDecoder from `{}`)
- Notification history endpoint uses `RawAPIClient` (bypasses library) because the library encodes dates as floats which Apple rejects with HTTP 400
- Library types predate Swift concurrency -- `@retroactive @unchecked Sendable` conformances are in `SendableConformances.swift`
- `AppStoreServerAPIClient` is not `Sendable` -- keep as local var in command `run()` methods
- All API results use `APIResult<T>` enum (not throws) -- use `.unwrap()` extension to convert to throwing
- `PBXFileSystemSynchronizedRootGroup` auto-discovers new `.swift` files -- no pbxproj edits needed for source files
