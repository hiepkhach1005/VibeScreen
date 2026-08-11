---
name: verify-feature-parity
description: Audit ColorControl migration milestones for silent feature loss by tracing each non-GPU legacy behavior through source evidence, requirement, public macOS mapping, Swift implementation, tests, hardware evidence, status, and accepted limitation. Use before closing a feature, vertical slice, migration phase, beta, or release; when code or UI is claimed to preserve legacy behavior; or when NVIDIA/AMD/web exclusions may have removed shared functionality accidentally.
---

# Verify Feature Parity

Challenge completion claims with traceable evidence. Build success is one signal, not proof of parity.

## Required context

Read current NEXUS, product requirements, source map, feature matrix, platform map, limitations, test strategy, and progress. Load `references/parity-audit-checklist.md` and apply it to every row in scope.

Invoke `map-legacy-colorcontrol` first for unaudited or weakly sourced behavior. Invoke the relevant implementation skill when evidence exposes a gap; do not repair unrelated code during a pure audit unless the user requested implementation.

## Workflow

1. Define audit scope by module, phase, or release and list all candidate feature IDs.
2. Re-scan relevant legacy entry points, UI, configuration, resources, and cross-module call sites for missing rows.
3. Validate that each row is atomic and its legacy behavior is accurately described.
4. Inspect macOS mapping and semantic differences. Require public-API evidence for platform-sensitive claims.
5. Inspect implementation paths and verify the actual code reaches the claimed behavior.
6. Inspect tests and distinguish unit, adapter, UI, integration, and hardware evidence.
7. Verify exclusions do not remove shared preset, event, persistence, or navigation behavior needed by retained modules.
8. Downgrade unsupported statuses, create explicit gap tasks, and update limitations/NEXUS/progress.
9. Mark `Accepted` only when scope and evidence satisfy the checklist and no unresolved blocker is hidden.

## Status rules

- `Not audited`: behavior has not been traced adequately.
- `Mapped`: legacy behavior and intended macOS disposition are explicit.
- `Implemented`: reachable code exists, but required verification is incomplete.
- `Tested`: required automated and applicable integration evidence exists.
- `Accepted`: product scope and evidence were reviewed; limitations are explicit.
- `Not applicable`: intentionally excluded with reason, usually NVIDIA/AMD/web-only or truly Windows-only.
- `Blocked`: cannot proceed without external/user/hardware/API evidence; blocker and next action are documented.

Never move directly from `Not audited` to `Implemented` or `Accepted`.

## Completion evidence

Produce a concise audit report with rows checked, status changes, missing features, unsupported claims, test/hardware gaps, files reviewed, and exact next actions. Update durable documents in the same session.
