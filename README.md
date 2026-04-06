# appstore-tool

A read-only CLI for querying the Apple App Store Server API -- transactions, subscriptions, refunds, and customer data.

Built on Apple's [app-store-server-library-swift](https://github.com/apple/app-store-server-library-swift).

## Getting Started

Download the latest release.

Run the interactive setup to configure credentials and download Apple root certificates:

```bash
appstore-tool config
```

This walks you through each required setting with step-by-step instructions, saves everything to `~/.appstore-tool/config`, downloads Apple root certificates to `~/.appstore-tool/certs/`, and optionally installs shell completions.

## Usage

```bash
# Look up transactions by customer order ID (from Apple receipt email)
appstore-tool transactions order <order-id>

# List recent transaction history (most recent first)
appstore-tool transactions history <transaction-id> --limit 20

# Get full details for a single transaction
appstore-tool transactions info <transaction-id>

# Get all subscription statuses
appstore-tool subscriptions status <transaction-id>

# List all refunds across customers for a time period
appstore-tool refunds list --start-date 2024-01-01

# List refunds for a specific customer
appstore-tool refunds history <transaction-id>

# Full customer lookup (history + subscriptions + refunds)
appstore-tool customer lookup <transaction-id>

# Notification history (start date required, end date defaults to now)
appstore-tool notifications history --start-date 2024-01-01

# Custom columns for any list command
appstore-tool notifications history --start-date 2024-01-01 --fields type,product_id,storefront
```

## Configuration

Settings resolve in order: **CLI flags > environment variables > stored config** (`~/.appstore-tool/config`).

| Setting      | Flag                 | Env Var            | Description                                         |
|--------------|----------------------|--------------------|-----------------------------------------------------|
| Key path     | `--key-path, -k`     | `AST_KEY_PATH`     | Path to `.p8` private key file (required)            |
| Key ID       | `--key-id`           | `AST_KEY_ID`       | API Key ID (required)                                |
| Issuer ID    | `--issuer-id`        | `AST_ISSUER_ID`    | Issuer ID (required)                                 |
| Bundle ID    | `--bundle-id, -b`    | `AST_BUNDLE_ID`    | App bundle identifier (required)                     |
| App Apple ID | `--app-apple-id`     | `AST_APP_APPLE_ID` | Numeric Apple ID of the app                          |
| Environment  | `--environment, -e`  | `AST_ENVIRONMENT`  | `sandbox` or `production` (default: `production`)    |
| Certs dir    | `--certs-dir`        | `AST_CERTS_DIR`    | Path to Apple root `.cer` files                      |

If a required setting is missing from all sources, the tool prints an error and suggests running `appstore-tool config`.

### Output Formats

All commands support `--output` (`-o`) with three formats:

| Format  | Description                                |
|---------|--------------------------------------------|
| `table` | Human-readable aligned columns (default)   |
| `json`  | Pretty-printed JSON with all fields        |
| `csv`   | CSV with header row                        |

When table output is too wide for the terminal, it automatically switches to a vertical key-value layout.

```bash
appstore-tool transactions history <id> -o json
appstore-tool refunds history <id> -o csv
```

### Configurable Fields

Every list command supports `--fields` (comma-separated) to choose which columns appear in table/CSV output. JSON always includes all non-nil fields.

Use `--list-fields` on any command to see available field names:

```bash
appstore-tool transactions info --list-fields
appstore-tool subscriptions status --list-fields
appstore-tool notifications history --list-fields
```

Fields resolve in order: `--fields` flag > `~/.appstore-tool/config` > built-in defaults.

#### Transaction Fields

Used by: `transactions info`, `transactions history`, `transactions order`, `refunds history`.
Config key: `transaction_fields`.

| Field                    | Description                                          |
|--------------------------|------------------------------------------------------|
| `transaction_id`         | Unique transaction identifier                        |
| `original_transaction_id`| Original transaction ID (groups renewals/restores)   |
| `product_id`             | Product identifier                                   |
| `product_type`           | `Auto-Renewable Subscription`, `Consumable`, etc.    |
| `purchase_date`          | When the purchase was charged                        |
| `original_purchase_date` | When the original purchase was made                  |
| `expires_date`           | Subscription expiration date                         |
| `quantity`               | Number of items purchased                            |
| `app_account_token`      | UUID linking purchase to your user system            |
| `ownership_type`         | `PURCHASED` or `FAMILY_SHARED`                       |
| `revocation_date`        | When Apple revoked/refunded the transaction          |
| `revocation_reason`      | `Issue with app` or `Other reason`                   |
| `is_upgraded`            | Whether the subscription was upgraded                |
| `offer_type`             | `Introductory`, `Promotional`, or `Offer Code`       |
| `offer_id`               | Promotional offer identifier                         |
| `storefront`             | Three-letter country code (e.g. `USA`)               |
| `storefront_id`          | Numeric storefront identifier                        |
| `transaction_reason`     | `PURCHASE` or `RENEWAL`                              |
| `subscription_group_id`  | Subscription group identifier                        |
| `web_order_line_item_id` | Web order line item identifier                       |
| `environment`            | `Production` or `Sandbox`                            |

Defaults: `transaction_id`, `original_transaction_id`, `product_id`, `product_type`, `purchase_date`, `expires_date`, `environment`, `storefront`.

#### Subscription Fields

Used by: `subscriptions status`.
Config key: `subscription_fields`.

| Field                    | Description                                          |
|--------------------------|------------------------------------------------------|
| `subscription_group_id`  | Subscription group identifier                        |
| `status`                 | `Active`, `Expired`, `Billing Retry`, etc.           |
| `transaction_id`         | Transaction identifier                               |
| `original_transaction_id`| Original transaction ID                              |
| `product_id`             | Product identifier                                   |
| `product_type`           | Product type                                         |
| `purchase_date`          | When the purchase was charged                        |
| `expires_date`           | Subscription expiration date                         |
| `ownership_type`         | `PURCHASED` or `FAMILY_SHARED`                       |
| `offer_type`             | `Introductory`, `Promotional`, or `Offer Code`       |
| `offer_id`               | Promotional offer identifier                         |
| `storefront`             | Three-letter country code                            |
| `environment`            | `Production` or `Sandbox`                            |
| `auto_renew_status`      | `On` or `Off`                                        |
| `auto_renew_product_id`  | Product the subscription will renew to               |
| `expiration_intent`      | Why the subscription expired                         |
| `billing_retry`          | Whether Apple is retrying failed billing             |
| `grace_period_expires`   | End of billing grace period                          |
| `renewal_date`           | Next expected renewal date                           |
| `recent_sub_start`       | Most recent subscription period start                |

Defaults: `subscription_group_id`, `status`, `product_id`, `original_transaction_id`, `purchase_date`, `expires_date`, `auto_renew_status`, `environment`.

#### Notification Fields

Used by: `notifications history`, `refunds list`.
Config key: `notification_fields`.

Includes all transaction and subscription renewal fields above, plus:

| Field              | Description                                              |
|--------------------|----------------------------------------------------------|
| `type`             | Notification type (e.g. `SUBSCRIBED`, `DID_RENEW`)       |
| `subtype`          | Notification subtype (e.g. `INITIAL_BUY`)                |
| `uuid`             | Unique notification identifier                           |
| `date`             | When Apple signed/sent the notification                  |
| `version`          | Notification version (e.g. `2.0`)                        |
| `environment`      | `Production` or `Sandbox`                                |
| `app_apple_id`     | Numeric Apple ID of the app                              |
| `bundle_id`        | App bundle identifier                                    |
| `bundle_version`   | App bundle version at time of event                      |
| `send_attempts`    | Number of notification delivery attempts                 |
| `last_send_result` | Result of last attempt (e.g. `SUCCESS`, `TIMED_OUT`)     |
| `last_send_date`   | Timestamp of last delivery attempt                       |

Defaults: `type`, `subtype`, `date`, `product_id`, `transaction_id`, `original_transaction_id`, `purchase_date`, `expires_date`, `environment`.

### Config File

Running `appstore-tool config` creates `~/.appstore-tool/config` with auth and field settings:

```json
{
  "auth": {
    "key_id": "YOURKEYID",
    "issuer_id": "your-issuer-id",
    "key_path": "~/keys/AuthKey_YOURKEYID.p8",
    "bundle_id": "com.example.app",
    "app_apple_id": 1234567890,
    "environment": "production",
    "certs_dir": "~/.appstore-tool/certs"
  },
  "fields": {
    "notification_fields": ["type", "subtype", "date", "..."],
    "transaction_fields": ["transaction_id", "product_id", "..."],
    "subscription_fields": ["subscription_group_id", "status", "..."]
  }
}
```

Edit the `fields` section to customize which columns appear by default in table/CSV output. Use `--list-fields` on any command to see all available field names.

### Debugging

Use `--debug` on any command to print request details and full API error responses:

```bash
appstore-tool notifications history --start-date 2024-01-01 --debug
```

Use `--verbose` (`-v`) to print the resolved configuration before executing.

### Shell Completions

Shell completions for zsh, bash, and fish are offered during `appstore-tool config`. To install or regenerate manually:

```bash
./install-completions
```

## Security

- Private key contents are never printed, even with `--verbose` or `--debug`
- All signed payloads (JWS) from Apple are cryptographically verified against Apple root certificates before display
- No write or mutation operations -- this tool is strictly read-only


## Developing

Requires Xcode with Swift 6 (uses Xcode-managed SPM dependencies).

```bash
./build           # Release build, copies executable to ./bin/appstore-tool
./build Debug     # Debug build
```

The executable is placed at `./bin/appstore-tool`.

## License

MIT
