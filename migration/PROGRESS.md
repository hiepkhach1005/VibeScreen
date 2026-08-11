# macOS migration progress

This is the durable handoff file for all future AI and human work sessions.

## Current status

- Project phase: `Phase 1 / native foundation + platform adapters (Phase 0 audits continue)`
- Overall status: `In progress`
- Last updated: `2026-08-11`
- Last environment: `Windows, C:\\wsrc\\ColorControl-master`
- Native app implementation started: `Yes (Swift Package Manager foundation)`
- macOS build verified: `No`

## Current stopping point

The native Swift package under `macOS/ColorControlMac/` now contains a bounded
host-independent core plus platform adapters: typed preset execution, targeted
TV actions, WOL/power-policy coordination, versioned persistence, legacy import
preview, LG/Samsung WebSocket clients, LG pointer-input remote commands, game
launching, display snapshots/modes, Keychain, login-item, and
SwiftUI/MenuBarExtra surfaces. Unsupported or unverified actions fail visibly.
Swift/Xcode is unavailable on this Windows host, so no native build or runtime
claim has been made.

The next session must move the package to a Mac build machine, run `swift test`
and an Xcode app build, then continue the LG WebOS registration/pairing flow.
Keep `legacy-windows/` read-only and update this handoff after each slice.

## Completed work

### 2026-08-11 — Repository preparation

- Inspected the repository root and identified the original projects and assets.
- Created:
  - `legacy-windows/`
  - `macOS/ColorControlMac/`
  - `migration/`
- Moved these original items into `legacy-windows/`:
  - `ColorControl/`
  - `ColorControl.UI/`
  - `images/`
  - `LittleCms/`
  - `MHC2Gen/`
  - `NLogViewer/`
  - `novideo_srgb/`
  - `Nspector/`
  - `NvAPIWrapper/`
  - `Shared/`
  - `ColorControl.slnx`
  - the original `README.md`
- Kept `.gitignore` and license files at repository root.
- Added a new root README describing the workspace layout.
- Added root `AGENTS.md` to force future sessions to read this handoff first.
- Recorded accepted architectural decisions in `migration/DECISIONS.md`.
- Stored the complete migration instructions in `migration/MASTER_PROMPT.md`.

### 2026-08-11 — Post-move integrity verification

- Verified `legacy-windows/ColorControl.slnx` after relocation.
- All 9 solution project paths resolve inside `legacy-windows/`.
- Recursively inspected all `.csproj` `ProjectReference` entries; no missing references were found.
- Legacy baseline after relocation:
  - Files: `850`
  - Directories below `legacy-windows/`: `103`
  - Total file bytes: `6,529,163`
  - Manifest algorithm: SHA-256 of sorted `relative-path<TAB>size<TAB>file-sha256` records
  - Manifest hash: `9cd669f758618edd70b68865d54effcffd0c5cd81589a524cf194fee3bb738b2`
- This baseline is for future change detection. It does not replace the original upstream checksum because no pre-move checksum was available.
- No legacy build was run; this session only verified file and project-reference integrity.

### 2026-08-11 — Repository skills completed

- Environment: Windows, `C:\\wsrc\\ColorControl-master`.
- Objective: complete all AI workflows required for native frontend, backend/core, macOS platform integration, TV protocols, migration, quality, and parity verification.
- Used the system `skill-creator` guidance and the `frontend-design` design process.
- Completed and validated 8 repository skills under `.agents/skills/`:
  - `map-legacy-colorcontrol`
  - `build-colorcontrol-core`
  - `build-macos-liquid-glass-ui`
  - `port-tv-protocols`
  - `implement-macos-platform-services`
  - `migrate-colorcontrol-data`
  - `enforce-swift-quality`
  - `verify-feature-parity`
- Added 18 focused reference files covering source audit, architecture, automation, game launching, Apple UI/layout, visual QA, Apple API routing, permissions, LG/Samsung protocol behavior, protocol tests, legacy schemas, migration, quality, release, and parity.
- Replaced all generated TODO/template content and added consistent `agents/openai.yaml` metadata.
- Added `build-colorcontrol-core` to the master prompt to explicitly cover the native backend/domain layer.
- Created `migration/docs/NEXUS.md` as the central project index.
- Validation command: system `skill-creator/scripts/quick_validate.py` run for every skill.
- Validation result: all 8 skills report `Skill is valid!`; placeholder scan reports none.

## Source audit already known

Initial inspection identified these important legacy areas. They still need to be converted into formal source maps and parity rows:

- Lifecycle and composition:
  - `legacy-windows/ColorControl/Program.cs`
  - `legacy-windows/ColorControl/MainWorker.cs`
  - `legacy-windows/ColorControl/MainForm.cs`
  - `legacy-windows/ColorControl/Services/Common/ServiceManager.cs`
- Presets and event dispatchers:
  - `legacy-windows/ColorControl/Services/Common/ServiceBase.cs`
  - `legacy-windows/Shared/Contracts/Presets/PresetBase.cs`
  - `legacy-windows/Shared/Contracts/PresetStep.cs`
  - `legacy-windows/Shared/EventDispatcher/`
- LG WebOS:
  - `legacy-windows/ColorControl/Services/LG/`
  - `legacy-windows/ColorControl/LgTv/`
- Samsung Tizen:
  - `legacy-windows/ColorControl/Services/Samsung/`
- Game launcher:
  - `legacy-windows/ColorControl/Services/GameLauncher/`
  - `legacy-windows/Shared/Contracts/Game/`
- Display and color profile:
  - `legacy-windows/ColorControl/Services/Common/GraphicsService.cs`
  - `legacy-windows/ColorControl/Services/Common/ColorProfileService.cs`
  - `legacy-windows/MHC2Gen/`
  - `legacy-windows/LittleCms/`
- Windows-specific replacements:
  - `legacy-windows/Shared/Native/`
  - `legacy-windows/Shared/Services/`
- Legacy feature inventory UI:
  - `legacy-windows/ColorControl.UI/`
  - the LG, Samsung, Game, Options, Color Profile, and remote-control WinForms panels.

## Next actions

Execute in this order:

1. Move `macOS/ColorControlMac/` to a Mac build machine and run package tests.
2. Fix Swift 6/SDK availability issues and produce the first Xcode app build.
3. Exercise LG registration/pairing, pointer remote, subscriptions, and commands.
4. Exercise Samsung token flow, response state machine, keys, and reconnects.
5. Finish native process monitoring, ColorSync profile association, and shortcut scope.
6. Run the full parity, visual QA, signing, and hardware gates.

## Session log format

Append a new section after every work session:

```markdown
### YYYY-MM-DD — Short session title

- Environment:
- Objective:
- Completed:
- Files changed:
- Commands/tests and results:
- Decisions made:
- Open issues/blockers:
- Exact next safe step:
```

Never replace earlier entries. Append new evidence and update `Current status` plus `Current stopping point`.

### 2026-08-11 - Native foundation vertical slice

- Environment: Windows, `C:\\wsrc\\ColorControl-master`; Swift/Xcode unavailable.
- Objective: begin the native rewrite from the audited source without changing `legacy-windows/`.
- Completed:
  - Created Swift Package Manager manifest with `ColorControlCore`, executable app target, and tests.
  - Added typed preset/trigger models, legacy step parser, actor executor with retry/cancellation, repository, and automation router.
  - Added LG WebOS/Samsung Tizen request builders, endpoint mapping, generic URLSession WebSocket boundary, WOL packet builder, TV power-policy mapper, and Keychain boundary.
  - Added versioned atomic native store and dry-run LG/Samsung preset/device importers with stable IDs, GPU omission warnings, and secret redirection to Keychain references.
  - Added SwiftUI window, MenuBarExtra, Liquid Glass availability path with material fallback, settings/navigation shell, and NSWorkspace/AppKit event bridge.
  - Added host-independent tests for parser, executor, trigger matching, protocol shapes, WOL, power policy, and migration importers.
- Files changed: `macOS/ColorControlMac/` native sources/tests; migration architecture/status/tasks/roadmap/NEXUS/parity docs; this progress handoff.
- Commands/tests and results: source audits with `rg`/PowerShell completed; TODO scan clean; Swift compiler not installed, so `swift test` and Xcode build not run.
- Decisions made: keep the first executor as a safe preview adapter; do not claim real TV or hardware parity until Mac build and device tests pass; keep secrets out of JSON.
- Open issues/blockers: Mac SDK/Xcode required; full LG/Samsung state machines, display/HDR/ColorSync, game launcher, global hotkeys, OSLog, signing, and hardware evidence remain.
- Exact next safe step: run `swift test` on macOS, fix compiler/API issues, then implement the LG WebOS handshake/pairing actor behind the existing contracts.

### 2026-08-11 - Native backend and platform expansion

- Environment: Windows, `C:\\wsrc\\ColorControl-master`; Swift/Xcode unavailable.
- Objective: continue the rewrite into native adapters while preserving `legacy-windows/` as read-only source evidence.
- Completed:
  - Added target-aware preset execution so imported preset-level TV addresses select the intended device.
  - Added a real `PresetDeviceActionRouter` path for TV commands, WOL/PowerOn, display refresh, and bundle-identifier application launch; unsupported ColorSync writes remain explicit failures.
  - Added `TVPowerPolicyCoordinator` for startup, wake, sleep, screens sleep/wake, shutdown, and session lock/unlock signals with injected clocks/controllers/WOL.
  - Expanded schema-v2 native storage and the migration coordinator to settings, LG/Samsung devices and presets, game presets, remotes, stable IDs, warnings, atomic writes, backups, and Keychain references.
  - Added macOS game launch/process waiting, display-mode enumeration/application, ICC inventory/validation, login-item adapter, OSLog categories, and Network.framework WOL sending.
  - Added LG registration response polling and the legacy pointer-input WebSocket for remote buttons; preserved Samsung remote-key transport.
  - Expanded SwiftUI UI with preset CRUD/editor, TV device/power-policy editor, game launch surface, display inventory, MenuBarExtra quick access, Liquid Glass availability path, and accessibility-friendly empty/error states.
  - Added host-independent tests for parser edge cases, preset target mapping, router/WOL, TV power coordination, game/migration/store/protocol behavior.
- Files changed: `macOS/ColorControlMac/` native sources/tests; migration status, architecture, task, roadmap, NEXUS, and parity documents.
- Commands/tests and results: PowerShell source audit, brace balance, XML validation, exclusion scan, and legacy integrity checks completed; `47` Swift files totaling `228,746` bytes are present; `swift test` and Xcode build were not run because Swift/Xcode are absent.
- Decisions made: keep no web UI, .NET, NVIDIA, or AMD concepts in the new target; use documented public macOS APIs; keep credentials in Keychain; preserve unknown legacy actions as traceable failures; do not call hardware parity complete before Mac build/device evidence.
- Open issues/blockers: Mac SDK/compiler unavailable; LG/Samsung live pairing/reconnect/subscriptions, process-trigger auto game apply, global shortcuts, ColorSync profile association, full remote UI, signing/notarization, and hardware evidence remain.
- Exact next safe step: on macOS run `swift test`, open `macOS/ColorControlMac/Package.swift` in Xcode, resolve SDK/compiler diagnostics, then test LG pairing → pointer remote → power/WOL → Samsung pairing → display/color.

### 2026-08-11 - Static quality handoff after native vertical-slice expansion

- Converted the AppKit application launcher, display refresh adapter, and game
  process launcher to actor-backed adapters where they cross the core async
  protocols; this reduces Swift 6 strict-concurrency risk.
- Fixed the native TV editor's `TVPowerPolicy` initializer argument order and
  verified command-status interpolation in the app container.
- Added `macOS/ColorControlMac/ColorControlMac.entitlements` with App Sandbox
  and outgoing network-client capability. It must be selected by the Xcode app
  target during signing; Swift Package Manager does not apply it automatically.
- Added native remote controls for the bounded LG pointer/Samsung key paths,
  target-aware preset routing, macOS screen-sleep/wake mapping for legacy
  Windows monitor-power options, and startup sequencing that loads state before
  platform events are consumed.
- Static checks completed on Windows:
  - Native tree: `48` Swift files including package/tests, `235,131` bytes;
    `34` source files and `13` test files.
  - Swift source braces: `1000/1000`; square brackets: `532/532`; all native
    Swift files passed strict UTF-8 decoding.
  - `Info.plist` and entitlements XML both parse successfully.
  - No native C#, web, NVIDIA, AMD runtime/dependency markers were found;
    the only two GPU matches are intentional migration warnings that explain
    why those legacy settings are excluded. No TODO, FIXME, `fatalError`, or
    `NotImplemented` markers were found.
  - Legacy relocation baseline remains unchanged: `850` files, `103` folders,
    `6,529,163` bytes, manifest SHA-256
    `9cd669f758618edd70b68865d54effcffd0c5cd81589a524cf194fee3bb738b2`.
  - Legacy solution still resolves `9` solution projects and all `10` project
    files have valid project references.
- Verification limit remains explicit: `swift`, `swiftc`, `xcodebuild`,
  `swift-format`, and `sourcekit-lsp` are unavailable on this Windows host.
  No Swift test, app build, signing, Keychain, TV pairing, sleep/wake, WOL, or
  display-hardware claim has been made.
- Exact next step: move/open `macOS/ColorControlMac/Package.swift` on macOS,
  run `swift test`, build the executable in Xcode with the entitlements file,
  fix SDK/concurrency diagnostics, then exercise LG pairing/pointer input,
  Samsung token/key flow, WOL, sleep/session power policy, and display/color
  behavior on real hardware.

### 2026-08-11 - Function-level migratable parity checklist

- Environment: Windows, C:\wsrc\ColorControl-master; legacy-windows/ remained
  read-only; Swift/Xcode remained unavailable.
- Objective: enumerate the legacy functions that are feasible to retain on macOS,
  compare them with the current native implementation, and leave a resumable
  checklist. NVIDIA, AMD, web, Windows Service, Win32, registry, WMI, and other
  Windows-only implementation details are excluded or recorded as replacements.
- Completed:
  - Audited the relevant entry points for application lifecycle, settings,
    modules, event dispatch, power/session/process automation, presets, LG WebOS,
    Samsung Tizen, game launcher, display/color, WOL, migration, and native UI.
  - Added migration/docs/FUNCTION_PARITY_CHECKLIST.md with 108 atomic behavior
    rows. Private helper chains are grouped under their user-visible behavior;
    important legacy symbols and native source targets are recorded in each row.
  - Recorded the current static distribution: 67 Partial, 23 Missing, 1
    Blocked, 5 Implemented (static), 2 Tested (host-independent only), and
    10 Not applicable.
  - Linked the checklist from FEATURE_PARITY_MATRIX.md, LEGACY_SOURCE_MAP.md,
    and this NEXUS/progress trail.
- Evidence read:
  - Legacy application/core/event sources including Program, MainWorker,
    MainForm, ServiceManager, ServiceBase, Config, OptionsService,
    PowerEventDispatcher, ProcessEventDispatcher, and
    KeyboardShortcutDispatcher.
  - Legacy LG/Samsung device/service/transport/API sources, remote JSON, power
    policy fields, game launcher, GraphicsService, ColorProfileService, and
    WolService.
  - Native Swift models, executors, automation, TV clients/transports,
    power coordinator, migration importers/store, display adapters, app
    container, SwiftUI views, menu-bar view, and host-independent tests.
- Verification limits:
  - This is a source comparison and static reachability audit. No claim of
    macOS runtime completion, TV pairing, WOL wake, sleep/wake, display/color
    control, signing, or notarization is made.
  - The checklist intentionally distinguishes Partial, Missing, Blocked,
    Implemented (static), and Not applicable; no retained feature is marked
    end-to-end complete.
- Current stopping point:
  - The next implementation/evidence slice is LG pairing, reconnect and
    subscriptions, then pointer remote and WOL/power policy; after that repeat
    the same comparison for Samsung token/state handling.
  - The next environment action is to run swift test and an Xcode build on a
    macOS machine, then update the checklist rows with compiler/test evidence.
