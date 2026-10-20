# Master prompt: rewrite ColorControl as a native macOS application

Use this prompt from the repository root. Treat every requirement below as project instructions.

---

## Role and objective

You are the lead macOS engineer, software architect, migration engineer, test engineer, and native UI designer responsible for rewriting ColorControl as a production-quality macOS application.

The original Windows application is located at `legacy-windows/`. It is the behavioral source of truth and must remain read-only. All native application code must be written under `macOS/VibeScreen/`.

Rewrite the application with:

- Swift 6 or newer;
- SwiftUI as the primary UI framework;
- AppKit only when SwiftUI does not expose the required native capability;
- a full native app window;
- a macOS menu bar experience using `MenuBarExtra`, with `NSStatusItem` only when advanced AppKit behavior is required;
- the current stable macOS design language and Liquid Glass;
- documented public Apple APIs only.

Do not use .NET, C#, Blazor, WebView, Electron, Tauri, MAUI, Avalonia, or a local web server in the macOS product.

Do not migrate NVIDIA or AMD functionality. Remove GPU-specific models, conditions, commands, startup flags, navigation, and dependencies from the new domain.

Preserve all applicable non-GPU behavior: LG WebOS, Samsung Tizen, Wake-on-LAN, device discovery and pairing, remotes, presets and steps, automation, global shortcuts, sleep/wake/session/screensaver/display/process triggers, game launching, display management, color profiles, settings, logging, startup, migration, and updates.

## Mandatory continuity workflow

Before any action, read:

1. `AGENTS.md`
2. `migration/PROGRESS.md`
3. `migration/DECISIONS.md`
4. this file

Continue from the exact stopping point in `migration/PROGRESS.md`. Do not repeat completed work without evidence that it is invalid.

After every meaningful session, append to `migration/PROGRESS.md`:

- work completed;
- files changed;
- commands and tests run with results;
- decisions and limitations;
- open issues;
- exact next safe step;
- date and environment.

## Non-negotiable rules

1. Never silently drop a legacy feature.
2. Every feature must be traced from legacy source to requirement, macOS mapping, implementation, and tests.
3. Every feature must use one status: `Not audited`, `Mapped`, `Implemented`, `Tested`, `Accepted`, `Not applicable`, or `Blocked`.
4. `Not applicable` is valid for NVIDIA, AMD, web-host infrastructure, and genuinely Windows-only behavior with a documented explanation.
5. When public macOS APIs cannot provide parity, cite Apple documentation, implement the closest safe behavior, and record the limitation. Never use private APIs to fake parity.
6. Do not modify, format, rename, or delete `legacy-windows/`.
7. Do not execute real shutdown, sleep, TV power-off, factory-menu, or other destructive actions in automated tests or on first launch.
8. Do not claim macOS build/runtime validation from a Windows environment.
9. Never put LG client keys, Samsung tokens, credentials, private addresses, or personal data in source, fixtures, screenshots, or logs.
10. Do not claim completion while any accepted-scope feature remains unaudited or lacks evidence.

## Environment and repository inspection

Before coding:

- confirm repository root;
- inspect existing `AGENTS.md` files and repository skills;
- use `rg --files` for source inventory;
- inspect working-tree state and preserve user changes;
- on macOS, record macOS, Xcode, Swift, SDK, architecture, and deployment-target availability;
- on Windows, limit work to analysis, documentation, migration fixtures, and portable scaffolding;
- record the result in `migration/PROGRESS.md`.

## Mandatory legacy source reading

All source paths below are relative to `legacy-windows/`. Read complete files. If output is truncated, continue to EOF. Resolve globs to actual file lists and record audited paths in the legacy source map.

### Build, lifecycle, and composition

- `README.md`
- `ColorControl.slnx`
- `ColorControl/ColorControl.csproj`
- `ColorControl.UI/ColorControl.UI.csproj`
- `Shared/Shared.csproj`
- `LittleCms/LittleCms.csproj`
- `MHC2Gen/MHC2Gen.csproj`
- `ColorControl/Program.cs`
- `ColorControl/MainWorker.cs`
- `ColorControl/MainForm.cs`
- `ColorControl/Services/Common/ServiceManager.cs`
- `ColorControl/Services/Common/NotifyIconManager.cs`
- `ColorControl/Services/Common/OptionsService.cs`
- `ColorControl/Services/Common/UpdateManager.cs`
- `ColorControl/Services/Common/LoggingService.cs`
- `ColorControl/Services/Common/ElevationService.cs`
- `Shared/Contracts/StartUpParams.cs`
- `Shared/Contracts/Module.cs`
- `Shared/Contracts/Config.cs`

Map launch, dependency setup, service initialization, tray behavior, notification registration, hotkeys, startup actions, shutdown, and background behavior.

### Presets, steps, triggers, and dispatchers

- `ColorControl/Services/Common/ServiceBase.cs`
- `ColorControl/Services/Common/IServiceBase.cs`
- `Shared/Contracts/Presets/PresetBase.cs`
- `Shared/Contracts/PresetStep.cs`
- related contracts under `Shared/Contracts/`
- all files under `Shared/EventDispatcher/`

Map startup, resume, sleep, shutdown, lock/unlock, screensaver, display sleep/wake/change, process events, fullscreen conditions, delays, retries, ordering, quick access, shortcuts, event presets, and trigger conditions.

Remove GPU-specific conditions from the new domain rather than leaving dead types.

### Windows integrations to replace, not translate line by line

- `Shared/Native/WinApi.cs`
- `Shared/Native/CCD.cs`
- `Shared/Native/DXWrapper.cs`
- `Shared/Services/WinApiService.cs`
- `Shared/Services/WinApiAdminService.cs`
- `Shared/Services/WinElevatedProcessManager.cs`
- `Shared/Services/RpcClientService.cs`
- `Shared/Services/RpcServerService.cs`
- `Shared/Common/PipeUtils.cs`

Find every call site involving Win32 messages, Windows Services, WMI, registry, named pipes, Task Scheduler, elevation, power broadcasts, session notifications, display configuration, HDR, DDC/CI, global hotkeys, and screensaver detection.

### LG WebOS

- all files under `ColorControl/Services/LG/`
- all files under `ColorControl/LgTv/`
- LG remote-control classes used by those services
- `ColorControl/Resources/LG_register.json`
- `ColorControl/Resources/LG_register_legacy.json`
- `ColorControl/Resources/LgRemotes.json`
- `ColorControl/LgPresets.json` when present

Audit discovery, manual setup, IP/MAC data, pairing, client key, secure and legacy WebSockets, connection state, reconnection, subscriptions, WOL, power, screen state, volume, channels, media, apps, inputs, remote keys, mouse service, system/picture settings, game bar, presets, triggers, delays, retries, and custom remotes.

### Samsung Tizen

- all files under `ColorControl/Services/Samsung/`
- `ColorControl/Resources/SamsungRemotes.json`
- `ColorControl/SamsungPresets.json` when present

Audit secure and non-secure WebSockets, pairing token, persistence, trust behavior, reconnection, WOL, power detection, keys and key delays, apps, screen state, service/hospitality/factory actions, presets, triggers, and custom remotes. Do not carry over blanket TLS validation bypasses.

### Game launcher

- all files under `ColorControl/Services/GameLauncher/`
- all files under `Shared/Contracts/Game/`
- every class called by the game service

Audit external-process detection, path/name matching, auto activation, pre/post/finalization steps, executable, arguments, working directory, delay, lifecycle, priority, affinity, elevation, suspend, restart, and cleanup.

Map `.exe` behavior to `.app`, bundle identifiers, and Mach-O executables using `NSWorkspace`, `Process`, and public process APIs. Document unsupported Windows elevation, affinity, suspension, or priority behavior.

### Displays and color profiles

- `ColorControl/Services/Common/GraphicsService.cs`
- `ColorControl/Services/Common/ColorProfileService.cs`
- all relevant files under `MHC2Gen/`
- all relevant files under `LittleCms/`
- related display/profile contracts under `Shared/Contracts/`

Audit display identity and enumeration, reconfiguration, resolution, refresh rate, rotation, scaling, HDR, brightness, DDC/CI, ICC profile listing, install/uninstall, display association, default profile, generation/editing, primaries, white point, SDR/HDR luminance, gamma, gains, tone mapping, MHC2, and LittleCMS.

Prioritize CoreGraphics, ColorSync, and public IOKit APIs. Never reuse `lcms2.dll`; if LittleCMS remains necessary, integrate a native macOS C target/package and validate each supported architecture.

### WOL and discovery

- `Shared/Services/WolService.cs`
- relevant discovery/network helpers in `Shared/Common/Utils.cs`
- every WMI, ARP, routing, or network-interface call site

Preserve UDP magic packets. Replace Windows discovery with Network.framework, Bonjour/mDNS, SSDP/UPnP where appropriate, and always support manual IP/MAC setup.

### Legacy UI as feature inventory

Read these even though none of the web UI will be reused:

- `ColorControl.UI/Components/Layout/**`
- LG, Samsung, Game, ColorProfile, RemoteControl, and Generic pages under `ColorControl.UI/Components/Pages/`
- `ColorControl.UI/Components/Pages/Options.razor`
- `ColorControl.UI/Components/Pages/Logging.razor`
- `ColorControl.UI/Components/Pages/Info.razor`
- LG, Samsung, Game, Options, Color Profile, and remote-control WinForms panels, including Designer/resource files when needed to inventory fields and actions

Use UI source only to discover behavior and information architecture. Do not port Razor, HTML, CSS, WinForms, or WPF.

### Legacy persistence

Find schemas and call sites for:

- `Settings.json`
- `LgConfig.json`
- `LgPresets.json`
- `LgRemotes.json`
- `<ip>_ClientKey.txt`
- `SamsungConfig.json`
- `SamsungPresets.json`
- `SamsungRemotes.json`
- Samsung pairing tokens
- `GameConfig.json`
- `GamePresets.json`
- backup files, logs, profile metadata, and all other runtime-generated configuration

The importer must accept a user-selected legacy folder and never assume a Windows path exists on macOS.

### GPU exclusion audit

Do not read or port NVIDIA/AMD implementations except where needed to identify cross-module coupling. Use `rg` across non-GPU source for `NVIDIA`, `AMD`, `NvPreset`, `AmdPreset`, `Gsync`, GPU-specific steps, flags, navigation, and contracts. Record and remove those dependencies from the new architecture.

## Phase 0 deliverables before application code

Create under `migration/docs/`:

- `NEXUS.md`
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

Create ADRs under `migration/docs/adr/` for native Swift, architecture, menu-bar lifecycle, background/login behavior, persistence/Keychain, network protocols, ColorSync/display control, and update/signing/notarization.

`NEXUS.md` is the compact central index. It must link all documents, show the current phase, architecture version, required reading order, module map, parity summary, build/test state, blockers, unresolved decisions, and next safe task. Do not duplicate entire documents inside it.

The feature matrix columns must be:

| Feature ID | Module | Legacy behavior | Legacy source/symbol | macOS mapping | Target source | Tests | Status | Notes/limitations |

The source map columns must be:

| Legacy path | Legacy type/symbol | Responsibility | New module/path | Semantic differences | Audit status |

## Repository skills

If the `skill-creator` skill is available, use it to scaffold and validate these repository skills under `.agents/skills/`. Otherwise create the same valid structure manually:

1. `map-legacy-colorcontrol`
   - source inventory, call flows, hidden UI/config behavior, source map, and parity matrix;
   - references: `source-manifest.md`, `behavior-checklist.md`.
2. `build-colorcontrol-core`
   - native domain models, dependency boundaries, preset/automation execution, cancellation, error policy, and game-launch workflows;
   - references: `architecture-rules.md`, `automation-engine.md`, `game-launcher.md`.
3. `build-macos-liquid-glass-ui`
   - native SwiftUI/AppKit, menu bar, Liquid Glass, accessibility, and visual QA;
   - references: `design-system.md`, `screen-inventory.md`, `visual-qa-checklist.md`.
4. `port-tv-protocols`
   - LG/Samsung WebSocket state machines, pairing, secrets, WOL, discovery, fixtures, retry, timeout, and cancellation;
   - references: `lg-webos-map.md`, `samsung-tizen-map.md`, `protocol-test-matrix.md`.
5. `implement-macos-platform-services`
   - NSWorkspace, IOKit, CoreGraphics, ColorSync, global shortcuts, process monitoring, Login Items, LaunchAgents, and permissions;
   - references: `apple-api-map.md`, `permission-matrix.md`.
6. `migrate-colorcontrol-data`
   - legacy JSON schemas, dry run, backup, atomic and idempotent migration, Keychain, and golden fixtures;
   - references: `legacy-schema-map.md`, `migration-checklist.md`.
7. `enforce-swift-quality`
   - Swift strict concurrency, build/test/lint gates, dependencies, security, performance, and release checks;
   - references: `quality-gates.md`, `release-checklist.md`.
8. `verify-feature-parity`
   - source-to-test traceability and prevention of silent feature loss;
   - reference: `parity-audit-checklist.md`.

Each skill needs `SKILL.md` and `agents/openai.yaml`. Keep `SKILL.md` concise and put detailed inventories in `references/`.

## Target architecture

Create the native project under `macOS/VibeScreen/` with clear layers resembling:

- `VibeScreen/App/`
- `VibeScreen/Domain/Models/`
- `VibeScreen/Domain/Protocols/`
- `VibeScreen/Domain/UseCases/`
- `VibeScreen/Features/MenuBar/`
- `VibeScreen/Features/Devices/`
- `VibeScreen/Features/Presets/`
- `VibeScreen/Features/Automation/`
- `VibeScreen/Features/GameLauncher/`
- `VibeScreen/Features/ColorProfiles/`
- `VibeScreen/Features/Settings/`
- `VibeScreen/Features/Logs/`
- `VibeScreen/Infrastructure/LGWebOS/`
- `VibeScreen/Infrastructure/SamsungTizen/`
- `VibeScreen/Infrastructure/Discovery/`
- `VibeScreen/Infrastructure/WakeOnLAN/`
- `VibeScreen/Infrastructure/Persistence/`
- `VibeScreen/Infrastructure/Keychain/`
- `VibeScreen/Infrastructure/Logging/`
- `VibeScreen/Infrastructure/Updates/`
- `VibeScreen/Platform/macOS/Power/`
- `VibeScreen/Platform/macOS/Displays/`
- `VibeScreen/Platform/macOS/ColorSync/`
- `VibeScreen/Platform/macOS/GlobalHotkeys/`
- `VibeScreen/Platform/macOS/ProcessMonitoring/`
- `VibeScreen/Platform/macOS/LoginItem/`
- `VibeScreen/Platform/macOS/Permissions/`
- `VibeScreen/Resources/`
- `VibeScreenTests/`
- `VibeScreenUITests/`
- `TestFixtures/`

Adjust this only through a documented ADR.

Use protocol-oriented boundaries and explicit dependency injection. Domain code must not depend on SwiftUI or AppKit. UI state belongs on `@MainActor`; network, persistence, and mutable device state should be actor-isolated where appropriate. Use structured concurrency, `Sendable`, cancellation, bounded retries, and timeouts. Do not create mutable global singletons, service locators, God views/services, unmanaged detached tasks, or main-thread network/disk work.

## Initial Windows-to-macOS API map

Verify every API against the installed stable SDK and official Apple documentation:

| Legacy behavior | Preferred macOS direction |
|---|---|
| Tray icon | SwiftUI `MenuBarExtra`, fallback `NSStatusItem` |
| Windows Service | user-session app, `SMAppService` Login Item, or justified LaunchAgent |
| Power broadcasts | IOKit power notifications and NSWorkspace notifications |
| Lock/unlock/session | public NSWorkspace session notifications |
| Screensaver | verified public/distributed notifications |
| Display changes/modes | CoreGraphics callbacks and display APIs |
| ICC profiles | ColorSync |
| Global hotkeys | supported shortcut API or CoreGraphics event tap with explicit permission |
| WMI discovery | Network.framework, Bonjour/mDNS, SSDP/UPnP, and manual configuration |
| Registry/config | Codable versioned data in Application Support |
| Credential files | Keychain |
| NLog/Event Log | OSLog plus native viewer/export |
| Task Scheduler startup | `SMAppService` |
| Named-pipe admin service | in-process design or justified XPC/helper |
| Process launch | `NSWorkspace`, `Process`, and public process APIs |
| Windows updater | signed/notarized update flow; evaluate Sparkle or release-based updates |

Do not reproduce Windows Service architecture mechanically. Prefer a user-session menu bar app and Login Item. Add LaunchAgent, XPC, or a privileged helper only when evidence proves it necessary; privileged behavior requires an ADR, threat model, and user approval.

## Required product behavior

### Native shell and menu bar

- Native main window and settings.
- Menu bar status, quick presets, device state, safe quick actions, open main window, settings, logs, update/about, and quit.
- Start at login.
- Optional Dock-icon behavior if compatible with lifecycle.
- Clear loading, offline, pairing, permission, and error states.

### LG WebOS and Samsung Tizen

Preserve all audited non-GPU device behavior: multiple devices, discovery/manual setup, pairing, Keychain credentials, secure reconnection, WOL, power/screen control, remotes, apps, inputs/channels/media/volume where supported, custom remotes, service actions with warnings, presets, steps, and event automation.

Networking must use explicit state machines, cancellation, bounded exponential backoff, timeout, cleanup, and redacted structured logs. Do not disable TLS verification globally.

### Presets and automation

Preserve CRUD, clone, rename, reorder, quick access, global shortcut, ordered steps, per-step delay, retry/error policy, and applicable startup/wake/sleep/session/screensaver/display/process triggers. Cross-service steps may combine LG, Samsung, game, system/display, and profile actions. Remove GPU-only triggers.

### Power and lifecycle

Using public APIs where possible, support startup, wake/resume, preparing for sleep, lock/unlock, screensaver start/stop, display sleep/wake/change, process launch/termination, manual sleep, display sleep, shutdown/restart where permitted, and prevent-sleep assertions. Destructive operations require explicit user intent and must be disabled in tests/previews.

### Game launcher

Support `.app`, bundle identifiers, Mach-O executables, arguments, working directory, external app detection, auto activation, pre/post/finalization steps, delay, timeout, lifecycle, and cleanup. Document unsupported Windows elevation, affinity, suspend, and priority behavior rather than using hacks.

### Displays and color profiles

Implement the maximum safe public-API support for display enumeration, metadata, mode and reconfiguration, ICC listing/install/uninstall/association/default selection, and profile generation/editing. Explicitly classify hardware-dependent HDR, brightness, DDC/CI, MHC2, and other controls as verified, test-only, hardware-dependent, or unavailable.

### Settings, logs, updates, and actions

- Native settings and permission diagnostics.
- OSLog with filtering/export and secret redaction.
- Signed/notarized update strategy.
- Legacy import with preview.
- Evaluate URL schemes, App Intents/Shortcuts, and an optional CLI helper for LG, Samsung, and game presets.
- Remove all NVIDIA/AMD command-line flags.

## Persistence and migration

Use macOS conventions: Application Support for durable data, Caches for cache, Unified Logging for logs, and Keychain for pairing secrets.

The importer must be versioned, previewable, backed up, atomic, idempotent, and non-destructive. Preserve preset order, delays, triggers, device association, and custom remotes. Move LG client keys and Samsung tokens to Keychain and never write them to new JSON. Handle malformed, partial, duplicate, unknown-field, and future-version data without crashing. Create redacted golden fixtures and rollback tests.

## Native UI and Liquid Glass rules

Before UI implementation, create the screen inventory, information architecture, design tokens, and wireframes for menu bar, dashboard, device details, LG/Samsung remotes, presets, automation, game launcher, color profiles, settings, logs, and migration.

Use standard system components so the current macOS appearance is inherited naturally. Apply glass selectively to the menu bar popover, toolbar, floating quick controls, and status/action surfaces. Keep settings, forms, logs, and data-heavy screens calm, opaque enough, and legible. Do not simulate Liquid Glass with indiscriminate blur.

Use SF Symbols, system typography, semantic colors, centralized design tokens, correct destructive roles, keyboard navigation, focus rings, VoiceOver labels, and support for light/dark mode, Reduce Transparency, Reduce Motion, Increase Contrast, and relevant text scaling. Do not reuse the Windows `.ico` as the macOS AppIcon.

Define one product-specific visual signature, such as a device/display state ribbon or live connection topology strip, rather than generic decorative gradients.

Perform visual QA in light and dark mode, menu bar, small and normal windows, accessibility text sizes, and reduced-transparency/high-contrast settings.

## Coding and security rules

- Enable Swift 6 strict concurrency.
- Avoid force unwraps; never use production `try!`.
- Do not swallow actionable errors with `try?`.
- Use typed errors and actionable user messages.
- Every network operation needs timeout and cancellation.
- Retries must be bounded; no infinite loops.
- Clean up tasks, subscriptions, sockets, and callbacks.
- Prevent retain cycles and main-thread blocking.
- Use versioned schemas and atomic persistence.
- Prefer Apple frameworks and Swift Package Manager.
- Justify every dependency in an ADR.
- Use public APIs only; no signing bypass or fragile shell command as core behavior.
- Request Local Network, Accessibility, Input Monitoring, or Automation permissions only when a feature needs them.
- The app must remain usable when optional permissions are denied.
- Treat imported data as untrusted input.
- Do not collect telemetry by default.
- Keep accepted features free of placeholder behavior and unresolved TODOs.

## Tests and quality gates

Create unit tests for preset/trigger logic, ordering, delay, cancellation, retry, LG/Samsung encoding and state machines, WOL packets, persistence, Keychain abstractions, migration, game-launch planning, display/profile domain logic, and power automation with fake event sources.

Create redacted protocol fixtures covering malformed data, unknown fields, timeout, disconnect, duplicates, out-of-order responses, cancellation, reconnect, rejected pairing, and invalidated credentials.

Create migration golden tests for empty, valid, partial, malformed, duplicate, already-migrated, repeated, rollback, and future-schema cases.

Create UI smoke tests for app launch, menu bar, main window, navigation, presets, settings, import preview, destructive confirmations, keyboard navigation, and accessibility identifiers. Never require a real TV or real system shutdown in CI.

Real-device integration tests must be opt-in, secret-free, and excluded from default CI. TV power-off and factory/service actions require an explicit manual flag.

On a Mac, verify Debug and Release builds, unit tests, UI smoke tests, concurrency diagnostics, archive creation, signing, notarization documentation, and each declared architecture. If SwiftFormat or SwiftLint is adopted, document and run it consistently.

## Implementation phases

1. **Phase 0 — Audit and project intelligence:** source inventory, NEXUS, requirements, maps, parity matrix, API research, ADRs, roadmap, and repository skills.
2. **Phase 1 — Native shell:** Xcode project, lifecycle, menu bar, main window, navigation, settings skeleton, logging, dependency composition, and build commands.
3. **Phase 2 — Persistence/migration foundation:** versioned storage, Keychain, legacy parser, dry run, backup, fixtures, and tests.
4. **Phase 3 — LG vertical slice:** one device from pairing through a command, WOL, menu bar action, preset, and tests; then full LG parity.
5. **Phase 4 — Samsung vertical slice:** the equivalent end-to-end Samsung path, then full Samsung parity.
6. **Phase 5 — Preset and automation engine:** triggers, steps, lifecycle event sources, shortcuts, cancellation, and error policy.
7. **Phase 6 — Game launcher:** native app selection, launch, monitoring, steps, cleanup, and documented limitations.
8. **Phase 7 — Display and color profiles:** CoreGraphics, ColorSync, optional native LittleCMS/MHC2, and hardware validation.
9. **Phase 8 — UI refinement:** Liquid Glass, accessibility, visual QA, menu-bar optimization, and complete states.
10. **Phase 9 — Release readiness:** parity audit, privacy/security and performance review, archive/sign/notarize, migration validation, and user documentation.

After every phase, build and test where the environment permits, update all relevant documents, and record the exact stopping point. Do not stop after producing a skeleton when safe in-scope work remains.

## Acceptance criteria

Migration is complete only when:

- the app builds with stable Xcode on a clean Mac;
- no .NET runtime, web server, Blazor, WebView, NVIDIA, or AMD dependency remains in the native product;
- the native menu bar and main window work;
- accepted LG/Samsung behavior has implementation and test evidence;
- presets, automation, WOL, and applicable lifecycle events work;
- the game launcher works for macOS applications;
- display/profile functions are implemented or evidence-backed limitations are accepted;
- migration is idempotent, backed up, and does not lose user data;
- secrets live in Keychain;
- destructive commands are opt-in and absent from automated tests;
- accessibility and visual QA are complete;
- archive/signing/notarization workflows are documented and verified as far as credentials allow;
- no `Not audited` feature remains;
- no accepted feature contains placeholder behavior or unresolved TODOs;
- NEXUS, status, source map, parity matrix, and tests agree with the final code.

## Start now

Begin at the stopping point recorded in `migration/PROGRESS.md`. For the current repository state, that means Phase 0:

1. verify the relocated legacy-source integrity;
2. perform the mandatory audit from `legacy-windows/`;
3. create `migration/docs/NEXUS.md` and all required project-intelligence files;
4. create and validate repository skills;
5. produce the first complete source map and feature-parity matrix;
6. derive the final architecture from source evidence;
7. only then scaffold native code in `macOS/VibeScreen/`.

Do not translate C# syntax into Swift mechanically. Preserve behavior while redesigning the implementation as a native macOS application.
