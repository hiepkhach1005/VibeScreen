# Swift and macOS quality gates

## Source and architecture

- [ ] Change maps to requirements and parity IDs.
- [ ] Legacy behavior or deliberate semantic change is evidenced.
- [ ] Domain has no SwiftUI/AppKit/network/storage imports.
- [ ] External effects are behind narrow protocols with fakes.
- [ ] Composition remains centralized; no mutable global singleton/service locator.
- [ ] No NVIDIA/AMD/web runtime dependency entered native targets.

## Swift 6 concurrency

- [ ] Main-actor state is limited to UI/presentation concerns.
- [ ] Mutable shared connection/persistence/platform state has one isolation owner.
- [ ] Cross-boundary values are genuinely `Sendable`.
- [ ] No unjustified unchecked/unsafe concurrency annotation.
- [ ] Child tasks have an owner and cancellation path.
- [ ] Streams/continuations finish exactly once and clean up on cancellation.
- [ ] No disk/network/blocking wait on the main actor.

## Reliability and errors

- [ ] Errors are typed and classified as validation, transient, permission/capability, permanent, or cancellation.
- [ ] Timeouts and retries are bounded and testable with an injected clock.
- [ ] Partial failure is preserved rather than flattened into success/failure.
- [ ] Cleanup runs on success, error, cancellation, sleep, and app termination.
- [ ] Duplicate/noisy/out-of-order events are tested where relevant.
- [ ] Persistent writes are versioned and atomic.

## Security and privacy

- [ ] Secrets use Keychain and are redacted from all output.
- [ ] Imported/network data is validated as untrusted.
- [ ] TLS/trust behavior follows the approved decision.
- [ ] Permission and entitlement changes are least-privileged and documented.
- [ ] Destructive actions require explicit intent and are absent from default tests.
- [ ] No private API, signing bypass, or undocumented core shell command.

## Tests

- [ ] Pure domain/unit tests cover new rules.
- [ ] Adapter tests cover failures and cancellation.
- [ ] Protocol/migration fixtures are synthetic and redacted.
- [ ] UI smoke/accessibility tests cover changed critical flows.
- [ ] Real-device tests are opt-in and do not leak configuration.
- [ ] Test names describe behavior and avoid order/global-state dependence.

## Build and maintainability

- [ ] Debug and relevant test targets build on the supported Mac toolchain.
- [ ] Release build is checked at milestone boundaries.
- [ ] Compiler warnings are zero or explicitly documented with a remediation task.
- [ ] Formatter/linter, if adopted, runs from documented reproducible commands.
- [ ] New dependencies have ADR/license/security/native-architecture review.
- [ ] Public symbols and non-obvious invariants are documented; comments explain why, not syntax.

## UI and performance

- [ ] UI states and visual/accessibility QA completed when affected.
- [ ] Idle app avoids aggressive polling, reconnect, and log churn.
- [ ] Lists/logs/event history have bounded retention or pagination.
- [ ] Network and device operations do not freeze UI.
- [ ] Measurements use release-like builds and documented environment before making performance claims.

## Handoff

- [ ] NEXUS/status/parity/source map updated as applicable.
- [ ] Exact commands and results recorded in progress.
- [ ] Remaining limitation/blocker and next safe step recorded.
