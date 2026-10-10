# Security and privacy model

## Sensitive data

- LG client keys.
- Samsung pairing tokens.
- Local network addresses/MAC addresses and device names.
- Imported paths and app bookmarks.
- Logs that may contain payloads or user activity.

## Rules

- Store credentials in Keychain for every production build.
- Local debug builds may explicitly enable
  `COLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`. In that mode, store each TV
  credential as plaintext only under
  `Application Support/ColorControl/DevelopmentCredentials`, require owner-only
  directory/file permissions (`0700`/`0600`), exclude the files from backup,
  display an in-app warning, and never log, synchronize, fixture, or commit
  them. Development-file mode never reads or modifies Keychain, avoiding any
  Keychain authorization prompt; the user pairs once to create a new file if
  needed. A normal build can move that file back to Keychain and remove it on
  the next connection. Any older Keychain item remains dormant until explicitly
  removed or replaced from a normal build.
- Keep development code identity stable when testing Keychain-backed TV
  credentials. The local signing certificate is limited to development builds;
  release builds must use the selected Apple signing and provisioning path.
- Redact credentials, authorization payloads and sensitive network data in OSLog, fixtures, error reports and migration previews.
- Power diagnostics are limited to event/action names, generated correlation IDs,
  device UUIDs, boolean policy state, timing, status, and error type. They omit
  TV names, host/IP/MAC values, credentials, and protocol payloads; the current
  and previous JSONL files are owner-only (`0600`) inside an owner-only (`0700`)
  Application Support diagnostics directory and are each bounded by rotation.
- Treat imported JSON and network messages as untrusted input.
- Validate lengths, enum values, URLs, MAC addresses, JSON types, paths and command arguments.
- Do not globally disable TLS/certificate validation.
- For LG `wss:3001`, accept a locally issued leaf certificate only after the
  user reviews and confirms its SHA-256 fingerprint. Pin it to the exact device
  host; a changed certificate must fail closed and require a new confirmation.
- Do not shell out to privileged/undocumented commands for core behavior.
- Do not run the whole app as root.
- Request Local Network, Accessibility, Input Monitoring, Automation and Notifications permissions only when the invoked feature needs them.
- The editable first-TV power hotkeys use `RegisterEventHotKey`, not an event
  tap or global event monitor, and the recorder observes only key events sent
  to the focused Settings control. They therefore do not request Accessibility
  or Input Monitoring. Exclusive registration fails visibly when a chord
  conflicts, and rejected bindings are not persisted.
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

- Samsung trust model after its protocol audit; LG now uses explicit per-host
  leaf-certificate SHA-256 pinning for locally issued certificates.
- Keychain access-group and migration behavior on clean install/upgrade.
- File/Keychain mode migration integration tests with a full Xcode XCTest host.
- Sandbox/Local Network/Accessibility entitlement decisions.
- Update signature/feed strategy.
