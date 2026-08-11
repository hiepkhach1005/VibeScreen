---
name: enforce-swift-quality
description: Review and enforce production quality for the native ColorControl Swift codebase, covering Swift 6 strict concurrency, architecture boundaries, error and cancellation handling, tests, formatting/linting, privacy, dependency hygiene, performance, accessibility evidence, build/archive, signing, notarization, and release readiness. Use after meaningful Swift changes, before merging a vertical slice, when fixing warnings or flaky tests, and at every migration phase or release gate.
---

# Enforce Swift Quality

Use evidence from builds, tests, diffs, and project documents. Do not convert warnings into checklist prose without fixing or explicitly accepting them.

## Required context

Read current NEXUS, architecture, test strategy, security/privacy, build/release, parity, and progress documents. Load:

- `references/quality-gates.md` for implementation and milestone review;
- `references/release-checklist.md` for archive, signing, notarization, packaging, or update work.

Run only checks supported by the current environment. On Windows, review portable source/docs but do not claim Xcode validation.

## Workflow

1. Establish scope from changed files and affected parity rows.
2. Inspect architecture direction, actor ownership, lifecycle cleanup, errors, privacy, and dependency changes before running broad tools.
3. Run the smallest relevant tests, then the documented project-wide build/test/lint commands.
4. Fix root causes rather than suppressing diagnostics. Document any necessary exception with owner, rationale, risk, and removal condition.
5. Check failure/cancellation, denied permissions, offline devices, and destructive-action safeguards.
6. Verify docs and parity evidence match implementation.
7. For release work, run the release checklist on the intended Mac/toolchain and distribution configuration.
8. Record exact commands, environment, results, remaining warnings, and next step in progress.

## Review rules

- Enable Swift 6 strict concurrency and treat isolation warnings as design feedback.
- Never add `@unchecked Sendable`, `nonisolated(unsafe)`, force unwrap, `try!`, or ignored errors without a proven invariant and focused test.
- Bound retries, timeouts, queues, event streams, and memory growth.
- Verify tasks, observers, sockets, event taps, assertions, files, and continuations terminate correctly.
- Keep production secrets and identifying network data out of logs and fixtures.
- Reject private APIs, undocumented shell dependencies, blanket TLS bypasses, and unapproved privilege expansion.
- Require tests proportional to behavior and risk; snapshots/build success alone do not prove protocol or hardware parity.
- Prefer no new dependency. When one is necessary, review maintenance, license, security, size, update policy, and native architecture support.

## Completion evidence

Provide commands/results, affected tests, warnings remaining, platform/hardware limits, parity status, and file links. Never state "all tests pass" if only a subset ran.
