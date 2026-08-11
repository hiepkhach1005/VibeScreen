# LG WebOS protocol map

## Legacy source seeds

Read all files under:

- `legacy-windows/ColorControl/Services/LG/`
- `legacy-windows/ColorControl/LgTv/`

Also inspect LG presets, remote resources, registration payloads, UI pages/panels, startup/resume handlers, and every caller of `LgTvApi` and the connection class.

## Capability groups to audit separately

- device identity, address, MAC, selected/default device;
- discovery and manual setup;
- secure and legacy WebSocket endpoints;
- registration/pairing and client-key lifecycle;
- request ID generation and response correlation;
- subscriptions and unsolicited events;
- reconnect and invalid-key recovery;
- Wake-on-LAN and power detection;
- power off, screen off/on;
- volume, mute, media, channels;
- apps and external inputs;
- remote keys and custom remote layouts;
- mouse/remote socket behavior;
- system and picture settings;
- game bar behavior;
- presets, delays, retries, quick access, and event automation.

Do not collapse these into one parity row.

## Suggested Swift boundaries

- `LGWebOSTransport`: connect, send, receive, close.
- `LGMessageCodec`: encode request/register payloads and decode response/event/error.
- `LGConnectionActor`: own state, request correlation, subscriptions, reconnect, and cancellation.
- `LGCredentialStore`: Keychain-backed client key.
- `LGDeviceService`: capability-oriented commands exposed to the application core.
- `LGDiscoveryService`: optional discovery plus manual-device validation.

Keep raw wire URI and JSON fields inside infrastructure. Expose typed domain commands/results to the core.

## State model

At minimum distinguish:

```text
idle -> connecting -> registering/pairing -> ready
  |         |               |                |
  +---------+---------------+------> reconnecting
                                  -> needsUserAction
                                  -> closed
```

Define transitions for timeout, network loss, TV standby, rejected pairing, stale client key, app cancellation, and manual disconnect. Fail and clear pending requests on connection loss.

## Security

- Import legacy client keys into Keychain through the migration layer.
- Redact registration payloads and credentials.
- Document legacy certificate/trust behavior and replace unsafe bypass with an explicit reviewed strategy.
- Keep dangerous service actions out of quick/default surfaces.

## Hardware evidence record

For real-device validation, record app version, macOS version, TV model, firmware, secure/legacy endpoint, network topology, capability, expected/actual result, and sanitized logs. Never commit device credentials or personal network data.
