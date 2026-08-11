# Test strategy

## Test layers

### Pure domain tests

- preset ID/clone/name/order behavior;
- compact legacy step parser and canonical serialization;
- trigger conditions and process/display matching;
- event debounce/conflict policy;
- execution result aggregation and error policy.

### Application/core tests

- preset validation before side effects;
- ordered steps, delays, timeout and bounded retry;
- cancellation before/during/after a step;
- duplicate events and concurrent executions;
- partial target/device failure;
- game launch plan and finalization.

### Protocol fixture tests

- LG/Samsung codecs, pairing, request correlation, subscriptions, invalid credentials, disconnect, reconnect, malformed/unknown fields, and redacted logs.

### Migration tests

- valid/empty/partial/malformed/future JSON;
- duplicate devices/presets;
- unsupported GPU/Windows actions;
- path repair;
- dry run no-write;
- atomic commit, rollback, repeated/idempotent import;
- Keychain success/failure with fake credential store.

### Platform tests

- fake power/session/display/process event sources;
- adapter registration/unregistration and cancellation;
- permission denied/unavailable API;
- WOL packet bytes and invalid MAC;
- real Mac checks for power/display/ColorSync/hotkeys/login item.

### UI tests

- app launch, menu bar, main window, navigation, device setup, preset CRUD, migration preview, settings and destructive confirmations;
- keyboard navigation and accessibility identifiers;
- no real TV power-off, shutdown, factory menu or system sleep in default test suite.

## Evidence levels

Classify each parity row as unit-tested, adapter-tested, UI-tested, integration-tested, hardware-verified, accepted limitation, or blocked. Unit tests do not prove public API or hardware parity.

## CI/local commands

On the Mac build machine, document exact `swift test`, `swift build`, `xcodebuild`, lint/format and archive commands after the package/Xcode target exists. On Windows, record only portable source/document checks and never claim macOS build success.
