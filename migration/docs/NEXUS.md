# ColorControl macOS migration NEXUS

This is the compact project index. Detailed evidence belongs in the linked files rather than being duplicated here.

## Current state

- Phase: `1 — Native foundation and platform adapters`
- Repository reorganization: complete and integrity-baselined.
- Repository skills: complete; all 8 pass `skill-creator` validation.
- Formal legacy source audit: lifecycle/core and 108-row migratable function audit
  recorded; deep protocol/UI/schema verification remains open.
- Feature-parity matrix: implementation rows now record bounded native evidence and Mac/hardware gates.
- Native Swift application: Swift Package Manager app, core, persistence, TV/WOL/power, game/display adapters, and SwiftUI shell are present.
- macOS build verification: not started; current environment is Windows.

## Required reading order

1. [`AGENTS.md`](../../AGENTS.md)
2. [`migration/PROGRESS.md`](../PROGRESS.md)
3. [`migration/DECISIONS.md`](../DECISIONS.md)
4. [`migration/MASTER_PROMPT.md`](../MASTER_PROMPT.md)
5. This NEXUS
6. The task-specific repository skill under [`.agents/skills/`](../../.agents/skills/)
7. Relevant source/parity/architecture documents once created

## Repository areas

| Area | Role | Mutation policy |
|---|---|---|
| `legacy-windows/` | Behavioral source of truth | Read-only |
| `macOS/ColorControlMac/` | Native Swift application | New production code only |
| `migration/` | Prompt, progress, decisions, maps, ADRs, and handoff | Keep current after every session |
| `.agents/skills/` | Repeatable AI workflows and references | Validate after updates |

## Skill routing

| Skill | Responsibility | Validation |
|---|---|---|
| `map-legacy-colorcontrol` | Legacy evidence, source map, parity rows | Valid |
| `build-colorcontrol-core` | Domain, presets, automation, game workflows | Valid |
| `build-macos-liquid-glass-ui` | Native Apple UI, menu bar, layout, accessibility, visual QA | Valid |
| `port-tv-protocols` | LG/Samsung protocols, discovery, WOL, connection state | Valid |
| `implement-macos-platform-services` | Power/session/display/ColorSync/process/login/permissions | Valid |
| `migrate-colorcontrol-data` | Legacy schemas, dry run, backup, Keychain, idempotency | Valid |
| `enforce-swift-quality` | Swift/test/security/release gates | Valid |
| `verify-feature-parity` | Source-to-test completeness audit | Valid |

## Documents already created

- `PRODUCT_REQUIREMENTS.md`
- `LEGACY_SOURCE_MAP.md`
- `FEATURE_PARITY_MATRIX.md`
- `PLATFORM_API_MAP.md`
- `ARCHITECTURE.md`
- `DATA_MIGRATION.md`
- `UI_DESIGN_SYSTEM.md`
- `TEST_STRATEGY.md`
- `BUILD_RELEASE.md`
- `SECURITY_PRIVACY.md`
- `KNOWN_LIMITATIONS.md`
- `ROADMAP.md`
- `STATUS.md`
- `TASKS.md`
- `FUNCTION_PARITY_CHECKLIST.md`

## Documents to create or deepen next

- LG/Samsung full state-machine and redacted protocol fixtures
- game-launcher and display/color deep maps
- Function parity checklist close-out and evidence links
- ADRs for deployment target, app identity, signing, update mechanism, and helper/login-item scope
- ADRs listed in the master prompt

## Current safe task

Move `macOS/ColorControlMac/` to a Mac build machine, run the native package
tests/build, fix Swift 6 and SDK availability issues, and then exercise the LG
pairing/pointer-remote vertical slice behind the existing transport/Keychain/core
contracts. Do not change `legacy-windows/`.

## Unresolved product decisions

See [`migration/DECISIONS.md`](../DECISIONS.md). The minimum macOS version, bundle identity, supported architectures, signing/distribution, update mechanism, and hardware-dependent display scope remain open.
