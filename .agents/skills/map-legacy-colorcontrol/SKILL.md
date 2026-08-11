---
name: map-legacy-colorcontrol
description: Audit the read-only legacy Windows ColorControl source and convert observed behavior into traceable source maps, requirements, call flows, feature-parity rows, exclusions, and migration evidence. Use before implementing or reviewing any feature whose legacy behavior, configuration, trigger semantics, hidden UI option, cross-module dependency, NVIDIA/AMD coupling, or source-to-test traceability is not already documented in migration/docs.
---

# Map Legacy ColorControl

Recover behavior from evidence rather than translating C# files mechanically. Produce durable maps another session can continue without rereading the whole repository.

## Required context

Read the repository handoff and current NEXUS first. Treat `legacy-windows/` as read-only. Load:

- `references/source-manifest.md` to choose the mandatory files and searches for the module being audited;
- `references/behavior-checklist.md` before finalizing feature rows.

Read complete selected files and follow call sites until inputs, side effects, persistence, events, and error handling are understood. If output is truncated, continue to EOF.

## Workflow

1. Select a bounded module or behavior and mark it `Not audited` in the working matrix.
2. Inventory source with `rg --files`; identify entry points, contracts, services, UI fields, resources, configuration, and tests.
3. Trace callers and callees with `rg -n`. Record symbol names and paths, not only directories.
4. Reconstruct observable behavior: preconditions, defaults, ordering, delays, retries, persistence, events, errors, and user-visible states.
5. Search non-GPU code for NVIDIA/AMD coupling. Mark intentional removal and any required domain redesign.
6. Split broad capabilities into atomic parity rows. For example, do not use one "LG support" row for pairing, WOL, reconnect, apps, remote keys, and power.
7. Map each row to a public macOS approach or mark the API question unresolved. Do not invent parity.
8. Update `LEGACY_SOURCE_MAP.md`, `FEATURE_PARITY_MATRIX.md`, requirements/limitations when relevant, NEXUS summary, and progress handoff.

## Evidence rules

- Cite `path` and `type/member` for every row.
- Distinguish declared UI options from implemented behavior and implemented behavior from reachable behavior.
- Record defaults and persistence filenames exactly.
- Read old UI to discover behavior but never treat appearance as a migration requirement unless it encodes workflow or grouping.
- Record uncertainty explicitly with a next investigation, not a guessed conclusion.
- Do not inspect GPU implementation deeply unless necessary to sever a non-GPU dependency.
- Never modify legacy files or generate artifacts inside `legacy-windows/`.

## Output quality

The source map must use:

| Legacy path | Legacy type/symbol | Responsibility | New module/path | Semantic differences | Audit status |

The parity matrix must use:

| Feature ID | Module | Legacy behavior | Legacy source/symbol | macOS mapping | Target source | Tests | Status | Notes/limitations |

Use stable feature IDs grouped by domain. A row can move to `Mapped` only after behavior and intended macOS handling are both explicit.
