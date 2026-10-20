# macOS migration progress

This is the durable handoff file for all future AI and human work sessions.

## Current status

- Project phase: `Phase 1 / native foundation + platform adapters (Phase 0 audits continue)`
- Overall status: `In progress`
- Last updated: `2026-09-30`
- Last environment: `macOS 27.0 (26A428), arm64, Xcode 27.0 (27A266a), Swift 6.4`
- Native app implementation started: `Yes (Swift Package Manager foundation)`
- macOS build verified: `Yes (SwiftPM development app bundle built with Xcode 27.0 / Swift 6.4; Xcode archive not verified)`

## Current stopping point

The native Swift package under `macOS/VibeScreen/` previously compiled as
a debug executable on macOS 26.6.1 with Swift 6.3.3 and launched successfully
as a live process. The first Mac build fixed SwiftPM Info.plist handling, four
pre-existing core syntax/concurrency diagnostics, current CoreGraphics display
mode accessors, and the typed WOL send continuation. Xcode 27.0 is now selected
on macOS 27.0; `Scripts/build-dev-app.sh` now builds the development app bundle
with this SDK. Xcode archive/distribution signing and XCTest remain unverified.

The current ad-hoc development app now has a real bundle identifier and Local
Network usage text, visible Save & Pair/Test state, an explicitly compiled
development-only plaintext credential-file mode that never accesses Keychain,
explicit per-host certificate pinning, and a device-local LG control center. The LG
surface includes the four legacy Game Bar defaults, a broad typed scalar/array
catalog for picture/game/HDMI/AI/aspect/motion/sound/OLED/white balance,
initial settings/volume read-back, user-configurable foreground synchronization
for the Game Bar and volume that can be disabled, media/channel/input/app/URL actions,
guarded reboot, and per-device power/session automation editors kept outside
the Add/Edit TV connection form. A compact menu-bar popover now
exposes only the same five quick sliders for the first saved LG TV plus
refresh/open/quit actions, and one editable global power-toggle shortcut reads
the first TV's live state before choosing on/off, with persistence, validation,
and exclusive-registration diagnostics shown in Settings. Devices now expands as a sidebar tree with one
destination per saved TV; selecting an LG renders connection, remote,
automation, and all LG controls inline in one detail scroll view. Pairing has
been confirmed by the user; command and
firmware-specific setting behavior still requires hardware evidence. The
current local app uses the explicit owner-only development credential-file
mode. The 2026-09-30 launch smoke reproduced a clean exit immediately after
startup. LLDB showed AppKit scheduling `terminate:` after the last window was
hidden; replacing the SwiftUI `MenuBarExtra` with a standalone `NSStatusItem`
had left AppKit's last-window termination enabled. The app delegate now
returns `false` from `applicationShouldTerminateAfterLastWindowClosed(_:)`.
After rebuilding and replacing the bundle, Finder/Launch Services launch
returned successfully, the menu-bar icon remained visible with no main window,
and the process stayed alive for more than three minutes. Accessibility/input
smoke confirmed both left- and right-click open the popover, `Open ColorControl`
shows the main window, and closing that window returns to menu-bar-only while
the process remains running. Current TV power triggers and startup presets
were both disabled during this check.

The menu bar uses one public AppKit `NSStatusItem` with a transient `NSPopover`
hosting the existing SwiftUI controls. Left-click and right-click toggle that
same popover. When another app activates while the popover is open, an
`NSWorkspace.didActivateApplicationNotification` observer closes it and is
removed when the popover closes. Updated-build focus-out interaction remains
unverified because an unrelated Gatekeeper dialog blocked accessibility input.
The `Open ColorControl` action focuses the SwiftUI `Window` scene or invokes
its registered `OpenWindowAction` after that window is closed. Every
initial launch starts with accessory activation and the main window hidden,
including Finder/Dock launches; only the menu-bar Open action switches to
regular activation and shows it.
Settings now exposes the Login Item as a standard toggle, reports macOS's
enabled, disabled, approval-required, and unavailable states, opens the system
Login Items pane when approval is needed, and resynchronizes after app
activation.
Menu-bar Quit and Command-Q now enter an explicit termination path that blocks
new platform events, removes wake/session observers, cancels their event task,
and unregisters the global TV shortcut before asking AppKit to exit. The app
delegate repeats this idempotent cleanup from `applicationWillTerminate` for
other Quit routes such as the Dock.

The development bundle was rebuilt with the explicit file-credential flag and
replaced at `$HOME/Documents/VibeScreen.app`. The prior installed
bundle is retained at
`$HOME/Documents/.VibeScreen-replace-autodismiss-20260930/VibeScreen.previous.app`.
The installed app's strict code-sign verification passed and its executable
SHA-256 matches the latest SwiftPM build
(`c09b4a62bc4e0f639f704b2d7df1e87e8dc1f3a082c6c133d19ed62c542d3778`).
The pre-existing `VibeScreen.zip` was not rebuilt. The generated `.build`
directory contains the development bundle. The local ad-hoc signature is not
a Developer ID/notarized distribution build.

The latest power-policy slice now distinguishes explicit remote/shortcut
power-off from automatic screen-sleep actions. Resume, screen-wake, session
unlock, and startup power-on actions are suppressed for a manually powered-off
device unless the user enables the manual override; event-triggered presets
use the same guard. Per-device screen-only startup and shutdown options are
available in the automation editor. The behavior is build-verified but still
needs XCTest and real sleep/wake hardware evidence.

A new System Monitor destination now sits directly below the Devices tree. It
samples aggregate CPU and memory usage, processor counts, uptime, startup-volume
capacity, non-loopback network rates, public thermal pressure, power source, and
hardware-dependent IOKit battery/adapter values only while visible. Settings
persists a 500 ms–60 s sampling interval through a pulldown menu and can hide the
Monitor destination from the sidebar. Hiding it redirects an active Monitor
selection to Devices and cancels the sampling task. CPU/GPU/RAM/SSD
temperatures, SMART health, whole-system GPU utilization, disk I/O throughput,
CPU frequency, live total-system watts, and fan RPM/control remain explicitly
unavailable because the project does not use private AppleSMC, IOReport,
`powermetrics`, undocumented registry data, or privileged SMC helpers.

LG percentage labels are now direct 5% step controls in both the main device
view and menu-bar Game Bar: left-click increments, right-click or Control-click
decrements, and values clamp to their `0…100` range before using the existing
single-command and bounded read-back path. Non-percentage expert ranges retain
their existing slider-only behavior.

Screen-wake TV automation now waits one second and requires a CoreGraphics
current-session input event within the preceding five seconds before forwarding
`NSWorkspace.screensDidWakeNotification`. This prevents observed Bluetooth/HID
and maintenance wake cycles from turning the TV back on without deliberate
input. A bounded owner-only JSONL diagnostic records platform signals, this
input decision, policy/manual-latch evaluation, command origin/results, and
every actual WOL attempt without TV names, network addresses, MACs, credentials,
or protocol payloads.

The 2026-09-29 source diagnosis found that the app hid its window only for Login
Item launches and that delayed power actions retained the old controller after
automation settings changed. The follow-up fix makes all initial launches
menu-bar-only and cancels per-device pending power work before replacing its
controller. This assumes “bắt hết” meant that all LG automation toggles were
turned off. The build succeeded; tests and real-TV automation checks were not
run.

## Completed work

### 2026-08-11 — Repository preparation

- Inspected the repository root and identified the original projects and assets.
- Created:
  - `legacy-windows/`
  - `macOS/VibeScreen/`
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

1. Move `macOS/VibeScreen/` to a Mac build machine and run package tests.
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
  - Created Swift Package Manager manifest with `VibeScreenCore`, executable app target, and tests.
  - Added typed preset/trigger models, legacy step parser, actor executor with retry/cancellation, repository, and automation router.
  - Added LG WebOS/Samsung Tizen request builders, endpoint mapping, generic URLSession WebSocket boundary, WOL packet builder, TV power-policy mapper, and Keychain boundary.
  - Added versioned atomic native store and dry-run LG/Samsung preset/device importers with stable IDs, GPU omission warnings, and secret redirection to Keychain references.
  - Added SwiftUI window, MenuBarExtra, Liquid Glass availability path with material fallback, settings/navigation shell, and NSWorkspace/AppKit event bridge.
  - Added host-independent tests for parser, executor, trigger matching, protocol shapes, WOL, power policy, and migration importers.
- Files changed: `macOS/VibeScreen/` native sources/tests; migration architecture/status/tasks/roadmap/NEXUS/parity docs; this progress handoff.
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
- Files changed: `macOS/VibeScreen/` native sources/tests; migration status, architecture, task, roadmap, NEXUS, and parity documents.
- Commands/tests and results: PowerShell source audit, brace balance, XML validation, exclusion scan, and legacy integrity checks completed; `47` Swift files totaling `228,746` bytes are present; `swift test` and Xcode build were not run because Swift/Xcode are absent.
- Decisions made: keep no web UI, .NET, NVIDIA, or AMD concepts in the new target; use documented public macOS APIs; keep credentials in Keychain; preserve unknown legacy actions as traceable failures; do not call hardware parity complete before Mac build/device evidence.
- Open issues/blockers: Mac SDK/compiler unavailable; LG/Samsung live pairing/reconnect/subscriptions, process-trigger auto game apply, global shortcuts, ColorSync profile association, full remote UI, signing/notarization, and hardware evidence remain.
- Exact next safe step: on macOS run `swift test`, open `macOS/VibeScreen/Package.swift` in Xcode, resolve SDK/compiler diagnostics, then test LG pairing → pointer remote → power/WOL → Samsung pairing → display/color.

### 2026-08-11 - Static quality handoff after native vertical-slice expansion

- Converted the AppKit application launcher, display refresh adapter, and game
  process launcher to actor-backed adapters where they cross the core async
  protocols; this reduces Swift 6 strict-concurrency risk.
- Fixed the native TV editor's `TVPowerPolicy` initializer argument order and
  verified command-status interpolation in the app container.
- Added `macOS/VibeScreen/VibeScreen.entitlements` with App Sandbox
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
- Exact next step: move/open `macOS/VibeScreen/Package.swift` on macOS,
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

### 2026-08-15 — First native macOS build and launch

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  active developer directory `/Library/Developer/CommandLineTools`; full Xcode
  not installed or selected.
- Objective: build and run the converted native macOS application.
- Completed:
  - Fixed SwiftPM packaging so the future Xcode `Info.plist` is excluded from
    SwiftPM resources instead of being placed in a forbidden resource bundle.
  - Fixed pre-existing device-import syntax, LG registration manifest typing,
    TV power command routing, and strict-concurrency handling of `FileManager`.
  - Replaced obsolete CoreGraphics C display-mode accessors with current Swift
    properties and typed the WOL send continuation as `Void`.
  - Built the debug executable and launched it through Launch Services; the
    native process remained live as PID 8167 and CoreGraphics reported two
    on-screen windows during the smoke check.
- Files changed: `.gitignore`; `Package.swift`; four `VibeScreenCore` source files; two
  `VibeScreen/Platform` source files; NEXUS, build/release, feature parity,
  and this progress handoff.
- Commands/tests and results:
  - `swift --version`: Apple Swift 6.3.3, arm64-apple-macosx26.0.
  - `swift build`: passed with no compiler warnings; debug executable linked.
  - `open .../.build/arm64-apple-macosx/debug/VibeScreen`: launched;
    `pgrep`/`ps` confirmed the process remained running and the public
    CoreGraphics window list reported two visible windows for its PID.
  - `swift test`: core/app compilation progressed after source fixes but test
    compilation is blocked because the Command Line Tools installation does
    not provide the `XCTest` module.
  - `xcodebuild -version`: unavailable because the active developer directory
    is Command Line Tools rather than full Xcode.
- Decisions made: keep `Resources/Info.plist` for a future Xcode application
  target while explicitly excluding it from SwiftPM; do not add an unsafe
  Sendable wrapper around `FileManager`.
- Open issues/blockers: full Xcode is required for XCTest, app-bundle metadata,
  signing/entitlements, UI test evidence, and archive validation. No TV or
  display hardware behavior was exercised in this smoke run.
- Exact next safe step: install/select full Xcode, rerun `swift test`, then build
  an Xcode application target using `Resources/Info.plist` and
  `VibeScreen.entitlements` before LG/Samsung hardware testing.

### 2026-08-15 — Restore keyboard focus in Add TV

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: fix Add TV fields that displayed but did not accept typed values.
- Completed:
  - Diagnosed the running SwiftPM executable through `NSRunningApplication`:
    it had activation policy `prohibited`, was not active, and had no bundle ID.
  - Added a main-actor `NSApplicationDelegate` bridge at the SwiftUI composition
    root to select regular activation policy and activate the application after
    launch.
  - Rebuilt, terminated only the old VibeScreen process, and launched the
    new binary. Runtime inspection reported `active=true`, `policy=regular`.
- Files changed: `Sources/VibeScreen/App/VibeScreenApp.swift`, feature
  parity matrix, and this progress handoff.
- Commands/tests and results:
  - `swift build`: passed with no compiler warnings.
  - Runtime smoke: new PID 8756 remained live; AppKit reported regular policy
    and active foreground state.
  - `swift test`: still blocked at test compilation because this Command Line
    Tools installation has no `XCTest` module.
- Decisions made: fix the lifecycle root cause rather than adding custom text
  controls or synthetic focus workarounds to the Add TV form.
- Open issues/blockers: keyboard entry requires user confirmation in the live
  sheet; full automated UI/accessibility testing still requires Xcode/XCTest.
- Exact next safe step: user verifies Add TV typing and saving; then test one
  non-destructive TV command before power/WOL behavior.

### 2026-08-15 — Make LG pairing reachable and expose first picture control

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only; LG hardware result awaiting user interaction.
- Objective: address the absence of LG pairing feedback, missing Local Network
  app metadata, non-responsive commands, and missing brightness control.
- Legacy evidence audited:
  - `LgTv/LgTvApi.cs`: `CreateLgTvApi`, `Connect`, `MakeHandShake`,
    `SetSystemSettings`, `ExecuteRequest`.
  - `LgTv/LgTvConnectionCws.cs`: connection, registration response dispatch,
    request correlation, reconnect, and the legacy blanket certificate bypass.
  - `Services/LG/LgDevice.cs`: picture action registry, including 0...100
    brightness/backlight/contrast/color and model-year-gated actions.
  - `Resources/LG_register.json` and `LG_register_legacy.json`.
- Completed:
  - Saving a device now initiates a connection test/pairing attempt instead of
    only persisting its IP. Device rows expose Pair/Test, retry, progress,
    paired/reachable, needs-approval, and actionable error states.
  - Added a bounded pairing wait, failure cleanup, and Keychain persistence of
    the returned LG client key; aligned the signed registration permissions
    with the current legacy registration resource.
  - Added the first safe LG picture-setting slice: a 0...100 Brightness/Black
    level slider routed through the legacy create-alert/Luna/close-alert flow.
  - Added a reproducible `Scripts/build-dev-app.sh` that creates an ad-hoc
    `.app` bundle with bundle ID and Local Network usage description. Replaced
    the bare executable with this bundle for live testing.
  - Kept system TLS trust intact and surfaced guidance for explicit `ws:3000`
    testing rather than copying the legacy accept-all-certificate callback.
- Files changed: TV protocol models/router/tests, LG client, app container,
  Devices/Add TV UI, development bundle script, source/parity/limitations/
  build/NEXUS documents, and this handoff. `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `swift build`: passed with no warnings.
  - `swift build -c release`: passed with no warnings.
  - `Scripts/build-dev-app.sh`: produced an ad-hoc signed
    `.build/VibeScreen.app`; `codesign --verify --deep --strict` passed.
  - Runtime PID 9217 reported regular activation policy and bundle identifier
    `com.colorcontrol.mac`; Local Network usage text is present in the bundle.
  - `swift test`: test sources were expanded, but execution remains blocked
    because Command Line Tools does not provide `XCTest`.
- Decisions made: treat the user's report as a parity failure; do not claim the
  current app contains all legacy LG capabilities. Do not reintroduce blanket
  TLS certificate acceptance. Keep picture changes explicit and bounded.
- Open issues/blockers: user must confirm whether `ws:3000` pairing reaches the
  TV and provide model/firmware result without sharing client keys. Secure LG
  trust, request correlation/reconnect, subscriptions/read-back, discovery,
  apps/inputs/media, complete remotes, full picture settings/game bar, and Mac
  display brightness/DDC remain incomplete. Full XCTest/UI tests need Xcode.
- Exact next safe step: in the live app edit the LG device, turn off Secure
  connection for this trusted-LAN test, press Save & Pair, approve the TV prompt,
  then test Volume Up and finally the non-destructive brightness slider. Record
  the sanitized outcome before adding scoped secure-certificate trust.

### 2026-08-15 — Add explicit LG certificate pinning

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only; LG hardware confirmation pending user interaction.
- Objective: allow secure LG `wss:3001` pairing after the TV presented its
  expected locally issued, system-untrusted certificate.
- Completed:
  - Added session-scoped server-trust handling using documented
    `URLSessionDelegate` authentication challenges and Security framework trust
    evaluation.
  - System-valid certificates continue through default handling. A locally
    issued certificate is rejected on first contact, its leaf SHA-256
    fingerprint is surfaced, and it is accepted only after an explicit
    Trust & Pair confirmation for the exact configured host.
  - Persisted the pinned fingerprint with the device descriptor. Editing the
    host or disabling secure transport clears the pin; certificate changes fail
    closed and require a new confirmation.
  - Added test-source coverage proving certificate-pin persistence through the
    native atomic store. No client key, certificate body, or private address was
    added to fixtures or logs.
- Files changed: TV device model/error, WebSocket transport trust delegate,
  AppContainer trust state/action, Devices UI confirmation, persistence test,
  security/limitations/parity/NEXUS documents, and this handoff.
- Commands/tests and results:
  - `swift build`: passed with no warnings.
  - `swift build -c release`: passed with no warnings.
  - Development `.app` rebuilt and launched as PID 9665 with bundle ID
    `com.colorcontrol.mac`.
  - `swift test`: still blocked because the Command Line Tools installation
    does not provide `XCTest`; new test source therefore has no execution claim.
- Decisions made: use explicit trust-on-first-use with per-host leaf-certificate
  SHA-256 pinning; never restore the legacy accept-all callback. Keep system
  trust as the first path and fail closed on host/fingerprint mismatch.
- Open issues/blockers: the user must now verify fingerprint confirmation,
  WebOS registration prompt, client-key persistence, and one safe command on
  real LG hardware. Certificate rotation UX and full Xcode UI tests remain.
- Exact next safe step: click Pair/Test, then Trust certificate & retry, confirm
  the warning, approve ColorControl on the TV, and report only the resulting UI
  state/error (not IP, fingerprint, or client key).

### 2026-08-15 — Expose LG Game Bar and broad device controls

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only; user confirmed LG pairing before this slice.
- Objective: move the legacy LG Game Bar capabilities and remaining practical
  LG controls into the TV device surface for direct adjustment.
- Legacy evidence audited:
  - `Services/LG/LgGameBar.cs` and `.Designer.cs`: dynamic action membership,
    four default sliders, current-value updates, shortcut/topmost/auto-hide.
  - `Services/LG/LgDevice.cs`: complete invokable-action construction, scalar
    bounds/options, per-HDMI expansion, model-year gates, volume and service
    action boundaries.
  - `Shared/Contracts/LG/LgEnums.cs`: wire enum values for picture, motion,
    gaming, sound, aspect ratio, HDMI, and OLED controls.
  - `LgTv/LgTvApi.cs`: system-setting alert/Luna payload, black-level and HDMI
    nested serialization, media/channel/input/app/browser/reboot endpoints,
    volume and settings read-back.
- Completed:
  - Added `LGControlCatalog`, a typed core catalog covering the four Game Bar
    defaults and retained scalar picture, game/HDMI, AI, aspect, motion, sound,
    OLED care, and expert scalar plus 10/22-point white-balance actions with
    bounds/options and minimum model-year labels.
  - Generalized the bounded create-alert/Luna/close-alert path for system
    settings, including legacy black-level expansion, nested HDMI/AI values,
    leading-underscore normalization, and TruMotion `current_app` behavior.
  - Added typed media play/pause/stop, channel up/down, discovered/manual HDMI
    input switching, discovered/manual app launch and close, URL open, volume,
    and guarded reboot commands.
  - Replaced the single inline brightness slider with an LG controls sheet on
    each LG device. Numeric values are directly editable and support Return,
    steppers, validation, option pickers, explicit Apply buttons, keyboard
    dismissal, progress, partial read errors, and destructive confirmation.
  - Added one-shot per-category setting and volume read-back when the sheet
    opens or the user chooses Read from TV.
  - Added a separately labeled Advanced region with confirmation before reboot,
    TPC/GSR writes, service-menu flag changes, InStart/EzAdjust, or opening the
    TV software-update application. Added the legacy HDMI 1–4 device-icon and
    label choices through the bounded EIM action. Arbitrary Luna URIs remain
    unavailable.
  - Added codec test sources for Game Bar catalog membership, nested HDMI
    payloads, and legacy black-level payload expansion.
- Files changed: `LGControlCatalog.swift`, TV protocol models/router/client,
  `AppContainer.swift`, `MainWindowView.swift`, protocol tests, source/parity/
  NEXUS documents, and this handoff. `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `swift build -c debug`: passed with no warnings after the final source slice.
  - `swift build -c release`: passed with no warnings.
  - `swift test`: test compilation remains blocked because this Command Line
    Tools installation has no `XCTest` module; no test-pass claim is made.
  - Ad-hoc `.app` was rebuilt and launched; process state reported running.
- Decisions made: place the Game Bar at the TV device as explicitly requested;
  keep its default four actions expanded and Game/HDMI controls immediately
  visible. Use typed settings instead of arbitrary user-provided Luna URIs.
  Keep reboot behind confirmation and do not expose factory/service menus as
  quick actions.
- Open issues/blockers: this is not yet full LG parity. Realtime subscriptions,
  configurable Game Bar membership, floating/topmost/auto-hide/global shortcut,
  channel discovery, mute/power/foreground state, remaining reachable
  config/system-property actions,
  custom remote editing, capability detection, and real-TV command evidence
  remain. Full Xcode/XCTest and UI accessibility inspection remain unavailable.
- Exact next safe step: on the paired LG, open Devices → LG controls, verify Read
  from TV populates the four Game Bar values, then apply one reversible control
  such as Contrast or Color and report the TV model/year plus sanitized result.

### 2026-08-15 — Add drag sliders and foreground LG value synchronization

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only; paired LG available for user-driven testing.
- Objective: replace numeric percentage entry with direct sliders, add a TV
  volume slider, and keep the visible values aligned with the TV.
- Completed:
  - Replaced every scalar range TextField/Stepper with a native SwiftUI Slider.
    Values update while dragging and the command is sent once on release, which
    avoids flooding the WebOS socket. 0–100 controls show a percentage suffix.
  - Added a prominent 0–100 volume slider above media/input/app actions and
    removed its duplicate from the collapsed Sound group.
  - Added an awaited LG control execution path so the sheet knows when a write
    has completed and immediately reads the authoritative TV values afterward.
  - The sheet still performs one full read on open. While visible, a bounded
    cancellable task refreshes only Backlight, Contrast, Brightness, Color, and
    Volume every 5 seconds. It pauses during dragging, writes, and full refresh;
    closing the sheet cancels it, so there is no background polling.
  - Added visible synchronized/progress state and disabled duplicate interaction
    during initial reads and writes.
- Files changed: `AppContainer.swift`, `MainWindowView.swift`, LG source/parity
  documentation, and this handoff. `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `swift build -c debug`: passed with no warnings.
  - `swift build -c release`: passed with no warnings.
  - `git diff --check`: passed; `legacy-windows/` remained clean; the native
    source scan found no unchecked/unsafe Sendable, `try!`, or `fatalError`.
  - Development `.app` rebuilt, ad-hoc signature verification passed, and the
    latest app process reported running.
  - `swift test` remains unavailable because Command Line Tools has no XCTest.
- Decisions made: synchronize by bounded foreground read-back until the actor-
  owned WebOS subscription/correlation state machine is implemented. Do not use
  persistent background polling or send a network request for every drag tick.
- Open issues/blockers: real-TV verification of slider write/read-back remains
  user-driven; WebOS protocol subscriptions, reconnect restoration, mute state,
  and full Xcode UI/accessibility tests remain pending.
- Exact next safe step: rebuild/relaunch the development app, then have the user
  open LG controls, confirm the sliders adopt the TV values, drag Volume once,
  and verify the TV and app converge on the same number after release.

### 2026-08-15 — Persist LG pairing across launches and stabilize development Keychain access

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only; no Apple Development or Developer ID identity was
  installed; paired LG configuration and Keychain item were present.
- Objective: reuse the LG client key automatically after app/Mac restart and
  stop repeated Keychain authorization while using TV controls.
- Root cause evidence:
  - The LG client key remained present in the `com.colorcontrol.mac` generic-
    password service; the TV was not forgetting the pairing.
  - The prior development bundle was ad-hoc signed. Its designated requirement
    was based on a changing executable code hash, so Keychain treated rebuilt
    artifacts as different clients.
  - `AppContainer` loaded state both from its initializer and the main-window
    task, recreating controller actors and their credential state twice.
- Completed:
  - Added one-shot automatic connection restoration after persisted devices are
    loaded. A saved LG now reconnects with its client key without requiring a
    Pair/Test click; the UI uses Reconnect or Approve pairing only when those
    actions are actually needed.
  - Cached the LG client key inside the device actor after its first Keychain
    read, eliminating repeated Keychain reads while sliders and commands run.
  - Removed the duplicate main-window reload and changed connection copy to
    explain that TV approval is expected only on first pairing.
  - Added `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` for newly written
    TV credentials while keeping all secrets out of native JSON.
  - Added a one-time local development signing-identity setup script and made
    the app-bundle build select that stable certificate, with explicit ad-hoc
    fallback warnings. Installed the scoped identity on this development Mac.
- Files changed: `AppContainer.swift`, `MainWindowView.swift`,
  `TVDeviceClients.swift`, `MacTVWebSocketTransport.swift`, `Package.swift`,
  `Scripts/build-dev-app.sh`, `Scripts/create-local-signing-identity.sh`, build/
  security documentation, and this handoff. `legacy-windows/` remained
  read-only.
- Commands/tests and results:
  - `swift build` and `swift build -c release`: passed.
  - Development app assembly and strict `codesign` verification: passed; the
    bundle is signed by `ColorControl Local Development` and its designated
    requirement is anchored to the stable leaf certificate plus bundle ID.
  - The rebuilt `.app` launched successfully and remained running.
  - `swift test` remains blocked because the selected Command Line Tools
    installation has no `XCTest` module; no test-pass claim is made.
- Decisions made: do not put LG/Samsung credentials in JSON, weaken the Keychain
  ACL, or ship restricted entitlements on an ad-hoc signature. A failed attempt
  to use restricted access-group entitlements was removed after `amfid`
  correctly rejected that development bundle.
- Open issues/blockers: changing from ad-hoc to the stable development identity
  changes macOS privacy identity once. Local Network is currently reported as
  prohibited for the new identity and must be enabled once by the user; the
  existing Keychain item may likewise require one final approval before its ACL
  recognizes the stable signer. Full Apple Developer signing/provisioning and
  clean-install/upgrade Keychain evidence remain pending.
- Exact next safe step: enable ColorControl under System Settings → Privacy &
  Security → Local Network, return to the already running app, approve any one-
  time legacy Keychain prompt, and verify that a second app relaunch reconnects
  without TV approval or a Keychain dialog.

### 2026-08-15 — Isolate local development credentials from Keychain

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only; paired LG configuration present.
- Objective: stop local development builds from requiring any Keychain or
  signing-identity password and store newly paired TV credentials in files.
- Completed:
  - Added a narrow `TVCredentialStore` boundary, production
    `KeychainCredentialStore`, owner-only `DevelopmentFileCredentialStore`, and
    mode router shared by LG, Samsung, and Samsung endpoint construction.
  - The development app script compiles
    `COLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`; that branch never reads,
    writes, or deletes Keychain items. It stores each key/token as a separate
    plaintext file under
    `~/Library/Application Support/ColorControl/DevelopmentCredentials`, with
    directory `0700`, file `0600`, atomic replacement, backup exclusion,
    reference validation, and symlink rejection.
  - Changed the local app script to ad-hoc signing only, so it does not query a
    certificate/private key from Keychain. Settings visibly warns about the
    less-secure mode and shows its path. Deleting a device deletes its active
    credential. Normal/release builds remain Keychain-backed and can move a
    development file back to Keychain on the next connection.
  - Rebuilt, strictly verified, stopped the old Keychain-using process, and
    launched the new file-only development bundle as PID 3625.
- Files changed: `Platform/CredentialStores.swift`, TV transport/device clients,
  `AppContainer.swift`, Settings UI, `Scripts/build-dev-app.sh`, README,
  migration architecture/build/data/security/parity/NEXUS docs, and this
  handoff. Existing unrelated user changes were preserved; `legacy-windows/`
  remained read-only.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release`: passed after the Keychain-isolation change.
  - `Scripts/build-dev-app.sh`: passed with ad-hoc signing.
  - `codesign --verify --strict --verbose=2 .build/VibeScreen.app`: passed.
  - `swift test`: remains blocked at compilation because this Command Line
    Tools installation has no `XCTest` module; no test-pass claim is made.
  - New file-mode app process launched successfully. No credential file exists
    yet because TV approval is required once; file creation/permission evidence
    is therefore pending and no real-TV persistence claim is made.
- Decisions made: do not access the old Keychain item from file mode because
  even one migration read/delete can trigger the password prompt. Leave that
  dormant item untouched; pair once to obtain a new file credential. Preserve
  mandatory Keychain storage in production builds.
- Open issues/blockers: user must approve the new pairing on the TV, after which
  file existence/`0600` mode and password-free relaunch can be verified. Full
  XCTest remains unavailable without full Xcode.
- Exact next safe step: approve ColorControl on the TV once, then inspect only
  the file name/mode (never contents), relaunch, and verify there is no Keychain
  prompt or repeated TV approval.

### 2026-08-15 — Move automation settings onto each saved TV

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: remove power/session automation from Add TV and expose it as a
  clearly device-scoped configuration surface.
- Completed:
  - Reduced Add/Edit TV to connection identity, platform, host, MAC address,
    secure transport, and pairing. Existing policies are preserved when
    connection details are edited; new devices receive the typed default.
  - Added a labeled Automation button and enabled/disabled status to every
    saved TV row. Its sheet names the TV, groups power/session and screen
    sleep/wake events, disables subordinate controls when automation is off,
    validates the non-negative delay, and supports default/cancel keyboard
    actions.
  - Added an `AppContainer` policy-only save path. It persists the updated
    device snapshot and replaces only that device's controller/policy
    registration, without Pair/Test or disrupting other TVs.
  - Added source coverage proving two TV descriptors round-trip independent
    power policies through `NativeStore`.
- Files changed: `MainWindowView.swift`, `AppContainer.swift`,
  `NativeStoreTests.swift`, UI design/parity/NEXUS docs, and this handoff.
  Existing unrelated user changes were preserved; `legacy-windows/` remained
  read-only.
- Commands/tests and results:
  - Debug file-mode `swift build`: passed with no warnings.
  - `swift build -c release`: passed with no warnings.
  - `git diff --check`: passed.

  - `swift test`: still blocked at compilation because Command Line Tools has
    no `XCTest` module; the new persistence test has no execution claim.
  - Development app assembly and strict ad-hoc `codesign` verification passed;
    the rebuilt app launched successfully as PID 2057.
- Decisions made: automation belongs to the saved device row/detail, not the
  short reversible Add TV setup flow. Saving automation must not initiate
  network pairing and must not rebuild unrelated device controllers.
- Open issues/blockers: full Xcode UI tests, VoiceOver/keyboard inspection, and
  screenshot QA in light/dark/accessibility appearances remain unavailable.
- Exact next safe step: in Devices, open Automation on two different TVs, save
  different trigger values, relaunch, and verify each device restores only its
  own settings; then capture full Xcode UI/accessibility evidence.

### 2026-08-15 — Hide the Add/Edit TV scroll indicator

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: remove the visible vertical scrollbar from the compact TV
  connection sheet.
- Completed: hid the Add/Edit TV `Form` scroll indicator while preserving
  scrolling for constrained windows and accessibility text sizes.
- Files changed: `MainWindowView.swift` and this handoff.
- Commands/tests and results: file-mode debug build passed; release build
  passed; `git diff --check` passed; development bundle assembly and strict
  ad-hoc signature verification passed; rebuilt app launched as PID 2222.
- Decisions made: hide only the indicator, not scrolling or content access.
- Open issues/blockers: full Xcode screenshot and accessibility QA remain.
- Exact next safe step: reopen Add TV and visually confirm the indicator is
  absent at normal and increased text sizes while trackpad scrolling still works.

### 2026-08-15 — Add device tree navigation and inline TV controls

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: make every saved TV a child destination under Devices and remove
  LG Controls/Automation popup navigation.
- Completed:
  - Replaced the fixed sidebar selection with typed static/device destinations.
    `Devices` is an expanded tree containing `All devices` plus one child row
    per stable TV UUID. Deleted selections safely fall back to `All devices`.
  - Add/Edit remains a short connection sheet. Saving from All devices now
    selects the newly added/edited TV destination automatically.
  - Added a single-scroll device detail with connection/pairing/error state,
    remote buttons, inline power/session automation, and inline LG Game Bar,
    media/input/app, setting groups, and guarded advanced actions. Samsung
    details show the shared connection/remote/automation surface without LG
    controls.
  - Removed LG Controls and Automation sheet state. LG initial read and bounded
    5-second synchronization are owned by the visible detail task and cancel
    when navigation removes that detail.
  - Kept connection editing as a sheet and added explicit confirmation before
    deleting a TV from its detail.
- Files changed: `MainWindowView.swift`, UI design/parity/NEXUS/status docs,
  and this handoff. Existing unrelated user changes were preserved;
  `legacy-windows/` remained read-only.
- Commands/tests and results:
  - File-mode debug and normal release `swift build`: passed with no warnings.
  - `git diff --check`: passed; unsafe-concurrency/force-crash source scan clean.
  - `swift test`: blocked at compilation because Command Line Tools has no
    `XCTest` module; no test-pass claim is made.
  - Development app assembly and strict ad-hoc signature verification passed;
    rebuilt app launched as PID 2788.
  - Live Accessibility inspection confirmed `All devices` in the sidebar tree,
    one scroll area in the selected device detail, and both `Power and session
    automation` and `LG controls` present inline (`true, true, 1`). No private
    device values were recorded in repository evidence.
- Decisions made: use macOS master-detail tree navigation; keep only short
  reversible setup/edit flows modal. Do not nest LG Controls in a second scroll
  view or keep its polling alive outside the selected device page.
- Open issues/blockers: full Xcode UI tests and screenshot QA across light/dark,
  minimum window, long device names, Reduce Transparency, and Increase Contrast
  remain unavailable.
- Exact next safe step: visually exercise All devices → TV child → another
  destination → TV child, confirm LG read-back pauses/resumes with selection,
  then capture full Xcode UI/accessibility evidence.

### 2026-08-15 — Merge All devices into the Devices parent

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: remove the redundant `All devices` child while preserving a
  compact selectable/expandable Devices tree.
- Completed: removed `All devices`; tagged the `Devices` disclosure row as the
  overview destination. Selecting its row opens the existing device overview,
  while its disclosure control still expands/collapses individual TV children.
  Deleted-device fallback now lands directly on `Devices`.
- Files changed: `MainWindowView.swift`, UI design documentation, and this
  handoff. Existing unrelated changes were preserved; `legacy-windows/`
  remained read-only.
- Commands/tests and results: file-mode debug and normal release builds passed;
  `git diff --check` passed; development bundle/signature verification passed;
  rebuilt app launched as PID 2960. Runtime Accessibility inspection confirmed
  selecting the Devices parent opens the Devices overview (`true`), the sidebar
  has one fewer row (`11` in the current configuration), and its TV child still
  exposes inline Automation/LG Controls (`true, true`).
- Decisions made: one parent row owns both overview selection and tree
  disclosure; avoid a redundant overview child label.
- Open issues/blockers: full Xcode UI/screenshot QA remains unavailable.
- Exact next safe step: visually click both the Devices label and disclosure
  chevron, then verify selection and expand/collapse remain independently clear.

### 2026-08-15 — Move automation below LG controls

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: prioritize direct LG controls before device automation in the TV
  detail reading order.
- Completed: reordered LG detail to Connection/Remote → LG Controls → Power and
  session automation. Samsung retains Connection/Remote → Automation because it
  has no LG section.
- Files changed: `MainWindowView.swift`, UI design documentation, and this
  handoff. Existing unrelated changes were preserved; `legacy-windows/`
  remained read-only.
- Commands/tests and results: file-mode debug and normal release builds passed;
  `git diff --check` passed; development bundle/signature verification passed;
  rebuilt app launched as PID 3228. Live Accessibility ordering returned
  `true, true, true`: both headings exist and LG Controls precedes Automation.
- Decisions made: keep both sections inline in the same scroll view and change
  only their task-oriented reading order.
- Open issues/blockers: full Xcode screenshot QA remains unavailable.
- Exact next safe step: visually scroll the LG detail from controls into
  automation at normal and minimum supported window sizes.

### 2026-08-15 — Make LG slider rows responsive

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: keep LG control labels aligned while allowing every slider to
  grow with a wider device-detail window.
- Completed: centralized a fixed 240-point label column in `LGControlRow`,
  removed the fixed 320-point slider width, and made range editors consume the
  remaining row width while retaining a 240-point minimum. Game Bar and Volume
  inherit the same responsive layout from the shared row component.
- Files changed: `MainWindowView.swift`, UI design documentation, and this
  handoff. Existing unrelated changes were preserved; `legacy-windows/`
  remained read-only.
- Commands/tests and results: file-mode debug and normal release builds passed;
  `git diff --check` and strict ad-hoc signature verification passed;
  development bundle assembly passed and rebuilt app launched as PID 5264.
  Runtime Accessibility measurement showed the same slider growing from 349
  points in a 920-point window to 829 points in a 1400-point window.
- Decisions made: labels remain stable for scanability; only the range editor
  absorbs additional horizontal space. Numeric values retain their fixed-width
  trailing column.
- Open issues/blockers: full Xcode UI tests and appearance/accessibility QA
  across Dark Mode, larger text, and minimum window size remain unavailable.
- Exact next safe step: visually resize the LG detail through its full supported
  range and verify long localized labels remain readable without truncating the
  numeric value column.

### 2026-08-15 — Clarify and enlarge TV remote shortcuts

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: make the icon-only TV remote commands easier to identify, hover,
  and click.
- Completed: grouped the nine shortcuts into power, audio, and navigation
  clusters with separators; replaced borderless compact controls with large
  bordered buttons; added plain-language native hover help and matching
  accessibility labels/hints for every command. Replaced unsupported volume
  symbols with `speaker.minus` and `speaker.plus` after runtime visual review
  exposed blank icons.
- Files changed: `MainWindowView.swift`, UI design documentation, and this
  handoff. Existing unrelated changes were preserved; `legacy-windows/`
  remained read-only.
- Commands/tests and results: file-mode debug and normal release builds passed;
  development bundle assembly, `git diff --check`, and strict ad-hoc signature
  verification passed. Runtime screenshot review confirmed all nine final icons
  render at the larger size in the device detail.
- Decisions made: retain icon-only density but rely on native macOS `.help`
  tooltips and VoiceOver metadata for explicit meaning; use visual grouping to
  distinguish power, volume, and directional operations.
- Open issues/blockers: automated pointer-hover screenshot capture and full
  Xcode UI/accessibility tests remain unavailable with Command Line Tools only.
- Exact next safe step: manually hover each shortcut and verify the native help
  text, then keyboard-tab through all nine buttons at minimum window width.

### 2026-08-15 — Add configurable LG live synchronization

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: let users change or disable the five-second LG Game Bar/volume
  foreground polling interval.
- Completed:
  - Added persisted `lgLiveSyncEnabled` and `lgLiveSyncIntervalSeconds` native
    settings with backward-compatible decoding, defaults of enabled/five
    seconds, and a bounded 1–3600 second interval.
  - Added an LG live sync Settings section with a toggle, Stepper, disabled
    interval state, accessibility hint, and explicit enabled/disabled behavior
    copy.
  - Split the initial full device read from the periodic live-value task. The
    polling task now restarts by configuration identity, cancels cleanly when
    disabled or when the detail disappears, and cannot overlap itself.
  - Kept initial page load, manual Read from TV, and post-command read-back when
    polling is disabled. No TV push-subscription claim is made; WebOS event
    subscriptions remain a separate parity item.
  - Added native-settings decoding/default and interval-boundary unit tests.
- Files changed: `NativeStore.swift`, `AppContainer.swift`,
  `MainWindowView.swift`, `NativeStoreTests.swift`, parity/data/UI docs, and this
  handoff. Existing unrelated changes were preserved; `legacy-windows/`
  remained read-only.
- Commands/tests and results: file-mode debug and normal release builds passed;
  development bundle assembly passed and the Settings screen was reviewed in
  the live app. Targeted `swift test --filter NativeStoreTests` remains blocked
  before test execution because Command Line Tools does not provide `XCTest`;
  no test-pass claim is made.
- Decisions made: this is a global LG foreground-refresh preference rather than
  a per-device automation policy. Disabling it stops periodic network reads but
  preserves explicit and command-triggered read-back.
- Open issues/blockers: install/use full Xcode to execute XCTest and UI tests;
  WebOS volume/picture/power/app subscriptions are still missing under LG-005.
- Exact next safe step: run `swift test --filter NativeStoreTests` with full
  Xcode selected, then verify live task cancellation while toggling sync off on
  an open LG detail.

### 2026-08-15 — Consolidate top-level feature tabs into Overview

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: combine Overview, Presets, Games, Automation, and Activity into a
  single destination while keeping Devices and Settings separate.
- Completed:
  - Removed the Presets, Games, Automation, and Activity destinations from the
    sidebar. The sidebar now contains Overview, the selectable Devices tree,
    and Settings.
  - Converted those four former screens into inline sections beneath the
    existing Overview dashboard. One outer `ScrollView` owns the entire page;
    the embedded sections no longer create nested scroll areas.
  - Kept preset create/apply/edit/delete and game launch behavior reachable.
    `New preset` now lives in the Presets section instead of a destination-only
    toolbar item.
  - Added a useful empty Presets state and updated NEXUS, UI design, and UI-001
    parity documentation to match the new navigation.
- Files changed: `MainWindowView.swift`, `migration/docs/NEXUS.md`,
  `migration/docs/UI_DESIGN_SYSTEM.md`,
  `migration/docs/FUNCTION_PARITY_CHECKLIST.md`, and this handoff. Existing
  unrelated user changes were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - Development-file debug `swift build`: passed with no warnings.
  - `swift build -c release`: passed with no warnings.
  - Development bundle assembly and strict ad-hoc `codesign` verification:
    passed; rebuilt app launched as PID 6884.
  - Runtime screenshot review confirmed the compact sidebar and the Presets
    section continuing below the dashboard in the same Overview scroll area.
  - `git diff --check`: passed.
  - `swift test --filter NativeStoreTests`: still blocked before test execution
    because Command Line Tools does not provide the `XCTest` module; no test-pass
    claim is made.
- Decisions made: Devices remains a separate tree because each TV owns its own
  controls and automation. Settings remains separate because it is global app
  configuration; all other top-level feature surfaces are sections in Overview.
- Open issues/blockers: full Xcode UI tests plus keyboard, VoiceOver, Dark Mode,
  and accessibility-appearance QA remain unavailable.
- Exact next safe step: with full Xcode selected, run the UI navigation tests
  and verify Overview scrolling reaches Presets, Games, Automation, and Activity
  at minimum and expanded window sizes.

### 2026-08-15 — Add persisted Overview sidebar visibility

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: let the user show or hide Overview from Settings, with Overview
  hidden by default.
- Completed:
  - Added `showOverviewInSidebar` to `NativeAppSettings`. New settings and old
    snapshots without this field both resolve to `false`; encoding preserves an
    explicit user choice.
  - Added the native `Show Overview in sidebar` toggle under Settings → Native
    application and persisted changes through the existing atomic native store.
  - Made the sidebar render Overview conditionally and changed the initial
    destination to Devices. If Overview becomes hidden while selected, navigation
    safely falls back to Devices.
  - Added decoding-default and visibility round-trip unit coverage; updated
    NEXUS, UI design, CFG-002, and UI-001 documentation.
- Files changed: `NativeStore.swift`, `AppContainer.swift`,
  `MainWindowView.swift`, `NativeStoreTests.swift`, `migration/docs/NEXUS.md`,
  `migration/docs/UI_DESIGN_SYSTEM.md`,
  `migration/docs/FUNCTION_PARITY_CHECKLIST.md`, and this handoff. Existing
  unrelated user changes were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - Development-file debug `swift build`: passed with no warnings.
  - `swift build -c release`: passed with no warnings.
  - Development bundle assembly and strict ad-hoc `codesign` verification:
    passed; rebuilt app launched as PID 7379.
  - Runtime Accessibility-driven toggle checks confirmed Overview is absent at
    the default `false` value, appears immediately at `true`, and disappears
    again at `false`. The persisted value was returned to and verified as
    `false` before handoff.
  - `git diff --check`: passed.
  - `swift test --filter NativeStoreTests`: blocked before test execution because
    Command Line Tools does not provide `XCTest`; no test-pass claim is made.
- Decisions made: this is a global persisted presentation preference. Devices
  remains the safe default destination because it is always present and useful
  even when no TV has been added.
- Open issues/blockers: full Xcode is required to execute the new unit tests and
  UI navigation tests; Dark Mode, VoiceOver, and keyboard-only QA remain open.
- Exact next safe step: select full Xcode, run `swift test --filter
  NativeStoreTests`, then add a UI smoke test that toggles Overview visibility
  and verifies the fallback selection.

### 2026-08-15 — Simplify Settings informational sections

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: remove non-actionable Settings content highlighted for cleanup
  while retaining controls and the required credential-storage warning.
- Completed:
  - Removed the Runtime, Data migration, and Legacy source metadata rows.
  - Removed the long LG live-sync explanatory paragraph; the toggle and refresh
    interval remain unchanged.
  - Removed the `Reload shell state` button because normal settings changes save
    immediately and do not require a manual reload action.
  - Renamed the remaining app section to `Application` and condensed Safety into
    `Credential storage`. Keychain status remains visible, while development
    file mode still warns that keys are less secure and explains how a normal
    build migrates them back to Keychain and deletes the files.
  - Updated UI design and UI-008 parity documentation.
- Files changed: `MainWindowView.swift`,
  `migration/docs/UI_DESIGN_SYSTEM.md`,
  `migration/docs/FUNCTION_PARITY_CHECKLIST.md`, and this handoff. Existing
  unrelated user changes were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - Development-file debug `swift build`: passed with no warnings.
  - `swift build -c release`: passed with no warnings.
  - Development app assembly and runtime screenshot review passed; compact
    Settings shows only Application, LG live sync, and Credential storage.
  - `git diff --check` and strict ad-hoc `codesign --verify --strict`: passed.
  - XCTest remains unavailable in Command Line Tools; no test-pass claim is
    made.
- Decisions made: retain only controls or safety information that changes user
  behavior. Credential warnings remain mandatory in development file mode.
- Open issues/blockers: full Xcode XCTest and appearance/accessibility QA remain
  unavailable.
- Exact next safe step: select full Xcode and run the Settings UI smoke tests,
  including credential warning visibility and keyboard/accessibility navigation.

### 2026-08-16 — Keep LG Volume live-read independent from Game Bar settings

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: fix the Volume slider staying stale when an LG TV rejects a
  picture/Game Bar setting during the same foreground refresh.
- Completed:
  - Split `AppContainer.loadLGLiveValues(for:)` into independent picture and
    volume reads. A failed Game Bar setting request no longer prevents
    `ssap://audio/getVolume` from running or clears successful partial values.
  - Preserved the existing initial read, manual `Read from TV`, post-change
    read-back, and configurable/disableable foreground polling behavior.
  - Updated the native parity/source-map index to identify Volume as part of
    the device-local Game Bar surface and to record the partial-read behavior.
- Files changed: `AppContainer.swift`, `migration/docs/NEXUS.md`,
  `migration/docs/FUNCTION_PARITY_CHECKLIST.md`,
  `migration/docs/FEATURE_PARITY_MATRIX.md`,
  `migration/docs/LEGACY_SOURCE_MAP.md`, and this handoff. Existing unrelated
  changes were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`:
    passed with no warnings.
  - `swift build -c release`: passed with no warnings.
  - `Scripts/build-dev-app.sh`: passed; development app assembled and
    development credential warning emitted as expected.
  - `codesign --verify --strict --deep .../VibeScreen.app` and
    `git diff --check`: passed.
  - `swift test --filter ProtocolAndWakeTests`: blocked before test execution
    because Command Line Tools does not provide `XCTest`; no test-pass claim
    is made.
- Decisions made: keep foreground polling as bounded request/response reads
  for now; preserve whichever live values succeed instead of treating one
  unsupported picture key as a failed Volume synchronization.
- Open issues/blockers: real LG hardware verification and WebOS push
  subscriptions remain pending; full Xcode is required to run XCTest.
- Exact next safe step: with a paired LG TV, change Volume on the TV and
  confirm the Game Bar Volume value updates on the configured interval; then
  run the protocol/UI tests with full Xcode selected.

### 2026-08-16 — Make long LG control sections collapsible

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: add expand/collapse affordances to Remote/media, Games & HDMI,
  and Advanced so the LG device page stays compact while preserving quick
  access to every action.
- Completed:
  - Added native `DisclosureGroup` sections for `Remote, media, inputs, and
    apps`, `Game & HDMI`, and `Advanced`.
  - Set all three sections closed by default and gave each an independent
    state so opening or closing one does not affect the others.
  - Preserved existing command controls, dangerous-action confirmation, and
    accessibility-friendly native disclosure arrows.
  - Updated the UI design-system documentation.
- Files changed: `MainWindowView.swift`, `migration/docs/UI_DESIGN_SYSTEM.md`,
  and this handoff. Existing unrelated changes were preserved;
  `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`:
    passed with no warnings after fixing the escaping view-builder closure.
  - `swift build -c release`: passed with no warnings.
  - `Scripts/build-dev-app.sh`: passed; development app assembled and
    ad-hoc-signed.
  - `codesign --verify --strict --deep .../VibeScreen.app` and
    `git diff --check`: passed.
  - Runtime screenshot review confirmed disclosure arrows for Remote/media and
    Game & HDMI in the LG detail; Advanced uses the same component below.
  - Full XCTest remains unavailable because Command Line Tools does not provide
    `XCTest`; no test-pass claim is made.
- Open issues/blockers: full Xcode UI/accessibility tests and dark-mode,
  keyboard-only, and VoiceOver QA remain pending.
- Exact next safe step: with full Xcode selected, run the LG detail UI smoke
  test and verify keyboard/VoiceOver expansion and collapse for all three
  sections at minimum window width.

### 2026-08-16 — Default collapsible LG sections to closed

- Follow-up to the collapsible-section change: the three independent
  DisclosureGroup states now initialize to `false`, so Remote/media, Game &
  HDMI, and Advanced open closed when the LG device tab is first shown.
- Re-ran `Scripts/build-dev-app.sh`; the development app bundle was rebuilt
  and ad-hoc-signed. A runtime screenshot of the rebuilt bundle confirmed the
  Advanced section renders closed with its disclosure arrow.

### 2026-08-16 — First-TV menu-bar sliders and global power shortcuts

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: expose the four LG Game Bar controls plus Volume from the macOS
  menu bar, target the first saved TV when several devices exist, and add two
  convenient global shortcuts for first-TV power on/off.
- Completed:
  - Changed `MenuBarExtra` to window style so the popover supports interactive
    SwiftUI sliders instead of menu-only rows.
  - Added five compact slider rows, live read, manual refresh, send-on-drag-end,
    and bounded read-back for the first saved LG TV. Empty and first-device-is-
    Samsung states explain why sliders are unavailable.
  - Added fixed exclusive `Control-Option-Command-Up` (power on) and
    `Control-Option-Command-Down` (power off) registrations through the public
    Carbon hot-key API. Both target `devices.first`; PowerOn uses the existing
    WOL path and PowerOff uses the existing device command path.
  - Added a Settings section that displays both chords and their registration
    status. This implementation does not install an event tap/global monitor
    and does not request Accessibility or Input Monitoring permission.
  - Added cleanup for partial registration failures and visible conflict/error
    reporting without logging device identity or credentials.
- Files changed: `VibeScreenApp.swift`, `MenuBarView.swift`,
  `AppContainer.swift`, new `MacGlobalTVShortcutManager.swift`, platform/UI/
  parity/security/NEXUS documentation, and this handoff. Existing unrelated
  user changes were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed
    with no warnings.
  - `swift build -c release -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`:
    passed with no warnings.
  - `Scripts/build-dev-app.sh`: passed; the development app was assembled,
    ad-hoc-signed, launched, and exposed a menu-bar status item.
  - `git diff --check`: passed.
  - `swift test`: blocked before test execution because the selected Command
    Line Tools toolchain does not provide `XCTest`; no test-pass claim is made.
  - Automated screenshot/accessibility inspection was blocked by missing
    Screen Recording/Accessibility authorization for the test shell. The
    generated screenshot was black, so no visual-pass claim is made.
- Decisions made: use fixed four-modifier arrow chords to reduce likely system
  conflicts; fail visibly if another app owns either chord; keep device
  selection deterministic by always using the first saved TV.
- Open issues/blockers: do not trigger either shortcut in automated checks
  because it would affect a real TV. Full Xcode UI tests, permission-authorized
  menu-bar accessibility QA, and opt-in real-TV power execution remain pending.
- Exact next safe step: with full Xcode selected and a test TV available, run
  menu-bar keyboard/VoiceOver UI tests, then explicitly verify both shortcuts,
  including no-device and shortcut-conflict states.

### 2026-08-16 — Editable first-TV power shortcuts

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: let the user replace both global first-TV power shortcuts from
  Settings and report conflicts without losing a working binding.
- Completed:
  - Added a Codable/Sendable `GlobalKeyboardShortcut` value with physical key
    code, display key, and explicit Command/Option/Control/Shift flags.
  - Extended `NativeAppSettings` with backward-compatible defaults for both
    shortcuts; old snapshots decode to `Control-Option-Command-Up/Down`.
  - Added focused native shortcut recorder buttons. Change enters a visible
    recording state, Escape cancels, and a shortcut must contain Command,
    Option, or Control.
  - Reconfigured both Carbon hotkeys as one pair. Identical bindings are
    rejected before registration; exclusive registration conflicts show an
    inline Settings error, do not persist, and trigger restoration of the
    previous working pair.
  - Added persistence round-trip and old-snapshot-default XCTest coverage.
- Files changed: `NativeStore.swift`, `MacGlobalTVShortcutManager.swift`,
  `AppContainer.swift`, `MainWindowView.swift`, `NativeStoreTests.swift`,
  platform/UI/parity/security/NEXUS documentation, and this handoff. Existing
  unrelated user changes were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - Development-file debug `swift build`: passed with no warnings.
  - Development-file release `swift build -c release`: passed with no warnings.
  - `Scripts/build-dev-app.sh`: passed; the app was rebuilt, ad-hoc-signed,
    launched, and strict `codesign` verification passed.
  - A separate non-destructive Carbon registration probe for the running app's
    default power-on chord returned `eventHotKeyExistsErr` (`-9878`), confirming
    the exclusive conflict path without invoking a TV command.
  - `git diff --check` and focused unsafe-concurrency/force-crash scan: passed.
  - `swift test --filter NativeStoreTests`: blocked before test execution
    because Command Line Tools does not provide `XCTest`; no test-pass claim is
    made.
- Decisions made: record ordinary key events only while the Settings control
  has focus; require a non-Shift registration modifier; use Carbon exclusive
  registration as the conflict authority and retain the last working pair if
  replacement fails.
- Open issues/blockers: Carbon reports exclusive registration conflicts but
  cannot prove that every shortcut configured through every macOS subsystem is
  discoverable in advance. Full Xcode UI/XCTest and opt-in real-TV execution
  remain pending.
- Exact next safe step: manually verify changing both bindings and the
  duplicate/conflict inline error in Settings without invoking TV power, then
  run the persistence/UI tests with full Xcode.

### 2026-08-16 — Compact menu-bar control surface

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: remove redundant device-description and preset content from the
  menu-bar popover and reduce its footprint.
- Completed:
  - Removed the “Controlling the first TV” subtitle and the entire Quick
    presets section, including empty-state preset copy.
  - Kept the five first-LG sliders, read/refresh behavior, Open ColorControl,
    and Quit actions unchanged.
  - Reduced popover width from 390 to 360 points, padding from 14 to 12 points,
    row spacing, header symbol size, slider label/value columns, and footer
    control size.
  - Recorded the deliberate menu-bar preset omission in the UI design and
    function-parity documentation; presets remain available in the main app.
- Files changed: `MenuBarView.swift`, `UI_DESIGN_SYSTEM.md`,
  `FUNCTION_PARITY_CHECKLIST.md`, and this handoff. Existing unrelated user
  changes were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - Development-file Debug and Release SwiftPM builds passed with no warnings.
  - `git diff --check` passed.
  - `Scripts/build-dev-app.sh` passed; the development app was rebuilt,
    ad-hoc-signed, launched, and strict `codesign` verification passed.
- Decisions made: keep the menu bar as a focused five-slider command surface;
  leave preset browsing and device context in the main window.
- Open issues/blockers: automated screenshot/accessibility QA remains blocked
  by test-shell permissions, and full Xcode UI tests remain unavailable.
- Exact next safe step: manually inspect the compact popover with the first TV
  online/offline and then run menu-bar keyboard/VoiceOver tests with full Xcode.

### 2026-08-16 — Remove dense slider tick marks

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: remove the dotted marks rendered beneath sliders in both the LG
  device UI and menu-bar popover without changing integer TV values.
- Completed:
  - Removed the explicit `step: 1` argument from both SwiftUI slider surfaces,
    which removes the dense per-step marks on the current macOS slider style.
  - Preserved integer behavior because both existing bindings round every
    slider update before storing or sending it to the TV.
  - Updated the UI design guidance to avoid dense tick rendering for these
    range controls.
- Files changed: `MainWindowView.swift`, `MenuBarView.swift`,
  `UI_DESIGN_SYSTEM.md`, and this handoff. Existing unrelated user changes were
  preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - Development-file Debug and Release SwiftPM builds passed with no warnings.
  - `git diff --check` passed.
  - `Scripts/build-dev-app.sh` passed; the development app was rebuilt,
    ad-hoc-signed, launched, and strict `codesign` verification passed.
- Decisions made: retain native SwiftUI sliders and integer rounding rather
  than replacing them with a custom track solely to hide decorative ticks.
- Open issues/blockers: automated screenshot review remains blocked by the
  test shell's Screen Recording permission; full Xcode UI tests are unavailable.
- Exact next safe step: visually confirm the clean tracks in the app and menu
  bar, then run appearance/VoiceOver slider checks with full Xcode.

### 2026-08-16 — ColorControl app and menu-bar icon

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: replace the generic display symbol with a recognizable
  ColorControl mark in both the app bundle and the menu bar.
- Completed:
  - Added the shared SwiftUI `ColorControlMark`: a monitor with three control
    bars; the menu-bar variant is monochrome while the app artwork is rendered
    as a blue/purple gradient with cyan, green, and orange controls.
  - Added a native AppKit renderer and generated the complete macOS iconset plus
    `ColorControlIcon.icns`; the generated 1024px artwork was visually inspected.
  - Updated `MenuBarExtra` to use the custom mark with an accessibility label.
  - Added `CFBundleIconFile` metadata and copied the `.icns` into the packaged
    app from `Scripts/build-dev-app.sh`.
  - Excluded packaging-only icon files from SwiftPM source discovery so builds
    remain warning-free.
- Files changed: `VibeScreenApp.swift`, `ColorControlMark.swift`,
  `Package.swift`, `Info.plist`, `Scripts/render-app-icon.swift`,
  `Scripts/build-dev-app.sh`, `Resources/AppIcon.iconset/`,
  `Resources/ColorControlIcon.icns`, `UI_DESIGN_SYSTEM.md`,
  `PLATFORM_API_MAP.md`, and this handoff. Existing unrelated user changes
  were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `swift Scripts/render-app-icon.swift ...` plus `sips`/`iconutil`: passed;
    generated valid 1024px PNG and macOS `.icns`.
  - Development-file `swift build`: passed with no warnings.
  - Development-file release `swift build -c release`: passed with no warnings.
  - `Scripts/build-dev-app.sh`: passed; app bundle was rebuilt and ad-hoc
    signed with the icon resource copied into `Contents/Resources`.
  - `plutil`, `file`, and `codesign --verify --strict --deep`: passed; the
    bundle reports `CFBundleIconFile=ColorControlIcon.icns` and a valid icon.
  - App launch smoke check: `open .build/VibeScreen.app` succeeded and
    the process remained running.
  - `git diff --check`: passed.
  - `swift test --filter NativeStoreTests`: blocked before test execution
    because the selected Command Line Tools toolchain does not provide
    `XCTest`; no test-pass claim is made.
- Decisions made: keep the menu-bar mark vector/native and monochrome instead
  of reusing a full-color bitmap, while using the richer gradient artwork for
  Dock/Finder where it remains recognizable at larger sizes.
- Open issues/blockers: full Xcode asset-catalog validation, Dock cache refresh,
  and permission-authorized menu-bar accessibility/screenshot QA remain pending
  on the target Mac; the current bundle/signature checks are successful.
- Exact next safe step: run the final release-quality checks and manually verify
  the new mark in Dock/Finder and the menu-bar popover after quitting any older
  ColorControl process.

### 2026-08-16 — Refresh icon in the running app

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Observation: the packaged `.icns` was valid, but a development app launched
  from the existing bundle still showed the SwiftPM placeholder in Dock and
  made the menu-bar mark easy to miss.
- Completed:
  - Assign `NSApp.applicationIconImage` from the bundled `.icns` during launch,
    so replacing a development bundle updates Dock immediately instead of
    waiting for Finder/LaunchServices cache invalidation.
  - Increased the menu-bar mark to 20 points and added a `ColorControl` hover
    help string while retaining the accessibility label.
  - Rebuilt, relaunched, and captured the Mac desktop: Dock now shows the
    blue/purple ColorControl monitor mark and the menu bar shows the compact
    monitor/control mark.
- Files changed: `VibeScreenApp.swift` and this handoff. Existing
  unrelated user changes were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `Scripts/build-dev-app.sh`: passed; app rebuilt and ad-hoc-signed.
  - `open .build/VibeScreen.app`: passed; process remained running.
  - `screencapture` plus visual inspection: confirmed the new Dock icon and
    menu-bar mark are visible.
  - `git diff --check`: passed.
- Open issues/blockers: Finder/Dock may retain a stale icon for copies of the
  app opened from another path; quit that copy and relaunch the rebuilt bundle
  before comparing artwork.
- Exact next safe step: perform final release/debug build and signature checks,
  then distribute the rebuilt `.app` rather than an older copied bundle.

### 2026-08-16 — Make the menu-bar app discoverable

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Observation: a 20-point custom SwiftUI mark alone was too subtle in a busy
  status bar, even though `MenuBarExtra` was registered.
- Completed:
  - Made the status-item label intrinsic and explicit: packaged ColorControl
    artwork at 20 points plus the visible `ColorControl` name, with combined
    VoiceOver label and hover help.
  - Loaded the icon at a fixed 20-point `NSImage` size to prevent the `.icns`
    source dimensions from expanding the status item unexpectedly.
  - Kept the native SwiftUI mark as a fallback when the packaged artwork is not
    available.
  - Rebuilt, relaunched, and visually verified the status bar: the blue/purple
    ColorControl icon and `ColorControl` name are both visible.
- Files changed: `VibeScreenApp.swift`, `ColorControlMark.swift`,
  `UI_DESIGN_SYSTEM.md`, `PLATFORM_API_MAP.md`, and this handoff. Existing
  unrelated user changes were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `Scripts/build-dev-app.sh`: passed; debug app rebuilt and ad-hoc-signed.
  - `open .build/VibeScreen.app`: passed; process remained running.
  - `screencapture` plus visual inspection: passed; menu bar shows both icon
    and app name.
  - `git diff --check`: passed.
- Open issues/blockers: full Xcode UI/accessibility tests remain unavailable;
  the checked-in app bundle is the one that must be launched after rebuild.
- Exact next safe step: run the final release build/signature checks and keep
  the menu-bar label visible until a later compactness review explicitly asks
  to remove the app name.

### 2026-08-16 — Compact menu-bar icon label

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: keep the visible ColorControl icon in the menu bar while removing
  the redundant `ColorControl` text.
- Completed:
  - Removed only the status-item text; the packaged 20-point icon remains.
  - Preserved hover help and the combined VoiceOver label (`ColorControl menu`).
  - Rebuilt, relaunched, and visually verified the icon-only status item.
- Files changed: `VibeScreenApp.swift`, `UI_DESIGN_SYSTEM.md`,
  `PLATFORM_API_MAP.md`, and this handoff. Existing unrelated user changes were
  preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `Scripts/build-dev-app.sh`: passed; app rebuilt and ad-hoc-signed.
  - `open .build/VibeScreen.app`: passed; process remained running.
  - `screencapture` plus visual inspection: passed; only the ColorControl icon
    remains in the menu bar.
  - `git diff --check`: passed.
- Open issues/blockers: full Xcode UI/accessibility tests remain unavailable.
- Exact next safe step: run the final release build and strict bundle-signature
  check, then use the rebuilt `.app` for manual menu-bar testing.

### 2026-08-16 — Add macOS Sound controls to the menu bar

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: expose sound output selection and volume from the existing compact
  menu-bar popover, keep software volume synchronized with macOS, and keep that
  surface independent from the LG WebOS volume slider.
- Completed:
  - Added `MacAudioOutputService`, a public Core Audio HAL adapter that
    enumerates output devices, identifies HDMI transport, switches the default
    system output, and writes scalar volume only when the device reports a
    settable software control.
  - Added a Sound section to `MenuBarView` with an output picker, macOS-only
    volume slider, and explicit unsupported-HDMI messaging. The visible
    popover refreshes the Core Audio snapshot every two seconds, then stops
    with the menu-bar surface. The Game Bar section now contains all five LG
    sliders, including WebOS TV Volume, and remains targeted at the first
    saved LG TV only.
  - Updated the platform map, UI design system, and known-limitations register
    to document the Core Audio boundary and generic HDMI hardware-volume limit.
  - The existing popover smoke capture showed the available outputs, including
    `LG TV SSCR2 · HDMI`; the final separation is covered by the rebuilt source
    and compile checks. Full interactive HDMI hardware screenshots remain
    pending on the target Mac.
- Files changed: `MacAudioOutputService.swift`, `AppContainer.swift`,
  `MenuBarView.swift`, `UI_DESIGN_SYSTEM.md`, `PLATFORM_API_MAP.md`,
  `FEATURE_PARITY_MATRIX.md`, `KNOWN_LIMITATIONS.md`, and this handoff. Existing unrelated user changes
  were preserved; `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed
    with no warnings.
  - `swift build -c release -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`:
    passed with no warnings.
  - `Scripts/build-dev-app.sh`: passed; development app rebuilt and ad-hoc
    signed.
  - `plutil` bundle metadata check and `codesign --verify --strict --deep`:
    passed; `CFBundleIconFile=ColorControlIcon.icns` remains present.
  - `git diff --check`: passed.
  - `swift test --filter NativeStoreTests`: still blocked before test execution
    because the selected Command Line Tools toolchain does not provide
    `XCTest`; no test-pass claim is made.
- Decisions and limitations: Sound intentionally never sends WebOS commands.
  Core Audio cannot guarantee a generic hardware volume path for HDMI; the
  separate fifth Game Bar slider continues to send LG TV volume over WebOS.
  Other HDMI receivers need a documented device protocol or hardware control.
  Real TV/receiver and HDMI-CEC behavior still require target hardware.
- Exact next safe step: install/run with full Xcode on the target Mac, then
  verify output switching, software-volume read/write, the separate LG WebOS
  Game Bar volume slider, disconnect/reconnect behavior, and VoiceOver on
  physical HDMI hardware.

### 2026-08-16 — Revert menu-bar Sound controls

- Objective: remove the newly added macOS Sound/output controls after deciding
  to use the native macOS sound menu instead, while preserving the original
  first-LG Game Bar surface.
- Completed:
  - Removed the Sound section, Core Audio polling, output picker, and macOS
    volume writer from `MenuBarView` and `AppContainer`.
  - Restored the compact menu-bar popover to the five LG WebOS sliders,
    including TV Volume, with its prior refresh/open/quit behavior.
  - Removed the temporary `MacAudioOutputService` adapter and reverted the
    Sound-specific platform/parity/limitation documentation.
- Verification: debug/release builds, development app packaging, the bundle
  metadata check, strict bundle-signature verification, and `git diff --check`
  passed after this revert. XCTest remains unavailable in the Command Line
  Tools-only environment.

### 2026-08-16 — Normalize LG WebOS volume read-back

- Objective: fix the LG TV Volume slider displaying `0%` when the TV reports a
  non-zero value such as `15`.
- Completed:
  - Confirmed the configured TV's live response over `ssap://audio/getVolume`:
    current firmware returns `payload.volumeStatus.volume` (for example `15`),
    rather than a direct `payload.volume` scalar.
  - Expanded `LGVolumeValueParser` in the core protocol layer to accept numeric
    JSON values, numeric strings such as `"15.0"`, and firmware/bridge payloads
    wrapped under `volume`, `value`, `level`, `currentVolume`, `masterVolume`,
    or `volumeStatus`, including responses that omit the outer `payload`; the
    result is clamped to 0–100 for the slider.
  - Updated `LGWebOSDeviceClient.readVolume()` to parse the complete bounded
    payload, so both old direct responses and the current `volumeStatus`
    response are handled.
  - Added protocol tests covering number, decimal-string, wrapped-object,
    `volumeStatus`, and upper-bound inputs. The existing independent volume
    read in both device controls and menu-bar Game Bar flows now uses the
    normalized result.
- Files changed: `TVProtocolModels.swift`, `TVDeviceClients.swift`,
  `ProtocolAndWakeTests.swift`, and this handoff. Existing unrelated changes
  were preserved; `legacy-windows/` remained read-only.
- Verification:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`:
    passed.
  - `Scripts/build-dev-app.sh`: passed; development app rebuilt and
    ad-hoc-signed, then relaunched from `.build/VibeScreen.app`.
  - Bundle `plutil` metadata and strict `codesign --verify --strict --deep`:
    passed; `CFBundleIconFile=ColorControlIcon.icns` remains present.
  - `git diff --check`: passed.
  - Direct WebSocket probe against the configured TV returned
    `volumeStatus.volume = 15`; this was the fixture used to identify and fix
    the response-shape mismatch.
  - `Scripts/build-dev-app.sh`, bundle metadata check, strict codesign
    verification, and `git diff --check`: passed.
  - XCTest execution remains blocked because the selected Command Line Tools
    toolchain does not provide `XCTest`; real-TV read-back verification is the
    next required hardware step.

### 2026-08-16 — Remove the menu-bar popover title row

- Objective: make the menu-bar popover more compact by removing the redundant
  ColorControl icon/title row while retaining the status-item icon itself.
- Completed: removed the in-popover icon and `ColorControl` title; loading
  feedback remains beside the Game Bar refresh action.
- Files changed: `macOS/VibeScreen/Sources/VibeScreen/Features/MenuBarView.swift`
  and this handoff.
- Verification: debug build, development app packaging, bundle metadata,
  strict codesign verification, and `git diff --check` passed.
- Exact next safe step: open the rebuilt app and confirm the compact popover in
  both light and dark menu bars.

### 2026-08-16 — Diagnose TV power-on after manual shortcut power-off

- Objective: investigate the report that the TV powers back on several minutes
  after using the global TV power-off shortcut; no product code was changed.
- Evidence:
  - The saved LG policy has `triggersEnabled`, `powerOnAfterResume`,
    `powerOnAfterScreenSaver`, `powerOffOnScreenSaver`, `powerOffOnStandby`,
    `powerOffOnShutdown`, and `powerOnAfterStartup` enabled. The screenshot
    shows the same screen-sleep/wake and resume toggles enabled.
  - `TVPowerPolicyEngine` maps `didWake` to `powerOn` when
    `powerOnAfterResume` is enabled, and maps `screensDidWake` to `powerOn`
    when `powerOnAfterScreenSaver` is enabled. It has no manual-power-off
    suppression or event-source memory. The shortcut calls a direct
    `PowerOff` command and does not mark the TV as manually powered off.
  - The current saved preset list has no event-triggered presets, so the
    observed behavior is not caused by a user preset in the repository.
  - `pmset -g custom` reports AC `displaysleep=2`, `sleep=1`, and `powernap=1`;
    `pmset -g log` records display-off/system-sleep followed by network/Bluetooth
    dark wakes. Those wakes are sufficient to produce the app's resume/screen
    wake signals.
  - ColorControl automation logs at 13:31:07 and 13:32:24 coincide with the
    observed sleep/dark-wake cycle. They only record a generic failure because
    the current development app is denied Local Network access, so they do not
    prove a successful TV power-on in this environment.
- Diagnosis: the most likely cause is the enabled resume/screen-wake policy
  conflicting with a manual shortcut power-off. A secondary contributing issue
  is that the current implementation does not distinguish a manual TV
  power-off from an automatic one. No fix was applied per request.
- Files changed: this handoff only.
- Exact next safe step: add event/action-specific logging and reproduce once
  with the Local Network permission enabled before deciding on a behavior fix.

### 2026-08-16 — Prevent automatic wake after manual TV power-off

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: stop a TV turned off by the remote or global shortcut from being
  powered back on by later resume/screen-wake events, while preserving the
  automatic screen-sleep/wake behavior and adding macOS startup/shutdown screen
  actions.
- Completed:
  - Added a per-device manual-power latch to `TVPowerPolicyCoordinator`.
    Remote/shortcut power-off and screen-off commands set the latch; explicit
    power-on/screen-on commands clear it. Automatic wake actions are suppressed
    while the latch is set unless the existing manual override option is
    enabled.
  - Applied the same latch in `PresetDeviceActionRouter`, so migrated or
    event-triggered presets cannot bypass the manual-off rule with a power-on or
    screen-on action.
  - Preserved automatic screen-sleep behavior: only a screen-off generated by
    the automation policy can be restored by the corresponding macOS
    `screensDidWake` event. The app follows the public macOS wake signal rather
    than attempting to classify individual HID devices.
  - Added per-device `Turn screen on after macOS startup` and `Turn screen off
    on macOS shutdown` options. These screen-only options take precedence over
    their full TV power counterparts when both are enabled, and include inline
    help text.
  - Added policy-engine, coordinator, and router regression tests for manual
    suppression, explicit re-enable, automatic screen wake, and screen-only
    startup/shutdown mapping.
- Files changed: `TVProtocolModels.swift`, `TVPowerCoordinator.swift`,
  `PresetDeviceActionRouter.swift`, `AppContainer.swift`, `MainWindowView.swift`,
  `TVPowerPolicyTests.swift`, `TVPowerCoordinatorTests.swift`,
  `PresetDeviceActionRouterTests.swift`, `FEATURE_PARITY_MATRIX.md`,
  `FUNCTION_PARITY_CHECKLIST.md`, and this handoff.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`:
    passed with no warnings.
  - `Scripts/build-dev-app.sh`: passed; app bundle rebuilt and ad-hoc signed.
  - `plutil` bundle metadata and `codesign --verify --strict --deep`:
    passed; the ColorControl icon remains in the packaged bundle.
  - `git diff --check`: passed.
  - `swift test --filter 'TVPowerPolicyTests|TVPowerCoordinatorTests|PresetDeviceActionRouterTests'`:
    blocked before test execution because this Command Line Tools-only
    toolchain does not provide `XCTest`; no XCTest pass claim is made.
- Decisions and limitations: manual-off state is held for the lifetime of the
  running app and is cleared by an explicit user power-on/screen-on command or
  device reconfiguration. Real-TV behavior, sleep/wake ordering, WOL, and
  shutdown timing still require Local Network permission and hardware testing.
- Exact next safe step: install/use full Xcode on the target Mac, run the three
  power/router test groups, then verify on the LG TV that remote/shortcut off
  remains off across Mac dark wakes while automation screen sleep still wakes
  on mouse/keyboard activity; finally verify the two startup/shutdown options.

### 2026-08-16 — Make macOS startup/shutdown options visible

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: expose the two screen-only macOS lifecycle options clearly in the
  per-device automation UI and verify their existing execution path.
- Completed:
  - Moved `Turn screen on after macOS startup` and `Turn screen off on macOS
    shutdown` into a dedicated, always-visible `macOS startup and shutdown`
    group instead of burying them in the longer power/session list.
  - Kept both toggles bound to the persisted `TVPowerPolicy` fields. Enabling
    startup maps the `.startup` signal to `screenOn`; enabling shutdown maps
    `NSWorkspace.willPowerOffNotification` to `screenOff` through
    `TVPowerPolicyCoordinator`.
  - Added explanatory help text stating that these commands control only the
    TV screen and are per-device.
- Files changed: `MainWindowView.swift` and this handoff. The lifecycle model,
  coordinator, platform event source, persistence, and regression tests remain
  in the previous power-policy slice.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`:
    passed.
  - `Scripts/build-dev-app.sh`: passed; app bundle rebuilt and ad-hoc signed.
  - `plutil` bundle metadata, strict `codesign --verify --strict --deep`, and
    `git diff --check`: passed.
  - XCTest remains blocked by the Command Line Tools-only environment because
    `XCTest` is unavailable.
- Open issues: the user must relaunch the rebuilt app to see the new group;
  real shutdown timing and TV screen commands still require Local Network
  permission and hardware verification.
- Exact next safe step: open the rebuilt app, select a TV, enable the desired
  toggles in `macOS startup and shutdown`, save, then verify startup and
  shutdown on the target Mac/TV with full Xcode tests available.

### 2026-08-16 — Focus the first TV on app launch

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: make the main window open directly on the first saved TV instead
  of selecting the `Devices` tree node.
- Completed:
  - Added initial selection fallback in `MainWindowView`: when devices load and
    the current selection is `nil` or `.devices`, the first saved device UUID
    becomes the selected navigation item.
  - Kept the Devices tree expanded and preserved the empty-state behavior when
    no TV has been configured. Removing the selected TV now naturally focuses
    the first remaining TV; an empty list returns to `Devices`.
- Files changed: `MainWindowView.swift` and this handoff.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`:
    passed.
  - `Scripts/build-dev-app.sh`: passed; app bundle rebuilt and ad-hoc signed.
  - `codesign --verify --strict --deep` and `git diff --check`: passed.
  - XCTest remains blocked by the Command Line Tools-only environment because
    `XCTest` is unavailable.
- Exact next safe step: relaunch the rebuilt app with at least one saved TV and
  confirm that its detail page is selected while the Devices tree remains
  expanded.

### 2026-08-16 — Keep the menu bar resident after closing the main window

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: let the main window close from its red X without terminating the
  menu-bar app or leaving a Dock icon behind.
- Completed:
  - Added an AppKit window-close observer in the application delegate. After
    the main window closes and no regular app window remains, the app switches
    to `.accessory` activation policy, which removes it from the Dock while
    keeping `MenuBarExtra` and its background services alive.
  - Updated the menu-bar `Open ColorControl` action to restore `.regular`
    activation policy, activate the app, and open the main window again.
  - Kept the real `Quit` action unchanged: choosing Quit terminates the entire
    process, including the menu-bar item.
- Files changed: `VibeScreenApp.swift`, `MenuBarView.swift`, and this
  handoff.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`:
    passed.
  - `Scripts/build-dev-app.sh`: passed; app bundle rebuilt and ad-hoc signed.
  - Bundle metadata, strict `codesign --verify --strict --deep`, and
    `git diff --check`: passed.
  - XCTest remains blocked by the Command Line Tools-only environment because
    `XCTest` is unavailable.
- Exact next safe step: relaunch the rebuilt app, close the main window with the
  red X, confirm the Dock icon disappears while the menu-bar icon remains, then
  use `Open ColorControl` from the menu bar to restore the window and Dock icon.

### 2026-08-16 — Fix Dock icon remaining after window close

- Objective: correct the activation-policy check after observing that the Dock
  icon still remained when the main window was closed.
- Diagnosis: the first implementation counted the transient `MenuBarExtra`
  window as a regular visible app window. That kept `NSApplication` in
  `.regular` activation policy even though the main window was gone.
- Completed:
  - The close handler now excludes the exact window that emitted
    `NSWindow.willCloseNotification` and only treats the titled `ColorControl`
    main window as a reason to keep the Dock icon.
  - The menu-bar scene remains unaffected; `Open ColorControl` still restores
    `.regular` policy before opening the WindowGroup.
- Verification:
  - Rebuilt and relaunched the development app.
  - Closed the main window through the macOS close button.
  - Queried `NSRunningApplication.activationPolicy`: it changed from `0`
    (`.regular`) to `1` (`.accessory`), confirming the Dock icon is removed
    while the process remains alive.
  - `git diff --check`: passed.
- Exact next safe step: use the menu-bar `Open ColorControl` action once to
  verify the window and Dock icon return to regular mode.

### 2026-08-16 — Remove orphan development credential and persist restrictive file permissions

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: remove the confirmed unreferenced development credential and
  prevent native snapshots from being recreated with group/world-readable
  permissions.
- Completed:
  - Re-read the current and backup snapshots and confirmed the orphan
    credential reference was absent from both; the running ColorControl process
    had no open handle to the credential directory.
  - Deleted the one unreferenced 32-byte development credential file. The
    remaining credential is still owner-only and referenced by the active TV.
  - Changed the app-specific `~/Library/Application Support/ColorControl`
    directory to `0700`, `ColorControl.json` to `0600`, and
    `ColorControl.json.bak` to `0600`. The shared parent `~/Library/Application
    Support` was intentionally not changed because it belongs to other apps.
  - Updated `NativeStore` to re-harden the app directory and existing snapshot
    files on load, and to apply `0700/0600` after directory creation, backup
    copy, and atomic snapshot replacement. Added a permission regression test.
- Files changed: `NativeStore.swift`, `NativeStoreTests.swift`, and this
  handoff. Runtime data was also changed as described above.
- Commands/tests and results:
  - `jq` reference checks, `lsof`, `rm` of the exact confirmed orphan, `chmod`,
    and `stat`: passed; resulting modes are `0700/0600/0600` and only one
    development credential remains.
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swiftc -parse Tests/VibeScreenCoreTests/NativeStoreTests.swift`: passed.
  - `swift test -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: blocked
    because this machine has Command Line Tools only and no `XCTest` module.
  - `git diff --check`: passed.
- Decisions made: permission hardening targets only the app-owned
  `Application Support/ColorControl` directory; no broad or destructive change
  was made to the user's shared Application Support folder.
- Open issues/blockers: the currently running process is an older launched
  binary; restart the app before relying on the new write-path hardening for a
  live save. Full XCTest verification still requires Xcode.
- Exact next safe step: restart the development app, save one harmless setting,
  and re-run `stat` to verify the new binary preserves `0700/0600` after an
  atomic write.

### 2026-08-16 — Runtime resource, temporary-file, and log audit

- Environment: macOS 26.6.1 (25G76), Apple Silicon arm64; Apple Swift 6.3.3;
  Command Line Tools only.
- Objective: inspect the running app's CPU/memory use, sockets, temporary files,
  logs, crash evidence, stale data, and obvious optimization risks. This was a
  read-only audit; no application data or source files were deleted or changed.
- Completed findings:
  - The resident menu-bar process was sleeping with 0.0% CPU, 0.5% `ps` memory,
    83,984 KB RSS, six threads, and 67.0 MiB physical footprint (139.4 MiB
    peak). RSS includes shared frameworks; no idle network socket was open.
  - No ColorControl crash report was present. `leaks` was blocked by macOS
    process-debugging restrictions and reported only 14.8 KB of mostly system
    `NSXPCConnection`/CoreFoundation candidates, which is not evidence of an
    app-owned leak.
  - Runtime data is under `~/Library/Application Support/ColorControl` and is
    only 16 KB: one JSON snapshot plus its intentional `.bak`, and two 32-byte
    development credential files. The credential directory/files are 0700/0600;
    no credential `.tmp` files remain. One credential file is unreferenced by
    the current snapshot and is a possible stale artifact; it was not removed.
  - No app log file or app cache directory was found. Logging uses unified
    `os_log` under subsystem `com.colorcontrol.mac`; current retained stats were
    60 error events / 964 bytes, split between protocol and automation. Several
    entries are repeated TV/network failures, so retry/backoff and error
    de-duplication remain optimization candidates.
  - The only runtime cache observed was a system-managed Metal cache of about
    208 KB. The SwiftPM `.build` directory is 525 MB (developer build output,
    not runtime garbage) and can be cleaned separately when a rebuild is safe.
  - Source inspection confirms there is no always-on polling loop: live TV sync
    sleeps only while the LG controls view is visible and is currently disabled
    in the saved settings; the menu-bar refreshes on appearance/manual actions.
    Native persistence keeps one backup rather than unbounded history.
- Commands/tests and results:
  - `ps`, `top`, `vmmap -summary`, `lsof`, `launchctl`, `find`, `du`, and
    `/usr/bin/log show/stats` completed successfully with the results above.
  - `leaks` completed with the macOS security restriction noted above.
  - No build or XCTest run was needed for this read-only audit; the environment
    remains Command Line Tools-only for XCTest.
- Open issues and decisions:
  - Consider removing the unreferenced 32-byte development credential only after
    confirming the device was intentionally removed.
  - Consider tightening the parent Application Support directory and JSON/.bak
    permissions (currently 0755/0644); they do not contain the secret key today,
    but they expose device metadata and trust settings to other local users.
  - Consider bounded retry/backoff and log de-duplication for repeated offline-TV
    or Local Network failures. No resource leak or unbounded runtime file growth
    was observed in this audit.
- Exact next safe step: if requested, implement the stale-credential cleanup and
  permission hardening with a migration-safe test, then add bounded network retry
  telemetry; otherwise leave the current runtime behavior unchanged.

### 2026-08-16 — Add native public-API System Monitor

- Environment: macOS 26.6.1 (25G76), arm64; Apple Swift 6.3.3; Command Line
  Tools SDK only, with no XCTest module or `xcodebuild`.
- Objective: add a Monitor destination below Devices for the requested CPU,
  GPU, RAM, network, temperature, fan, DC-in, voltage, current, and watt fields,
  plus a persisted sampling-interval setting.
- Completed:
  - Added platform-neutral monitor snapshots and a narrow async sampling
    protocol in VibeScreenCore.
  - Added an actor-isolated macOS sampler using public Mach host statistics for
    aggregate CPU/RAM, BSD `getifaddrs` counters for download/upload rates,
    Foundation thermal pressure, and IOKit power-source dictionaries.
  - Added a persistent Monitor sidebar destination with grouped utilization,
    temperature, network, cooling, and power sections; live technical values
    use monospaced digits and accessible labels/hints.
  - Added a Settings stepper from 500 ms through 60 seconds. The value decodes
    safely from old snapshots, clamps at both limits, persists through the
    existing atomic native store, and restarts the visible sampling task when
    changed.
  - Kept whole-system GPU usage, CPU/GPU/RAM/SSD temperatures, and fan RPM
    visibly unavailable because macOS provides no documented public app API for
    them. No private SMC/IOReport symbols, shell commands, helper, root access,
    entitlement, permission, or external dependency was added.
  - Distinguished IOKit's optional battery voltage/current and calculated
    battery-flow estimate from the external adapter's rated watts; neither is
    labeled as live total-system power.
- Files changed: `SystemMonitorModels.swift`, `MacSystemMonitorSampler.swift`,
  `SystemMonitorView.swift`, `NativeStore.swift`, `AppContainer.swift`,
  `MainWindowView.swift`, `NativeStoreTests.swift`, native README, screen
  inventory, platform map, parity matrix, UI design, limitations, NEXUS, and
  this handoff.
- Commands/tests and results:
  - `swift build`: passed under Swift 6 strict concurrency.
  - `swift build -c release`: passed.
  - `swiftc -parse Tests/VibeScreenCoreTests/NativeStoreTests.swift`: passed.
  - `swift test`: blocked by the existing Command Line Tools-only environment;
    `XCTest` is unavailable. No test-pass claim is made.
  - Launched the debug executable and visually inspected the live Monitor at
    1080×720 in light appearance. CPU, RAM, nominal thermal pressure, and
    network rates updated on the current Mac; unsupported sensor cards were
    explicit and legible. The first RAM formula was corrected after visual QA
    to exclude reclaimable file-backed/purgeable pages.
  - `git diff --check`: passed.
- Open issues/blockers: install/select full Xcode to run XCTest and UI tests;
  verify signed-sandbox operation, Dark Mode/accessibility appearances, battery
  voltage/current and adapter keys on a MacBook, and interface aggregation on
  Wi-Fi plus Ethernet/VPN hardware. Public API limitations for temperatures,
  fan RPM, and global GPU utilization remain intentional.
- Exact next safe step: install/select full Xcode, run the full test suite, then
  exercise Monitor in a signed sandboxed app on a MacBook while switching
  between AC and battery power.

### 2026-08-16 — Rebuild and relaunch Monitor-enabled development app

- Environment: macOS 26.6.1 (25G76), arm64; Apple Swift 6.3.3; Command Line
  Tools SDK and ad-hoc local signing.
- Objective: build the current native source into the local development app
  bundle and launch it for the user.
- Completed: ran `Scripts/build-dev-app.sh`, which rebuilt with the explicit
  `COLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS` flag, refreshed the existing
  `.build/VibeScreen.app` bundle, copied the current Info.plist/icon, and
  replaced its ad-hoc signature. No application data or credential file was
  changed by this session.
- Commands/tests and results:
  - Development Swift build: passed with the new System Monitor sources.
  - `codesign --verify --deep --strict --verbose=2`: passed; the bundle is valid
    on disk and satisfies its designated requirement.
  - Info.plist inspection: bundle ID `com.colorcontrol.mac`, version `0.1.0`
    (`1`), minimum macOS `14.0`, Local Network usage text, and packaged icon are
    present.
  - Launched `.build/VibeScreen.app`; process PID `22952` remained running
    and sleeping at 0.0% CPU after initialization. The on-screen main window
    was present at its 920×690 minimum-size layout.
- Open issues/blockers: this is an ad-hoc development build using the explicitly
  less-secure owner-only credential-file mode. Full Xcode/XCTest, signed sandbox
  packaging, archive, and notarization remain pending.
- Exact next safe step: use the running Monitor screen, then install/select full
  Xcode to run XCTest and validate the signed sandbox build on portable Mac
  power hardware.

### 2026-08-16 — Add left/right 5% LG value-label adjustment

- Environment: macOS 26.6.1 (25G76), arm64; Apple Swift 6.3.3; Command Line
  Tools SDK and ad-hoc local development signing.
- Objective: make percentage values beside LG brightness/picture and volume
  sliders increment 5% on left-click and decrement 5% on right-click in both
  the main app and menu-bar popover.
- Completed:
  - Added a narrow AppKit-backed SwiftUI overlay that distinguishes left,
    right, and Control-click without replacing the native text or slider.
  - Applied the interaction to all menu-bar Game Bar percentage values and only
    `0…100` percentage ranges in the main LG view. Expert signed/non-percentage
    ranges such as `-50…50` remain unchanged.
  - Each accepted click clamps at the range boundary, updates the visible value,
    sends exactly one command through the existing apply path, and performs the
    existing bounded TV read-back. Further clicks are ignored while refresh or
    apply is in progress.
  - Added pointing-hand cursor feedback, hover help, Control-click fallback,
    button semantics, and accessibility hints explaining both directions.
- Files changed: `MouseButtonClickOverlay.swift`, `MenuBarView.swift`,
  `MainWindowView.swift`, `UI_DESIGN_SYSTEM.md`, `FEATURE_PARITY_MATRIX.md`, and
  this handoff.
- Commands/tests and results:
  - `swift build`: passed.
  - `swift build -c release`: passed.
  - `git diff --check`: passed.
  - `Scripts/build-dev-app.sh`: passed with the explicit local development
    credential-file flag.
  - `codesign --verify --deep --strict --verbose=2`: passed.
  - Relaunched `.build/VibeScreen.app`; PID `24355` remained running and
    the main window appeared at 920×690.
- Open issues/blockers: the click path was not exercised automatically against
  the configured TV because that would mutate real brightness/volume state.
  XCTest/UI tests remain unavailable with Command Line Tools only; full Xcode
  is still required for automated click-event coverage.
- Exact next safe step: manually left-click and right-click one visible `%`
  label in the running menu-bar popover and main LG view, confirm one 5% step in
  each direction on the TV, then install/select full Xcode for automated UI
  coverage.

### 2026-08-16 — Audit upstream monitors and complete the public-API Monitor slice

- Environment: macOS 26.6.1 (25G76), arm64; Apple Swift 6.3.3; Command Line
  Tools SDK and ad-hoc local development signing.
- Objective: inspect the two upstream projects requested by the product owner,
  expand the Monitor surface where documented macOS APIs provide reliable data,
  and replace the sampling stepper with a pulldown.
- Upstream evidence:
  - [Macs Fan Control](https://github.com/crystalidea/macs-fan-control) is an
    SMC-oriented fan-control product; its published UI strings require a helper
    for fan control and distinguish monitoring-only operation.
  - [Stats](https://github.com/exelban/stats) advertises CPU/GPU/memory/disk/
    network/battery/sensor/fan features, but its source opens `AppleSMC` through
    IOKit and ships a privileged SMC helper. Those are hardware/private paths,
    not a documented public app API, so they were not copied into ColorControl.
- Completed:
  - Added processor count, active processor count, system uptime, startup-volume
    total capacity, and startup-volume available capacity to the monitor
    snapshot and sampler using `ProcessInfo` and `URLResourceValues`.
  - Added System Monitor UI tiles for CPU topology, uptime, startup-volume use,
    and SSD SMART health/total system power as explicit unavailable states.
    Added a visible public-API notice so users understand why SMC-only values
    (temperatures, fan RPM/control, GPU load, SMART health, live total watts)
    are not fabricated.
  - Replaced Settings → System Monitor → Sampling interval `Stepper` with a
    `.menu` `Picker` offering 0.5, 1, 2, 5, 10, 30, and 60 seconds. Existing
    persisted values are mapped to the nearest menu value and all changes still
    use the clamped atomic native settings path.
  - Updated the platform map, parity matrix, and known-limitations report with
    the upstream audit and the public/private API boundary.
- Files changed: `SystemMonitorModels.swift`, `MacSystemMonitorSampler.swift`,
  `SystemMonitorView.swift`, `MainWindowView.swift`,
  `migration/docs/PLATFORM_API_MAP.md`, `migration/docs/KNOWN_LIMITATIONS.md`,
  `migration/docs/FEATURE_PARITY_MATRIX.md`, and this handoff.
- Commands/tests and results:
  - `swift build`: passed.
  - `swift build -c release`: passed.
  - `Scripts/build-dev-app.sh`: passed with the explicit local development
    credential-file flag.
  - `codesign --verify --deep --strict --verbose=2 .build/VibeScreen.app`:
    passed; the ad-hoc development bundle is valid on disk.
  - `git diff --check`: passed.
  - Replaced the previous development process and relaunched the current app;
    PID `25609` remained running after initialization.
  - `swift test` remains unavailable because this machine has Command Line
    Tools only and no XCTest module; no XCTest pass claim is made.
- Open issues/blockers: SMC-backed fan control/readings, temperatures, SMART
  health, whole-system GPU usage, disk I/O throughput, CPU frequency, and live
  total-system watts remain blocked by the documented public-API constraint.
  Full Xcode/XCTest, signed sandbox, and portable Mac hardware evidence remain
  pending.
- Exact next safe step: install/select full Xcode, run XCTest/UI tests, then
  exercise the public power and network fields on a signed MacBook build while
  switching AC/battery and Wi-Fi/Ethernet/VPN interfaces.

### 2026-08-17 — Runtime handoff check

- Confirmed the rebuilt ad-hoc development app is still running as PID `25609`
  after the environment date rollover. A full-screen `screencapture` attempt
  returned a black image in this session, so no new visual-QA claim is made;
  the earlier live Monitor inspection remains the available visual evidence.
- Exact next safe step: use the running app's Monitor and Settings screens for
  manual pulldown verification, then repeat UI checks on a Screen Recording-
  authorized user session or full Xcode UI-test environment.

### 2026-08-17 — Make menu-bar Open ColorControl single-window

- Environment: macOS 26.6.1 (25G76), arm64; Apple Swift 6.3.3; Command Line
  Tools SDK and ad-hoc local development signing.
- Objective: repeated clicks on the menu-bar `Open ColorControl` action must
  never create multiple main app windows.
- Completed:
  - Replaced the main SwiftUI `WindowGroup("ColorControl", id: "main")` with
    a single-instance `Window("ColorControl", id: "main")` scene.
  - Added an AppKit focus path that finds the existing non-panel ColorControl
    window, restores it when minimized, activates the app, and brings it to the
    front. The menu-bar action only calls `openWindow(id: "main")` when no main
    window exists.
  - Kept the menu-bar Settings/quit behavior unchanged.
- Files changed: `VibeScreenApp.swift`, `MenuBarView.swift`, and this
  handoff.
- Commands/tests and results:
  - `swift build`: passed.
  - `swift build -c release`: passed.
  - `Scripts/build-dev-app.sh`: passed.
  - `codesign --verify --deep --strict --verbose=2 .build/VibeScreen.app`:
    passed.
  - `git diff --check`: passed.
  - Relaunched the development app; PID `4922` remained running.
- Open issues/blockers: automated AppKit click repetition and full UI tests
  still require XCTest/full Xcode; manual menu-bar click verification remains
  recommended on the user's desktop session.
- Exact next safe step: click `Open ColorControl` repeatedly in the menu-bar
  popover and confirm one ColorControl window is reused and focused.

### 2026-08-17 — Clean rebuild and export development app

- Environment: macOS 26.6.1 (25G76), arm64; Apple Swift 6.3.3; Command Line
  Tools SDK and ad-hoc local development signing.
- Objective: stop old ColorControl processes, remove generated build output,
  rebuild the unchanged current source with file-based development credentials,
  and place a shareable app bundle in Documents.
- Completed:
  - Confirmed no old ColorControl process was running before the clean build.
  - Ran `swift package clean`, rebuilt with `Scripts/build-dev-app.sh` (which
    preserves `COLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`), and copied the
    resulting app to `$HOME/Documents/VibeScreen.app`; created
    `$HOME/Documents/VibeScreen.zip` with `ditto` for sharing.
  - Verified the exported app bundle has the expected `com.colorcontrol.mac`
    identifier, version `0.1.0`, macOS 14 minimum, executable, and packaged icon.
  - Verified the exported bundle's ad-hoc signature, then removed the generated
    repository `.build` directory and confirmed no ColorControl process remains.
  - No Swift source or credential-storage code was changed in this session.
- Files changed: this handoff only; generated build output was removed and the
  share bundle was created outside the repository.
- Commands/tests and results:
  - `swift package clean`: passed.
  - `Scripts/build-dev-app.sh`: passed.
  - `ditto .build/VibeScreen.app $HOME/Documents/VibeScreen.app`:
    passed.
  - `codesign --verify --deep --strict --verbose=2 $HOME/Documents/VibeScreen.app`:
    passed.
  - `git diff --check`: not rerun after this documentation-only append; prior
    source/build session passed it.
- Decisions made: the exported bundle intentionally remains a local development
  build and stores TV credentials as owner-only files in Application Support,
  matching the user's request. This is less secure than the production
  Keychain path and should not be uploaded with any credential files.
- Open issues/blockers: the app is not running after cleanup, as requested;
  full Xcode archive/notarization remains separate from this share build.
- Exact next safe step: share `$HOME/Documents/VibeScreen.zip`
  (or the `.app` bundle); launch it by double-clicking or with `open` when
  needed.

### 2026-08-17 — Add Monitor sidebar visibility and sampling cancellation

- Environment: macOS 26.6.1 (25G76), arm64; Apple Swift 6.3.3; Command Line
  Tools SDK and ad-hoc local development signing.
- Objective: let users hide the Monitor destination from Settings and stop all
  Monitor sampling when the destination is hidden.
- Completed:
  - Added `showSystemMonitorInSidebar` to `NativeAppSettings`, including a
    backward-compatible `true` decode default and persisted Codable storage.
  - Added a Settings toggle named `Show Monitor in sidebar` and a container
    persistence method.
  - Main navigation now removes the Monitor row when disabled and redirects an
    active Monitor selection to Devices when the toggle changes.
  - Replaced the view-owned sampling loop with an explicit cancellable task in
    `SystemMonitorViewModel`. It starts only on Monitor appearance, restarts on
    sampling-interval changes, and is cancelled on disappearance/deinitialization.
    This prevents a hidden Monitor from retaining a live polling task.
  - Added native settings round-trip/default coverage for the new visibility
    flag.
- Files changed: `NativeStore.swift`, `AppContainer.swift`,
  `MainWindowView.swift`, `SystemMonitorView.swift`,
  `NativeStoreTests.swift`, and this handoff.
- Commands/tests and results:
  - `swift build`: passed.
  - `swift build -c release`: passed.
  - `swiftc -parse Tests/VibeScreenCoreTests/NativeStoreTests.swift`: passed.
  - `git diff --check`: passed.
  - `Scripts/build-dev-app.sh`: passed; the ad-hoc bundle was rebuilt and
    re-signed.
  - `codesign --verify --deep --strict --verbose=2 .build/VibeScreen.app`:
    passed.
  - Relaunched the current development app; PID `4251` remained running after
    initialization.
  - `swift test`: not run because this Command Line Tools environment lacks
    XCTest; the limitation is unchanged.
- Open issues/blockers: full XCTest/UI lifecycle coverage still requires Xcode;
  the current app build remains an ad-hoc local development bundle.
- Exact next safe step: run debug/release builds, parse/test checks available on
  this machine, rebuild and relaunch the app, then manually verify the toggle
  hides Monitor and that reopening it resumes sampling.

### 2026-08-22 — Combine Settings TV keyboard shortcut controls

- Environment: macOS 26.6.1, arm64, Swift 6.3.3, Command Line Tools SDK and
  ad-hoc local development signing.
- Objective: replace the two visible Settings shortcut buttons with one
  combined control while preserving separate first-TV power-on and power-off
  bindings.
- Completed:
  - Replaced the two Settings recorder rows with one native button that shows
    both current shortcut chords and records power-on, then power-off, in one
    sequential interaction. Escape cancels the operation.
  - Added atomic pair replacement in `AppContainer`; duplicate or occupied
    bindings restore the previous working pair and keep the error visible.
  - Updated the shortcut copy, screen inventory, UI design system, parity
    matrix/checklist, NEXUS, and this handoff to describe the single-button
    interaction.
- Files changed: `MainWindowView.swift`, `AppContainer.swift`, UI/design/parity
  documentation, and this handoff. `legacy-windows/` remained read-only.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release`: passed.
  - `Scripts/build-dev-app.sh`: passed; the development bundle was rebuilt and
    ad-hoc signed.
  - `codesign --verify --deep --strict --verbose=2 .build/VibeScreen.app`:
    passed.
  - `git diff --check`: passed.
  - `swift test -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: blocked
    before execution because the Command Line Tools installation has no
    `XCTest` module; no XCTest pass claim is made.
  - Full-screen screenshot capture produced a black image because the current
    shell lacks Screen Recording permission; no screenshot visual-pass claim
    is made.
- Decisions made: keep two underlying global Carbon bindings because on/off
  are distinct actions, but expose them through one user-facing recorder to
  reduce Settings clutter and preserve atomic validation.
- Open issues/blockers: manual keyboard-only/VoiceOver interaction and
  appearance QA still require a permission-authorized user session or full
  Xcode UI-test environment.
- Exact next safe step: open Settings in the rebuilt app, click the combined
  button, record both chords without invoking TV power, and verify Escape plus
  duplicate/conflict rollback behavior.

### 2026-08-22 — Make the TV shortcut a real power toggle

- Environment: macOS 26.6.1, arm64, Swift 6.3.3, Command Line Tools SDK and
  ad-hoc local development signing.
- Objective: keep exactly one global shortcut. For example, `Control-O` reads
  the first TV's current state; on turns it off, and off/standby turns it on.
- Completed:
  - Replaced the two persisted settings and two Carbon registrations with one
    `tvPowerToggleShortcut`, defaulting to `Control-O`.
  - Added backward-compatible decoding for snapshots containing the old
    `tvPowerOnShortcut` and `tvPowerOffShortcut` pair; the old default pair
    migrates to `Control-O` and a customized pair keeps its former power-on
    binding as the single toggle until edited.
  - Added LG webOS and Samsung Tizen live power-state reads and bounded state
    parsers. The toggle sends PowerOff only after confirming the TV is on; when
    the TV is off, enters standby, or stops answering state queries, it uses
    only the safe PowerOn/Wake-on-LAN path.
  - Kept power-on routed through the existing Wake-on-LAN path and power-off
    through the existing TV command path.
  - Replaced the Settings recorder with one shortcut recorder and updated the
    parity/design documentation to describe the actual toggle behavior.
- Files changed: `NativeStore.swift`, `TVProtocolModels.swift`,
  `TVPowerCoordinator.swift`, `TVDeviceClients.swift`, `MacGlobalTVShortcutManager.swift`,
  `AppContainer.swift`, `MainWindowView.swift`, `NativeStoreTests.swift`,
  `ProtocolAndWakeTests.swift`, and the related migration documentation.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release`: passed.
  - `swiftc -parse` for the two changed test files: passed.
  - `Scripts/build-dev-app.sh`: passed; the development bundle was rebuilt and
    ad-hoc signed.
  - `codesign --verify --deep --strict --verbose=2 .build/VibeScreen.app`:
    passed.
  - `git diff --check`: passed.
  - `swift test -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: blocked
    before execution because this Command Line Tools installation has no
    `XCTest` module.
- Open issues/blockers: the two directions still need a real-TV verification;
  LG/Samsung state endpoints and WOL behavior cannot be confirmed without a
  paired TV and network access. Full Xcode XCTest/UI verification remains
  unavailable on this machine.
- Exact next safe step: with a paired TV, press the one Settings shortcut once
  while the TV is off and once while it is on; verify the first press powers on
  and the second powers off, without sharing the TV address or credentials.

### 2026-08-22 — Rebuild app bundle in Documents

- Rebuilt the development app with `Scripts/build-dev-app.sh` and replaced
  `$HOME/Documents/VibeScreen.app` with the current bundle.
- `codesign --verify --deep --strict --verbose=2` passed for the Documents copy.
- The SHA-256 hash of the executable matches the freshly built executable in
  `.build/VibeScreen.app`.
- Exact next safe step: open `$HOME/Documents/VibeScreen.app`
  and test the one TV power-toggle shortcut with a paired TV.

### 2026-08-22 — Recover power-on after TV standby

- Environment: macOS 26.6.1, arm64, Swift 6.3.3, Command Line Tools SDK and
  ad-hoc local development signing.
- Objective: fix the second shortcut press after the first press powered the TV
  off.
- Root cause: the first power-off can put the TV into standby before its live
  state endpoint answers again, and the previous toggle path stopped at the
  failed state read without attempting PowerOn.
- Completed:
  - Added a query to the power-policy coordinator for the app's manual-off
    latch. The next toggle uses Wake-on-LAN immediately when that latch is set.
  - Changed unknown/error state recovery to attempt only safe PowerOn/WOL; the
    app still never sends PowerOff unless the TV reports `.on`.
  - Updated Settings copy, parity/limitation/design documentation, and added
    coordinator coverage for the manual-off query.
  - Rebuilt and replaced `$HOME/Documents/VibeScreen.app`.
- Files changed: `TVPowerCoordinator.swift`, `AppContainer.swift`,
  `TVProtocolModels.swift`, `MainWindowView.swift`,
  `TVPowerCoordinatorTests.swift`, related parity/limitation/design docs, and
  this handoff.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release`: passed.
  - `swiftc -parse Tests/VibeScreenCoreTests/TVPowerCoordinatorTests.swift`:
    passed.
  - `Scripts/build-dev-app.sh`: passed.
  - `codesign --verify --deep --strict --verbose=2` on the Documents app:
    passed.
  - Documents executable SHA-256 matches `.build/VibeScreen.app`.
  - `swift test -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: blocked
    before execution because this Command Line Tools installation has no
    `XCTest` module.
- Open issues/blockers: the exact LG/Samsung standby response and WOL wake
  behavior still need confirmation on the user's paired TV; the fallback is
  intentionally conservative and never sends PowerOff from an unknown state.
- Exact next safe step: launch the replaced Documents app and press the single
  shortcut twice with the TV on, then repeat starting with the TV off. Confirm
  the second press sends Wake-on-LAN and wakes the TV.

### 2026-08-28 — Start login launches in the menu bar only

- Environment: macOS 26.6.2 (25G83), arm64, Swift 6.3.3, Command Line Tools
  SDK and ad-hoc local development signing.
- Objective: when macOS launches ColorControl at login, keep the process and
  menu-bar item active without opening the main application window.
- Completed:
  - `ColorControlApplicationDelegate` now inspects the public
    `keyAELaunchedAsLogInItem` parameter on the current `kAEOpenApplication`
    Apple Event.
  - Login-item launches use `NSApplication.ActivationPolicy.accessory`, avoid
    foreground activation, and hide the SwiftUI main window both immediately
    and if it becomes main after the delegate callback.
  - Manual Finder/Dock launches retain the regular activation policy and normal
    window. The existing menu-bar `Open ColorControl` action clears startup
    suppression and focuses the existing window.
  - Settings now labels the option `Launch at login (menu bar only)` and
    persists `startHidden` together with `launchAtLogin`.
  - Updated platform API, parity, limitation, and NEXUS documentation using the
    installed SDK declaration and Apple documentation for
    `keyAELaunchedAsLogInItem` and `SMAppService.mainApp`.
  - Rebuilt and replaced `$HOME/Documents/VibeScreen.app`.
- Files changed: `VibeScreenApp.swift`, `AppContainer.swift`,
  `MainWindowView.swift`, platform/parity/limitation/NEXUS documentation, and
  this handoff.
- Commands/tests and results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release`: passed.
  - `Scripts/build-dev-app.sh`: passed.
  - `codesign --verify --deep --strict --verbose=2` on the Documents app:
    passed.
  - Documents executable SHA-256 matches `.build/VibeScreen.app`.
  - `git diff --check`: passed before this handoff append.
  - `swift test -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: blocked
    before execution because this Command Line Tools installation has no
    `XCTest` module.
- Decisions made: use the system-provided login-launch Apple Event marker, not
  command-line guesses or an extra LaunchAgent. No new entitlement or optional
  permission is required.
- Open issues/blockers: a true logout/login cycle is required to verify that
  `SMAppService.mainApp` supplies the marker and that no SwiftUI window flash is
  visible on this Mac. Full XCTest/UI automation remains blocked without Xcode.
- Exact next safe step: enable `Launch at login (menu bar only)`, quit the app,
  log out and back in, verify only the menu-bar icon appears, then use
  `Open ColorControl` to confirm the main window remains available on demand.

### 2026-08-28 — Diagnose display wake after quitting

- Environment: macOS 26.6.2 (25G83), arm64, Swift 6.3.3, Command Line Tools
  SDK.
- Objective: determine whether ColorControl or a background helper continues
  waking the display/TV after the user quits the app.
- Evidence:
  - No `VibeScreen` process was present in `ps`/`pgrep` during the
    reported post-Quit state.
  - No ColorControl job was present in the current GUI `launchctl` domain, and
    no ColorControl LaunchAgent or LaunchDaemon file exists in the user/system
    launch directories.
  - The packaged app contains only its main executable, Info.plist, icon, and
    code signature; it contains no helper service executable.
  - `pmset -g assertions` reported both `PreventUserIdleDisplaySleep = 0` and
    `PreventSystemSleep = 0` with no ColorControl assertion owner.
  - The latest relevant power log at `2026-08-28 17:09:11 +0700` records
    `DarkWake to FullWake ... due to HID Activity`, followed by `Display is
    turned on`. This is macOS reacting to mouse/input activity, not a
    ColorControl request.
  - The saved TV policy has both `powerOffOnScreenSaver` and
    `powerOnAfterScreenSaver` enabled. If only the main window is closed, the
    menu-bar process intentionally remains alive and maps
    `NSWorkspace.screensDidWakeNotification` to PowerOn/WOL. A true menu-bar
    Quit calls `NSApplication.terminate` and the process exits.
- Source finding: `AppContainer.stopPlatformEvents()` exists but is not
  explicitly called from `applicationWillTerminate`. Process exit still
  destroys observers/tasks/sockets, so this omission cannot leave a service
  running after the process is gone; it remains a graceful-cleanup quality gap.
- Files changed: this handoff only; no runtime behavior was changed during the
  diagnosis.
- Commands/results: `ps`, `pgrep`, `launchctl`, launch-directory inspection,
  bundle-content inspection, redacted native policy inspection, `log show`,
  and `pmset -g assertions/-g log` completed successfully.
- Exact next safe step: distinguish close from Quit in a manual check. After
  choosing menu-bar Quit, confirm the menu-bar icon disappears and
  `VibeScreen` is absent in Activity Monitor; then move the mouse. If the
  TV still wakes, inspect TV HDMI-CEC/Quick Start/input-signal behavior because
  ColorControl is no longer able to issue a command.

### 2026-08-28 — Stop TV wake automation before Quit

- Environment: macOS 26.6.2 (25G83), arm64, Swift 6.3.3, Command Line Tools
  SDK.
- Objective: close the graceful-shutdown race after confirming that this LG TV
  requires an IP/WOL request to power on and cannot be explained by HDMI signal
  detection alone.
- Implementation:
  - Added an idempotent `AppContainer.prepareForTermination()` gate that marks
    termination first, stops `MacPlatformEventSource`, cancels its consumer
    task, and unregisters the global TV shortcut.
  - The platform event loop now rejects startup/restart while terminating and
    checks cancellation/termination before handling each signal and after each
    awaited coordinator operation. A queued screen-wake event therefore cannot
    continue into later automation once Quit begins.
  - Both the menu-bar Quit button and the standard Command-Q app command run
    the same cleanup path before `NSApplication.terminate`.
  - `applicationWillTerminate` invokes the same idempotent cleanup as a fallback
    for system/Dock termination paths.
- Files changed: `App/AppContainer.swift`, `App/VibeScreenApp.swift`,
  `Features/MenuBarView.swift`, feature/function parity documentation, and this
  handoff.
- Commands/results:
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release`: passed.
  - `Scripts/build-dev-app.sh`: passed; the rebuilt bundle replaced
    `$HOME/Documents/VibeScreen.app`.
  - `codesign --verify --deep --strict --verbose=2` on the Documents app:
    passed, and its executable SHA-256 matches the packaged source bundle.
  - `git diff --check`: passed after the implementation and documentation
    updates.
  - `swift test -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: blocked
    before test execution because the Command Line Tools installation has no
    `XCTest` module.
- Remaining verification: real LG hardware is required to prove that after
  menu-bar Quit/Command-Q, mouse movement no longer causes this app to send
  WOL. Closing only the main window intentionally leaves menu-bar automation
  running.
- Exact next safe step: install and launch the rebuilt Documents app, power the
  TV off, choose Quit from the menu-bar popover (or press Command-Q while the
  main app is active), confirm its menu-bar icon disappears, then move the
  mouse and verify that the TV remains off.

### 2026-08-31 — Prevent no-input screen wake from sending WOL

- Environment: macOS 26.6.2 (25G83), arm64, Swift 6.3.3, Command Line Tools
  SDK and ad-hoc development signing.
- Objective: diagnose and stop an LG TV powering back on roughly 5–10 minutes
  after shortcut or automatic power-off when the user did not intentionally
  move the mouse or press a key; persist enough evidence to identify any future
  trigger conclusively.
- Root-cause evidence:
  - The saved first-LG policy has `powerOffOnScreenSaver=true`,
    `powerOnAfterScreenSaver=true`, `powerOnAfterManualPowerOff=false`, and all
    startup/resume/session power-on flags disabled.
  - `NSWorkspace.screensDidWakeNotification` provides only the screen-wake fact
    and no cause, but the app previously mapped every occurrence directly to
    PowerOn/WOL and the screensaver-stop preset trigger.
  - `pmset -g log` contains repeated no-deliberate-input display wake cycles in
    the reported interval: for example, display off at 16:09:17 and on at
    16:10:43, off at 16:15:12 and on at 16:20:41, and off at 16:34:27 and on at
    16:40:08 on 2026-08-31. macOS attributes these full wakes to
    Bluetooth/HID activity following DarkWake/maintenance activity.
  - Existing OSLog output said only `Automatic TV power action failed` and did
    not include the platform signal, policy decision, command, origin, or WOL
    send evidence, so it could not prove which path caused an observed TV wake.
- Completed:
  - Added `ScreenWakeUserIntentPolicy` and changed `MacPlatformEventSource` to
    wait one second after a screen-wake notification, then forward it only when
    `CGEventSource.secondsSinceLastEventType` reports current-session input no
    older than five seconds. No-input wake notifications are suppressed before
    both TV policy and preset automation.
  - Added cancellation ownership for pending wake-validation and diagnostic
    tasks; a new screen-sleep event cancels stale pending wake validation.
  - Added the injected `PowerDiagnosticRecording` boundary and
    `MacPowerDiagnosticRecorder`. It writes owner-only JSONL to
    `~/Library/Application Support/ColorControl/Diagnostics/PowerDiagnostics.jsonl`,
    rotates at 1 MB, and retains one previous file.
  - Diagnostics cover raw platform signals, screen-wake input age and
    forwarded/suppressed decision, policy flags/manual-off latch/actions,
    manual/shortcut command origin and result, preset-router WOL eligibility,
    and each actual UDP WOL attempt/result. TV names, IP/host/MAC values,
    credentials, payloads, and raw network errors are omitted.
  - Added deterministic boundary coverage for recent, stale, and non-finite
    input ages. Updated platform, security, limitations, parity, and function
    documentation.
  - Rebuilt and replaced `$HOME/Documents/VibeScreen.app` without
    launching it; no ColorControl process was running during packaging.
- Files changed: core power diagnostics and policy/coordinator/router sources;
  macOS platform event, WOL, recorder, and app-container sources;
  `PlatformEventsTests.swift`; platform/security/limitations/parity documents;
  and this handoff. `legacy-windows/` remained read-only.
- Commands/tests and results:
  - Existing unified ColorControl logs, redacted native policy, and `pmset`
    power/display history were inspected successfully.
  - `CGEventSource.secondsSinceLastEventType` returned a current-session idle
    age without Accessibility/Input Monitoring permission; no entitlement or
    permission change was added.
  - `swift build -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: passed.
  - `swift build -c release`: passed.
  - `swiftc -parse Tests/VibeScreenCoreTests/PlatformEventsTests.swift`:
    passed.
  - `swift test -Xswiftc -DCOLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS`: blocked
    before test execution because this Command Line Tools installation has no
    `XCTest` module.
  - `Scripts/build-dev-app.sh`: passed.
  - Documents app strict code-sign verification passed; its executable SHA-256
    matches the packaged source bundle.
  - `git diff --check`: passed before this handoff append.
- Decisions made: screen wake is a platform fact, not sufficient proof of user
  intent. Favor preventing an unsolicited TV wake; users whose wake method does
  not generate a CoreGraphics input event can still use the global TV toggle.
  Keep diagnostics local, bounded, owner-only, and redacted rather than adding
  telemetry or logging TV network identity.
- Open issues/blockers: the five-second threshold and mouse/keyboard ordering
  need real-session verification. XCTest remains unavailable without full
  Xcode. A future in-app Reveal/Export Diagnostics action is still pending.
- Exact next safe step: launch the replaced Documents app, turn the TV off by
  shortcut and by screen-sleep automation, leave input devices untouched for
  at least 15 minutes, and verify the TV remains off. If it wakes, preserve
  `PowerDiagnostics.jsonl` and its previous file before another 1 MB rotation;
  the presence or absence of `wol.send.started` at that timestamp identifies
  whether ColorControl sent the wake packet.

### 2026-09-02 — Launch at login Settings state completion

- Environment: macOS 26.6.2, arm64, Swift 6.3.3, Command Line Tools SDK; full
  Xcode and XCTest remain unavailable.
- Objective: expose a reliable “Launch at login” option in app Settings.
- Completed:
  - Kept the existing standard Settings toggle and `SMAppService.mainApp`
    registration path, with login launches opening in menu-bar-only mode.
  - Expanded `LoginItemManager` to distinguish disabled, enabled,
    approval-required, and unavailable states.
  - Added approval guidance and an “Open Login Items” action backed by
    `SMAppService.openSystemSettingsLoginItems()`.
  - Refreshes the authoritative system state whenever Settings loads or the app
    becomes active again, and persists any external approval/revocation change.
  - Avoids duplicate register/unregister calls for an already matching state.
- Files changed: `LoginItemManager.swift`, `MainWindowView.swift`, platform API
  map, feature parity matrix, UI design system, and this handoff. Existing
  unrelated working-tree changes were preserved; `legacy-windows/` remained
  read-only.
- Commands/tests and results:
  - `swift build`: passed.
  - `swift test`: blocked before execution because the Command Line Tools
    installation has no `XCTest` module.
  - Apple `SMAppService`, status, registration, system Login Items, and
    `keyAELaunchedAsLogInItem` documentation reviewed.
- Decisions made: the toggle represents a registered intent, including the
  approval-required state, so the user can still disable a pending Login Item.
  System Settings remains authoritative and the app does not use a LaunchAgent
  or private API.
- Open issues/blockers: real enable, approval, revocation, logout/login, and
  no-window-flash UI smoke tests require a packaged signed app and user-session
  testing. Visual inspection and automated UI/XCTest evidence remain pending.
- Exact next safe step: package the app, enable the toggle, approve it in System
  Settings if requested, log out/in, and confirm ColorControl starts only in the
  menu bar; then revoke approval and verify Settings reflects the change after
  app activation.

### 2026-09-16 — Diagnose LG connection failure after macOS 27 update

- Environment: macOS 27.0 (26A428), arm64; ad-hoc development app; Command
  Line Tools SDK without full Xcode.
- Objective: diagnose the reported loss of LG TV control immediately after the
  operating-system update without changing TV, credential, or privacy state.
- Evidence:
  - The configured LG remains reachable from this Mac by ICMP and its selected
    WebSocket port accepts a TCP connection. The saved host, MAC, credential
    reference, owner-only development credential file, secure-connection flag,
    and pinned certificate remain present; no secret or network address was
    printed or recorded.
  - The running `$HOME/Documents/VibeScreen.app` is the older
    development bundle last modified on 2026-08-17. Its bundle identifier and
    `NSLocalNetworkUsageDescription` are present, but the bundle is ad-hoc
    signed, has no Apple Team ID, and its effective code signature contains no
    entitlements.
  - Terminal connectivity does not prove the app has Local Network privilege:
    Apple's TN3179 documents that Terminal-launched command-line tools are
    automatically allowed, while GUI apps are privacy-gated. TN3179 also says
    reliable macOS local-network identity tracking requires an Apple-issued
    signing identity and recommends `URLSession.waitsForConnectivity` or retry
    handling while permission is unresolved. The current ephemeral WebSocket
    session does not enable `waitsForConnectivity`.
  - Apple developer reports include Local Network privacy regressions across
    macOS updates and unstable behavior for multiple/ad-hoc app identities.
- Commands/tests and results:
  - `sw_vers`: macOS 27.0 build 26A428.
  - `nc` against the redacted configured LG endpoint: selected WebSocket port
    reachable; one bounded ICMP probe also succeeded.
  - `codesign --verify --deep --strict`: passed for the installed app;
    `codesign -dv`: `Signature=adhoc`, `TeamIdentifier=not set`.
  - Read-only persistence inspection: schema-v2 store and `0600` development
    credential/diagnostic files remain intact.
  - A fresh debug build against the macOS 27 Command Line Tools SDK failed
    because `SwiftUIMacros.StateMacro` is missing and the CLT framework search
    path is absent. This is an incomplete/incompatible toolchain issue, not an
    LG protocol failure; Release did not run after Debug failed.
- Files changed: this handoff only. `legacy-windows/` remained read-only; no
  device, credential, permission, or installed-app state was changed.
- Diagnosis: the strongest current cause is Local Network privacy losing or
  misidentifying the ad-hoc app after the OS update. A TV/network outage is
  ruled out. TLS/client-key failure is less likely because both artifacts are
  intact, but an in-app error or signed-build handshake is still required to
  distinguish it conclusively.
- Open issues/blockers: the Local Network pane is user-private UI state and was
  not altered; no app-level sanitized WebSocket error is currently persisted.
  Full Xcode/current matching toolchain and an Apple Development-signed bundle
  are needed for the durable fix and verification.
- Exact next safe step: in System Settings > Privacy & Security > Local
  Network, enable ColorControl, fully quit and reopen it, then use Reconnect. If
  it still fails, build/install one Apple Development-signed bundle with a
  stable identity, enable `waitsForConnectivity`, and add a redacted connection
  diagnostic before repeating the non-destructive Pair/Test flow.

### 2026-09-29 — Diagnose menu-bar startup and stale LG automation actions

- Environment: macOS 27.0 (26A428), arm64, Xcode 27.0 (27A266a), Swift 6.4.
- Objective: identify why normal app launches show the main window and why LG
  automation may continue after its settings are disabled.
- Completed:
  - Read the required migration handoff, master prompt, decisions, and native
    README, plus applicable UI, core, LG protocol, and debugging guidance.
  - Traced app launch: `ColorControlApplicationDelegate` suppresses the window
    only when the macOS Login Item marker is present; other launches set regular
    activation policy and activate the app.
  - Traced LG policy update and event execution: the coordinator retains the
    event's original controller/actions across awaits; controller replacement
    does not invalidate a pending delay, so a stale action can resume with the
    old policy.
  - Confirmed Xcode 27.0 and Swift 6.4 are now selected. No build or tests were
    run.
- Files changed: this handoff only. Pre-existing modified/untracked workspace
  files were left untouched; `legacy-windows/` remains read-only.
- Commands/tests and results: `git status --short`, targeted `rg`/`sed` source
  inspection, `sw_vers`, `swift --version`, `xcode-select -p`, and
  `xcodebuild -version` completed. No test or build command ran.
- Decisions made: proposed behavior is menu-bar-only on every initial launch;
  show the main window only through the menu-bar Open action. Invalidate
  in-flight per-device power actions whenever the device policy/controller is
  replaced, checking around configured delays and before sending commands.
- Open issues/blockers: the wording “bắt hết” is assumed to mean all automation
  toggles were turned off; confirm this assumption before implementation.
  Bounded design approval is pending.
- Exact next safe step: after design approval, implement the two scoped fixes
  and update this handoff with build evidence and remaining limitations.

### 2026-09-29 — Start menu-bar-only and cancel stale LG power actions

- Environment: macOS 27.0 (26A428), arm64, Xcode 27.0 (27A266a), Swift 6.4.
- Objective: apply the approved launch behavior and stop LG power automation
  work that belongs to a replaced/disabled device policy; rebuild and replace
  the app bundle at its current Documents path.
- Completed:
  - All initial launches now use accessory activation and hide the main window;
    the menu-bar Open action switches to regular activation and opens/focuses
    the single main window.
  - `TVPowerPolicyCoordinator` now owns per-device action tasks, cancels them
    when the corresponding policy/controller is invalidated or removed, and
    checks registration validity around delays and TV/WOL commands.
  - Policy replacement invalidates the old registration before disconnecting
    the controller. Cancelled automation is reported as cancelled instead of
    completed.
  - Rebuilt using `macOS/VibeScreen/Scripts/build-dev-app.sh` and replaced
    `$HOME/Documents/VibeScreen.app`. Strict code-sign verification
    passed; installed and built executables have the same SHA-256:
    `8f677619828591cd4f53ab7a56ac3025e88369e6c355558aa975962055b8bebe`.
    The replaced bundle was retained at
`$HOME/Documents/.VibeScreen-replace-windowscene-20260929/VibeScreen.previous.app`.
- Files changed: `VibeScreenApp.swift`, `TVPowerCoordinator.swift`,
  `AppContainer.swift`, `migration/PROGRESS.md`, `migration/docs/NEXUS.md`,
  `migration/docs/BUILD_RELEASE.md`, `migration/docs/FEATURE_PARITY_MATRIX.md`,
  and `migration/docs/FUNCTION_PARITY_CHECKLIST.md`. Existing unrelated
  workspace changes remain untouched; `legacy-windows/` remains read-only.
- Commands/tests and results:
  - `./Scripts/build-dev-app.sh` from `macOS/VibeScreen`: passed with the
    selected Xcode 27.0 / Swift 6.4 toolchain.
  - The replacement command's EXIT trap returned non-zero because it assigned
    to zsh's read-only `status` variable after moving the new bundle into place;
    independent post-command checks confirmed the installed bundle is valid,
    has bundle ID `com.colorcontrol.mac`, and byte-matches the build executable.
    The original bundle remains available at the recovery path above.
  - `git diff --check`: passed after final documentation updates.
  - `codesign --verify --deep --strict --verbose=2` passed for both the staged
    and installed app bundles; bundle identifier is `com.colorcontrol.mac`.
  - Installed executable SHA-256 matches `.build/VibeScreen.app`.
  - No test suite or TV command was run. The app was not launched, so window
    visibility and real-TV cancellation still need manual verification.
- Decisions made: use the existing local development build path and preserve
  its explicit owner-only file-credential mode and ad-hoc signature. Only the
  app bundle at the established Documents path was replaced; the pre-existing
  ZIP was not rebuilt.
- Open issues/blockers: no UI smoke or real LG automation-delay check was run.
  Xcode archive/distribution signing and XCTest remain unverified.
- Exact next safe step: manually launch the Documents app and verify menu-bar-only
  startup plus explicit menu-bar Open behavior; perform LG delay-cancellation
  hardware checks only when those automatic TV actions are intended.

### 2026-09-29 — Open the same menu-bar popover on right-click

- Environment: macOS 27.0 (26A428), arm64, Xcode 27.0 (27A266a), Swift 6.4.
- Objective: make a secondary click on the menu-bar icon open the existing
  quick-control popover, retain the previously requested menu-only startup,
  and replace the installed app bundle after rebuilding.
- Root cause: the SwiftUI `MenuBarExtra` window-style status item handled its
  primary click but exposed no supported secondary-click route. Apple's
  `NSControl.sendAction(on:)` only recognizes primary mouse events; stable
  `NSClickGestureRecognizer.buttonMask` supports the secondary button.
- Completed:
  - Replaced the menu-bar scene with a public AppKit `NSStatusItem` and transient
    `NSPopover` hosting the existing `MenuBarView`; both primary and secondary
    clicks toggle the same content.
  - The existing Open action focuses the SwiftUI `Window` scene or uses its
    registered `OpenWindowAction` after that scene has closed. App startup
    remains accessory-only with the main window hidden.
  - Quit and application termination retain the existing cleanup handler; the
    status item removes its gesture recognizer and popover during termination.
  - Built with `macOS/VibeScreen/Scripts/build-dev-app.sh`, then gracefully
    quit the older running app and replaced
    `$HOME/Documents/VibeScreen.app`.
  - Strict signature verification passed for staged and installed bundles;
    installed bundle ID is `com.colorcontrol.mac`; installed and built
    executables byte-match with SHA-256
    `277030adacf69acfa07dd7dc482631d8b480ac4576168a0d84ecbc1618949ace`.
    The replaced bundle is retained at
    `$HOME/Documents/.VibeScreen-replace-windowscene-20260929/VibeScreen.previous.app`.
- Files changed: `VibeScreenApp.swift`, `MenuBarView.swift`, new
  `MenuBarStatusItemController.swift`, `README.md`, `UI_DESIGN_SYSTEM.md`,
  `PLATFORM_API_MAP.md`, `ARCHITECTURE.md`, `NEXUS.md`, `STATUS.md`,
  `FEATURE_PARITY_MATRIX.md`, `FUNCTION_PARITY_CHECKLIST.md`, the menu-bar row in
  the UI screen inventory, and this handoff. Unrelated worktree changes remain
  untouched; `legacy-windows/` remains read-only.
- Commands/tests and results:
  - `./Scripts/build-dev-app.sh` from `macOS/VibeScreen`: passed with the
    selected Xcode 27.0 / Swift 6.4 toolchain.
  - `codesign --verify --deep --strict --verbose=2` passed for staged and
    installed app bundles; `plutil` confirmed bundle ID and `cmp` confirmed the
    installed executable matches the build output.
  - The prior PID 1085 app was sent a normal Apple-event Quit before replacement
    and was no longer running before the bundle move.
  - No tests were added or run. The new installed app was not launched for
    mouse/UI or real-TV verification.
- Decisions: use a stable AppKit secondary-click recognizer rather than the
  macOS 27 beta expanded-interface API. Preserve the existing menu content and
  use the local development build/signing path. The existing ZIP was not rebuilt.
- Open issues: actual left/right mouse interaction, popover geometry and
  VoiceOver behavior still need a UI smoke check. XCTest, archive signing,
  notarization, and hardware checks remain unverified.
- Exact next safe step: launch the installed app, verify startup shows only the
  status item, verify either click opens the same popover, and verify Open,
  close/reopen, and Quit. Avoid TV slider actions unless intended.

### 2026-09-30 — Keep the menu-bar app alive without a window

- Environment: macOS 27.0 (26A428), arm64, Xcode 27.0 (27A266a), Swift 6.4.
- Objective: investigate why the installed app appeared not to run, repair the
  startup lifecycle, rebuild and replace the existing app, then smoke-check the
  requested menu-bar-only and click-to-open behavior.
- Root cause: before the fix, Launch Services accepted the open request but the
  executable exited cleanly with status 0. LLDB stopped in
  `-[NSApplication terminate:]`; the call stack came from AppKit's scheduled
  check after its last window was hidden. The manual `NSStatusItem` did not
  prevent AppKit's default last-window termination after removing `MenuBarExtra`.
- Completed:
  - Implemented `applicationShouldTerminateAfterLastWindowClosed(_:) -> Bool`
    in `ColorControlApplicationDelegate`, returning `false` so the persistent
    menu-bar status item can outlive hidden or closed window scenes.
  - Rebuilt with `./Scripts/build-dev-app.sh` and replaced
    `$HOME/Documents/VibeScreen.app`. The previous installed app
    is retained at
    `$HOME/Documents/.VibeScreen-replace-launchfix-20260930/VibeScreen.previous.app`.
  - Confirmed the new process stays running with zero app windows after
    startup and again after closing the main window.
  - Confirmed left- and right-click open/toggle the same popover; the `Open
    ColorControl` button opens the main window. Closed the window after the
    smoke check, leaving the app in menu-bar-only mode.
  - Checked saved TV automation state before launch: device automation triggers
    are disabled and there are no startup presets, so startup did not issue TV
    commands.
- Files changed: `VibeScreenApp.swift`, this progress handoff,
  `migration/docs/BUILD_RELEASE.md`, `migration/docs/NEXUS.md`, and
  `migration/docs/FEATURE_PARITY_MATRIX.md`. Existing unrelated worktree changes
  remain untouched; `legacy-windows/` remains read-only.
- Commands/checks and results:
  - `./Scripts/build-dev-app.sh`: passed with Xcode 27.0 / Swift 6.4.
  - `open -n -a $HOME/Documents/VibeScreen.app`: exit 0;
    `pgrep -x VibeScreen` confirmed the process remained live. Later check
    showed PID 6773 running for over 17 minutes, with zero visible app windows.
  - `codesign --verify --deep --strict` passed; bundle ID is
    `com.colorcontrol.mac`; installed and built executables match, SHA-256
    `42246960921a3f30b60820837237c1adc6662ff2d637892268a33b668b316b2b`.
  - `git diff --check` passed for the changed source and handoff documents.
  - Runtime UI smoke used Accessibility and synthetic pointer events for left,
    right, Open, and close behavior. No XCTest suite or TV setting action was
    run. `spctl` rejects this local ad-hoc-signed development app; it is not a
    Developer ID-signed or notarized release artifact.
- Decision: keep the accessory app alive explicitly through the documented
  application-delegate termination policy; retain the existing status item and
  SwiftUI main-window flow.
- Open issues: XCTest, Developer ID signing/notarization, TV hardware commands,
  and power-automation sleep/wake behavior remain unverified. The existing
  `VibeScreen.zip` was not rebuilt.
- Exact next safe step: continue the opt-in LG pairing and pointer-remote
  hardware checks; do not run power automation unless those TV actions are
  intended.

### 2026-09-30 — Dismiss the menu-bar popover when focus leaves ColorControl

- Environment: macOS 27.0 (26A428), arm64, Xcode 27.0 (27A266a), Swift 6.4.
- Objective: fix the menu-bar popover remaining visible after the user switches
  to another app, rebuild the development app, and replace the installed bundle.
- Reproduction: with the old build's popover open, switching to Chrome left the
  popover visible. Accessibility still exposed its `Open ColorControl` button.
  The accessory app was inactive while its popover was visible, so AppKit's
  transient behavior did not dismiss it for this focus change.
- Completed:
  - Added an `NSWorkspace.didActivateApplicationNotification` observer while
    the popover is shown. It ignores ColorControl's own process and closes the
    popover when another app activates. The observer is removed when the
    popover closes or the status item is torn down.
  - Rebuilt using `./Scripts/build-dev-app.sh` and replaced
    `$HOME/Documents/VibeScreen.app`. The previous installed
    bundle is retained at
    `$HOME/Documents/.VibeScreen-replace-autodismiss-20260930/VibeScreen.previous.app`.
  - Launched the replacement; process 9918 remained running. Strict
    `codesign --verify --deep --strict` passed and the installed executable
    SHA-256 is
    `c09b4a62bc4e0f639f704b2d7df1e87e8dc1f3a082c6c133d19ed62c542d3778`.
- Files changed for this issue: `Features/MenuBarStatusItemController.swift`,
  this handoff, `migration/docs/NEXUS.md`,
  `migration/docs/BUILD_RELEASE.md`, and
  `migration/docs/FEATURE_PARITY_MATRIX.md`. Other existing worktree changes
  were left untouched; `legacy-windows/` remains read-only.
- Commands/checks and results:
  - `./Scripts/build-dev-app.sh`: passed with Xcode 27.0 / Swift 6.4.
  - `codesign --verify --deep --strict --verbose=2
    $HOME/Documents/VibeScreen.app`: passed.
  - `pgrep -fl VibeScreen`: confirmed the replacement process is live;
    installed executable SHA-256 recorded above.
  - `git diff --check`: passed. No tests were added or run.
  - Updated-build focus-out UI verification is pending: an unrelated
    Gatekeeper alert for `VibeShotUITests-Runner` was present and blocked safe
    accessibility interaction. The old-build focus-out reproduction is
    confirmed; no claim is made that the updated UI interaction was manually
    verified.
- Decision: use the public workspace app-activation notification and keep the
  observer active only while the popover is open; no global input monitoring
  was added.
- Open issues: verify left- and right-click popover auto-dismiss after another
  app activates, once the unrelated Gatekeeper alert is no longer blocking UI.
  XCTest, distribution signing/notarization, TV hardware commands, and
  power-automation behavior remain unverified.
- Exact next safe step: with the updated app running and no blocking system
  dialog, open the popover with each mouse button, activate another app, and
  confirm the popover closes without a second click. Avoid TV slider actions.
## 2026-10-10 — Prepare public GitHub source publication

- Refreshed the root README with the product workflow, implemented features, source-build steps, and development-preview limitations.
- Added ignore rules for local metadata, build outputs, generated SARIF reports, signing material, environment files, and private configuration.
- Ran Gitleaks against the Git candidate file snapshot and reviewed findings; no actual credentials were identified.
- Checked README relative links and image references. Application behavior was not changed and app build/test suites were not run for this documentation/publication task.
- Git commits use the account's GitHub noreply address.

- Restored upstream GPL/third-party notices at the repository root and added attribution. Retained Windows source was not modified.
- Created a verified local Git bundle backup and rebuilt the initial commit without the generated SARIF report or the prior company author email. Personal home-directory paths in native/migration documentation now use `$HOME`.
- Public-repository handling must keep old cached commits private unless the owner explicitly accepts their exposure.
- Exact next safe step: publish the reviewed `main` branch using the owner-approved GitHub repository handling, then verify remote commit IDs and visibility.

### 2026-10-10 — Isolate the original private repository before publication

- The owner approved retaining the original GitHub repository as a private backup and creating a fresh public VibeScreen repository from sanitized `main`.
- A force push removed the generated SARIF report and company author email from reachable history, but GitHub still served the old commit by SHA. The original repository must remain private to prevent exposing that cache.
- The fresh public repository receives only the sanitized initial commit and reviewed native-source/documentation commits. The public origin URL remains `https://github.com/hiepkhach1005/VibeScreen.git`.
- Publication verification checks repository visibility/identity, remote `main` and README hashes, clean worktree, absence of SARIF from branch history, and noreply author metadata. App build/test suites are not part of this repository-management follow-up.
- Exact next development step: continue the previously recorded opt-in LG pairing and pointer-remote hardware checks; avoid power automation unless those TV actions are intended.

## 2026-10-20 — Menu-bar popover focus fix (macOS 27.0, Xcode 27.0)

- Problem: popover opened while app inactive, so controls rendered dimmed and needed an extra click; outside clicks did not dismiss it.
- Change: `MenuBarStatusItemController.swift` now calls `NSApp.activate()` and makes the popover window key before/after showing, and installs a global mouse-down monitor (removed on close/teardown) that closes the popover on clicks in other apps.
- Verification: `swift build` succeeded. Runtime behavior not yet confirmed by user.
- Next safe step: user confirms first-click interactivity and outside-click dismissal in the dev app bundle.

## 2026-10-20 — Rename to VibeScreen + shared Vibe icon family (macOS 27.0, Xcode 27.0)

- Native project moved `macOS/ColorControlMac` → `macOS/VibeScreen`; targets/modules renamed to `VibeScreen`, `VibeScreenCore`, `VibeScreenCoreTests`; bundle id `com.vibescreen.mac`; UI strings, logger subsystem, compile flag `VIBESCREEN_DEVELOPMENT_FILE_CREDENTIALS` renamed. Doc/skill path references updated (legacy-windows untouched).
- Intentionally kept old identity: LG signed pairing manifest (`com.colorcontrol.app`, app/vendor names), Samsung client name, and Keychain service `com.colorcontrol.mac`, so existing pairings and Keychain items stay valid.
- `NativeStore.makeDefault()` now moves `Application Support/ColorControl` → `VibeScreen` once and renames `ColorControl.json(.bak)`; verified on this Mac (credentials, diagnostics, snapshot moved).
- New icon from `Scripts/render-app-icon.swift` (shared renderer for VibeScreen/VibeShot/MacPad); iconset and `VibeScreenIcon.icns` regenerated.
- Verification: `swift build` OK; `Scripts/build-dev-app.sh` OK; app launched. `swift test` fails to compile on a pre-existing invalid raw string in `LegacyPresetImporterTests.swift:6` (unchanged by this work).
- Next safe step: fix the pre-existing test literal, then run `swift test`.

## 2026-10-20 — Rename VibeMonitor → VibeScreen; repository ScreenPilot → VibeScreen

- Project now at `macOS/VibeScreen` (targets `VibeScreen`, `VibeScreenCore`, `VibeScreenCoreTests`, bundle id `com.vibescreen.mac`, flag `VIBESCREEN_DEVELOPMENT_FILE_CREDENTIALS`). All non-legacy `ScreenPilot` references renamed to `VibeScreen`; local folder and GitHub repository renamed to `VibeScreen`.
- `NativeStore.makeDefault()` migrates `Application Support/VibeMonitor` or `ColorControl` into `VibeScreen` once; verified on this Mac. TV pairing identity and Keychain service still use the ColorControl values on purpose.
- Verification: `Scripts/build-dev-app.sh` OK, app launched (pid observed). `swift test` still blocked by the pre-existing invalid raw string in `LegacyPresetImporterTests.swift`.
- Next safe step: fix that test literal and run `swift test`.
