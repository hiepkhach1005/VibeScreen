# Security and privacy model

## Sensitive data

- LG client keys.
- Samsung pairing tokens.
- Local network addresses/MAC addresses and device names.
- Imported paths and app bookmarks.
- Logs that may contain payloads or user activity.

## Rules

- Store credentials only in Keychain.
- Redact credentials, authorization payloads and sensitive network data in OSLog, fixtures, error reports and migration previews.
- Treat imported JSON and network messages as untrusted input.
- Validate lengths, enum values, URLs, MAC addresses, JSON types, paths and command arguments.
- Do not globally disable TLS/certificate validation.
- Do not shell out to privileged/undocumented commands for core behavior.
- Do not run the whole app as root.
- Request Local Network, Accessibility, Input Monitoring, Automation and Notifications permissions only when the invoked feature needs them.
- Keep the app usable when optional permission is denied.
- Require explicit intent and warnings for power-off, shutdown/restart, service/factory menus and other destructive operations.
- Do not collect telemetry by default.

## Threat boundaries

- TV WebSocket messages can be malformed or unexpected.
- Legacy folders can contain corrupted or hostile data.
- User-selected app/profile paths may become stale or inaccessible.
- Update artifacts and metadata must be signed/verified according to the distribution decision.
- Optional XPC/privileged helper requires a separate threat model and approval.

## Evidence still required

- Exact LG/Samsung trust model after protocol audit.
- Keychain access-group and migration behavior on clean install/upgrade.
- Sandbox/Local Network/Accessibility entitlement decisions.
- Update signature/feed strategy.
