---
name: port-tv-protocols
description: Port, implement, and test ColorControl network integrations for LG WebOS and Samsung Tizen TVs, including discovery, manual configuration, pairing, Keychain-backed credentials, WebSocket request/response correlation, subscriptions, reconnection, Wake-on-LAN, remote commands, apps, screen and power behavior, capability detection, and redacted protocol fixtures. Use for TV transport, message models, connection actors, device repositories, discovery, WOL, trust handling, or real-device integration work.
---

# Port TV Protocols

Preserve observable protocol behavior while redesigning transport and state management for Swift concurrency and macOS security. Never translate connection classes line by line.

## Required context

Read the relevant legacy source, source-map rows, and parity rows. Load only the protocol reference needed:

- `references/lg-webos-map.md` for LG tasks;
- `references/samsung-tizen-map.md` for Samsung tasks;
- `references/protocol-test-matrix.md` before implementing state transitions or declaring a workflow complete.

Use `migrate-colorcontrol-data` for credential import/storage and `implement-macos-platform-services` for local-network permissions or platform discovery APIs.

## Workflow

1. Audit one end-to-end capability from UI/service entry through message payload and response handling.
2. Capture a redacted protocol contract: endpoint, connection mode, pairing state, request shape, correlation, subscription behavior, capability assumptions, timeout, and errors.
3. Model connection state explicitly in one actor. Separate message codecs, transport, credential store, device capability, and high-level commands.
4. Implement request IDs and pending-response cleanup. Every request must complete, time out, fail on disconnect, or cancel.
5. Implement bounded reconnect with backoff and a terminal/needs-user-action state for invalid credentials or trust.
6. Store secrets through a Keychain protocol. Never log or serialize them into normal configuration.
7. Add redacted codec/state-machine fixtures before real-device tests.
8. Run opt-in hardware validation for each accepted capability and record model/firmware/network context.
9. Update protocol maps, parity rows, security notes, tests, and progress.

## Guardrails

- Do not globally disable TLS validation or accept every certificate silently.
- Do not infer that a successful socket means the TV is powered on or a command succeeded.
- Preserve multiple-device isolation; one connection failure must not corrupt another device state.
- Keep discovery optional and always allow validated manual IP/MAC entry.
- Bound network retries, polling, command queues, and key holds.
- Define cancellation and cleanup for sockets, subscriptions, timers, continuations, and pending requests.
- Redact client keys, tokens, authorization payloads, and identifying fixture data.
- Treat service/factory/hospitality commands as dangerous capabilities requiring warning and explicit intent.
- Never run power-off or factory commands in default tests.

## Completion evidence

Require legacy traceability, protocol fixture tests, connection-state tests, Keychain integration, privacy-safe logs, optional real-device evidence for hardware claims, and updated parity documentation.
