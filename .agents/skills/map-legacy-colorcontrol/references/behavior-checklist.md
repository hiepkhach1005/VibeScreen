# Legacy behavior extraction checklist

## Reachability

- [ ] Entry point or UI action identified.
- [ ] Service method and downstream side effects traced.
- [ ] Feature is reachable in the current build/configuration.
- [ ] Module dependencies and startup conditions recorded.

## Inputs and defaults

- [ ] User inputs, config values, defaults, validation, and enum meanings recorded.
- [ ] Device capability or environment preconditions recorded.
- [ ] Command-line flags, hotkeys, and event triggers recorded.

## State and persistence

- [ ] In-memory state owner identified.
- [ ] File names, schemas, backup behavior, and secret storage identified.
- [ ] Stable IDs, ordering, per-device values, and migration hazards recorded.

## Timing and concurrency

- [ ] Delay, timeout, retry, polling, reconnect, and debounce behavior recorded.
- [ ] Threading/task assumptions and cancellation behavior recorded.
- [ ] Duplicate/out-of-order event behavior investigated.

## Effects and errors

- [ ] Network/system/device actions recorded in order.
- [ ] Partial failure and cleanup behavior recorded.
- [ ] User-facing and logged errors recorded with privacy implications.
- [ ] Destructive actions and confirmations identified.

## UI semantics

- [ ] Labels, grouping, disabled/hidden rules, quick access, and context menus inspected.
- [ ] Empty/loading/offline/permission states identified or marked absent.
- [ ] UI-only dead options distinguished from functioning behavior.

## Migration disposition

- [ ] Atomic feature rows created with source path and symbol.
- [ ] NVIDIA/AMD/web-only coupling classified.
- [ ] Public macOS mapping identified or research task created.
- [ ] Semantic differences and known limitations recorded.
- [ ] Tests needed for parity specified.
