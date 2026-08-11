# Samsung Tizen protocol map

## Legacy source seeds

Read all files under `legacy-windows/ColorControl/Services/Samsung/`, Samsung contracts/resources, old UI panels/pages, startup/resume handlers, persistence call sites, and every caller of `SamTvConnection`.

## Capability groups to audit separately

- device identity, address, MAC, selected/default device;
- discovery and manual setup;
- secure and non-secure remote-control WebSockets;
- pairing prompt and token lifecycle;
- request/event decoding and connection readiness;
- reconnect and invalid-token recovery;
- Wake-on-LAN and power detection;
- remote keys, hold/repeat, and configured delays;
- installed/launchable apps where supported;
- screen off/on and power behavior;
- custom remote layouts;
- service, hospitality, and factory actions;
- presets, delays, retries, quick access, and event automation.

## Suggested Swift boundaries

- `SamsungTransport`: WebSocket lifecycle.
- `SamsungMessageCodec`: encode key/app requests and decode events/errors.
- `SamsungConnectionActor`: token/pairing state, readiness, reconnect, cancellation.
- `SamsungCredentialStore`: Keychain-backed token.
- `SamsungDeviceService`: typed capability commands.
- `SamsungDiscoveryService`: discovery and manual validation.

## Trust and pairing

- Do not carry over blanket certificate acceptance.
- Model first pairing, accepted token, denied pairing, expired/invalid token, and user-cancelled pairing separately.
- Store token only after confirmed successful pairing.
- On token failure, retain non-secret device configuration and guide the user through re-pairing.

## Key command safety

- Validate key names against the audited remote definition or capability set.
- Bound key repeat/hold and command queue length.
- Do not retry dangerous keys automatically unless legacy semantics and user intent justify it.
- Mark service/factory/hospitality operations destructive or advanced and require warning.

## Hardware evidence record

Record app/macOS version, TV model/firmware, endpoint type, network topology, capability, expected/actual result, and sanitized logs. Keep tests opt-in and secret-free.
