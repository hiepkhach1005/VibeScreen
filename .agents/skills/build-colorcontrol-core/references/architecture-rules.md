# Native core architecture rules

## Dependency direction

```text
SwiftUI/AppKit features ---> Application use cases ---> Domain
                                 ^       ^                ^
                                 |       |                |
Platform adapters --------------+       |                |
Protocol/device/persistence adapters ----+----------------+
```

- Domain owns business vocabulary and invariants.
- Application use cases own orchestration and transaction/cancellation boundaries.
- Infrastructure implements network, persistence, logging, and update protocols.
- Platform implements macOS lifecycle, display, process, permission, and service protocols.
- Features own presentation models and views; they do not become alternate service layers.

## Suggested domain areas

- Devices: identity, capability, connection status, target selection.
- Presets: preset, ordered step, trigger, condition, execution policy/result.
- Automation: normalized event, rule, activation, execution history.
- Games: app identity, launch configuration, associated workflow, lifecycle state.
- Displays/profiles: platform-neutral identity and requested operations.

Do not force every model into one target if separate Swift packages or framework targets improve build/test boundaries; record the choice in an ADR.

## Protocol design

- Model capabilities rather than legacy classes: `TVCommanding`, `WakePacketSending`, `PlatformEventStreaming`, `AppLaunching`, `ProfileManaging`.
- Keep protocols narrow enough for a test fake and broad enough to represent one stable concept.
- Return domain values or typed failures, not framework dictionaries or JSON payloads.
- Make time, IDs, filesystem locations, and notifications injectable when behavior depends on them.
- Avoid protocols created only to mock every concrete type; use value types for pure logic.

## State and concurrency

- Give mutable device connection state to one actor.
- Give each running preset an explicit task/cancellation owner.
- Use `AsyncSequence` or another documented stream boundary for events; define termination behavior.
- Never call UI callbacks from arbitrary executors. Expose observable state through a main-actor presentation model.
- Do not hold actor isolation across unbounded external work when a smaller state transition suffices.
- Audit all types crossing isolation boundaries for `Sendable` correctness; do not silence warnings with unchecked conformance without proof.

## Error model

Separate:

- validation errors visible before execution;
- transient connection/time-out errors eligible for bounded retry;
- permission/capability errors requiring user action;
- permanent data or unsupported-operation errors;
- cancellation, which is not logged as a generic failure.

Preserve step-level failures in an aggregate execution result. Redact secrets and personal data before logging.

## Dependency composition

Compose concrete adapters in one app composition root. Inject protocols into use cases and presentation models. Do not use a mutable global container, static service singleton, or service locator.
