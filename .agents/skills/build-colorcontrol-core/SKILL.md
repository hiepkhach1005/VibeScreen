---
name: build-colorcontrol-core
description: Design and implement the native Swift domain and application-service layer for ColorControl, including device abstractions, preset and step execution, trigger evaluation, automation orchestration, game launching workflows, dependency injection, cancellation, and error policy. Use when adding or changing non-UI business logic, domain models, use cases, coordinators, app services, preset engines, automation engines, or game-launch behavior under macOS/ColorControlMac.
---

# Build ColorControl Core

Build a native application core rather than a server backend. Keep legacy behavior traceable while separating domain rules from Apple frameworks, transport protocols, storage, and SwiftUI.

## Required context

Read the project handoff files and the relevant rows in the source map and parity matrix. Before changing automation or game behavior, read:

- `references/architecture-rules.md` for boundaries and concurrency ownership;
- `references/automation-engine.md` for preset, trigger, step, cancellation, and recovery semantics;
- `references/game-launcher.md` for native application launch and lifecycle mapping.

Use `map-legacy-colorcontrol` first when behavior is not yet audited. Use `port-tv-protocols`, `implement-macos-platform-services`, or `migrate-colorcontrol-data` for implementations beyond the core boundaries.

## Workflow

1. Select one parity row or small vertical slice. Read the exact legacy implementation and every relevant call site.
2. Write the behavioral contract: inputs, outputs, state transitions, ordering, idempotency, cancellation, failure policy, and observable events.
3. Place pure concepts in Domain, orchestration in UseCases/Application, and external effects behind protocols.
4. Define narrow protocols for clocks, sleep/delay, IDs, persistence, device commands, process launch, platform events, and logging. Avoid generic repositories and managers without a concrete responsibility.
5. Assign one owner to mutable state. Use actors where state crosses concurrent tasks and `@MainActor` only for UI-facing state.
6. Implement the smallest complete vertical slice with fakes and deterministic tests before wiring concrete adapters.
7. Test success, partial failure, cancellation, duplicate events, app termination, missing targets, and retry exhaustion.
8. Update source map, parity matrix, architecture/ADR when boundaries change, and the progress handoff.

## Core invariants

- Domain types import neither SwiftUI nor AppKit.
- Core code never opens sockets, Keychain, files, displays, or system services directly.
- A preset has stable identity, ordered steps, explicit targets, and versioned serialization ownership outside Domain.
- One execution has one cancellation scope and produces a structured result per step.
- Destructive steps are explicit in the model and require policy approval from the application layer.
- Event sources emit normalized domain events; they do not execute presets themselves.
- Duplicate or rapidly repeated events are handled by an explicit debounce/coalescing policy.
- Retries are bounded and never hide permanent failures.
- The UI observes state and sends intents; it does not encode orchestration rules.
- No NVIDIA/AMD concept enters the new domain.

## Completion evidence

Require a linked parity row, protocol contract, deterministic unit tests, concurrency review, no framework leakage into Domain, and updated project memory. A compile-only result is not sufficient.
