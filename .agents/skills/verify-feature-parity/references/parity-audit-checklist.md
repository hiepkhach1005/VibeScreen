# Feature parity audit checklist

## Inventory completeness

- [ ] Entry points, service methods, contracts, configuration, resources, command-line actions, hotkeys, event handlers, and old UI were searched.
- [ ] Broad features are split into independently verifiable behaviors.
- [ ] Defaults, timing, retries, ordering, error policy, and persistence are represented.
- [ ] Hidden/advanced/dangerous actions are represented.
- [ ] NVIDIA/AMD/web exclusions and shared coupling were reviewed.

## Legacy evidence

- [ ] Each row cites exact path and symbol.
- [ ] Behavior is reachable, not merely declared.
- [ ] Inputs, preconditions, side effects, and outcomes are clear.
- [ ] Uncertainty is recorded as a research task rather than guessed.

## macOS disposition

- [ ] Public API/architecture mapping is specific enough to implement.
- [ ] Availability, permission, sandbox, privilege, and hardware implications are recorded.
- [ ] Semantic differences are user-visible where relevant.
- [ ] Unsupported behavior has evidence and a useful closest alternative.
- [ ] `Not applicable` is justified and does not hide retained shared behavior.

## Implementation

- [ ] Target paths exist and code is reachable from composition/UI/action entry.
- [ ] Domain/platform/protocol/persistence boundaries follow architecture.
- [ ] Failure, cancellation, cleanup, and offline/denied states are implemented.
- [ ] Destructive behavior is opt-in and guarded.
- [ ] No production placeholder or preview mock substitutes for implementation.

## Verification

- [ ] Pure behavior has focused unit tests.
- [ ] Adapters/state machines have failure and cancellation tests.
- [ ] Migration has golden, idempotency, and rollback tests.
- [ ] UI has critical smoke/accessibility evidence.
- [ ] Hardware/API-dependent claims have real-Mac/device evidence or are labeled accordingly.
- [ ] Commands, environment, and results are recorded.

## Documentation consistency

- [ ] Requirements, source map, parity matrix, platform map, architecture, limitations, status, tasks, and NEXUS do not contradict each other.
- [ ] Status matches evidence level.
- [ ] Blockers have owner/input needed/next action.
- [ ] Progress records the stopping point.

## Release-level questions

- Are any accepted-scope rows still `Not audited`, `Mapped`, `Implemented`, or `Blocked`?
- Are “full parity” statements narrowed by documented platform/hardware limitations?
- Can a fresh agent locate source, implementation, tests, and decision evidence without oral context?
- Can migration be repeated without data loss or plaintext secret exposure?
- Can automated tests run without controlling real user devices or powering down the system?
