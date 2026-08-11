# Migratable function parity checklist

Audit date: 2026-08-11  
Legacy source: legacy-windows/  
Native source: macOS/ColorControlMac/  
Canonical purpose: compare the user-observable and behaviorally meaningful functions that can be retained on macOS.

## How to use this file

This is a behavior checklist, not a mechanical one-to-one list of every C# getter,
WinForms designer callback, private helper, or generated DTO accessor. A row groups
the complete call chain when several private functions implement one user-visible
behavior. The legacy column still names the important entry points so the behavior
can be traced back to source.

The old source remains read-only. Do not check a row as complete only because a
Swift type exists. A row is complete only when the path is reachable from the app,
the relevant tests/build pass on macOS, and hardware-dependent behavior has evidence
where required.

### Status legend

- Implemented (static) — native behavior is implemented in source and covered by
  host-independent tests, but this Windows host cannot compile or run Swift.
- Partial — a bounded native slice exists, but parity, reachability, UI, error
  handling, protocol state, or verification is incomplete.
- Missing — no native implementation is present yet.
- Blocked — the behavior needs a macOS API or hardware feasibility decision before
  it can be completed safely.
- Not applicable — intentionally removed because it is NVIDIA, AMD, web, Windows
  Service, Win32, registry, WMI, or another Windows-only implementation detail.
- Tested — only use after the macOS build/test or the required hardware test has
  actually run. There are currently no end-to-end Tested rows from this Windows
  environment.

## Audit baseline

- Legacy relocation is intact: 850 files, 103 directories, 6,529,163 bytes.
- Legacy manifest SHA-256: 9cd669f758618edd70b68865d54effcffd0c5cd81589a524cf194fee3bb738b2.
- Native tree currently contains 34 Swift source files and 13 Swift test files,
  plus the package manifest.
- swift, swiftc, xcodebuild, swift-format, and sourcekit-lsp are not installed
  on the current Windows host.
- Therefore Implemented (static) and Partial below are source-audit results,
  not a claim that the app already runs on macOS.

## A. Application, settings, lifecycle, and module composition

| ID | Legacy function or behavior | Native mapping and evidence | Status | Remaining checklist |
|---|---|---|---|---|
| APP-001 | Program.Main, MainAsync, RunApp, CreateHostBuilder, RegisterSharedServices: start the interactive process and compose services | macOS/ColorControlMac/App/ColorControlMacApp.swift, App/AppContainer.swift, Swift Package executable | Partial | [ ] Build the executable on macOS. [ ] Verify dependency composition and first-launch failure handling. |
| APP-002 | Program.OpenDefaultUi, OpenMainForm, OpenNewUi, OpenNewUiEmbedded, StartOrStopUiServer: open or restore the main UI | Features/MainWindowView.swift, Features/MenuBarView.swift, SwiftUI WindowGroup and MenuBarExtra | Partial | [ ] Verify window restoration and menu-bar-to-window activation on macOS. [ ] Remove any stale server assumptions. |
| APP-003 | Program.IsMainFormOpened, mutex and EnumThreadWindows: prevent duplicate instance and bring the existing window front | No native single-instance or activation coordinator is present | Missing | [ ] Add an AppKit lifecycle/activation boundary using a documented macOS mechanism. [ ] Add a UI test. |
| APP-004 | Program.Exit, Restart, MainForm_FormClosing, MainWorker.HandleQueryEndSessionEvent, GlobalSave: save and close safely | Persistence/NativeStore.swift, AppContainer.persistNativeState, ColorControlMacApp lifecycle shell | Partial | [ ] Wire termination/background save. [ ] Verify cancellation of active work and atomic backup recovery. |
| APP-005 | Program.RunService, UseWindowsService, Windows Service install/start/stop | User-session app and optional LoginItemManager using SMAppService; no Windows service | Not applicable | [x] Keep the Windows Service out. [ ] Decide whether a login item is sufficient for the final product. |
| CFG-001 | Program.LoadConfig, Config, OptionsService.GetConfig, SetConfig, SaveSettings: load and save global settings | Persistence/NativeStore.swift, NativeAppSettings, Application Support JSON schema v2 | Partial | [ ] Complete the settings field mapping. [ ] Add migration golden fixtures and macOS store tests. |
| CFG-002 | OptionsService.SetStartAfterLogin, SetStartMinimized, SetMinimizeOnClose, SetMinimizeToTray, SetDarkMode, SetProcessMonitorPollingInterval, SetLogLevel | LoginItemManager.swift, NativeAppSettings, SettingsView | Partial | [ ] Persist all retained settings from UI. [ ] Define native equivalents for start-hidden and menu-bar behavior. |
| CFG-003 | OptionsService.InstallUpdate, RestartAfterUpdate, UpdateManager.CheckForUpdates, InstallUpdate | No update service or updater UI in the native target | Missing | [ ] Choose a signed/notarized update mechanism. [ ] Implement update checks only after bundle identity and release channel are decided. |
| CFG-004 | Program.InitLogger, LoggingService.SetLogLevel, LoadLog, log viewer/export behavior | Platform/ColorControlLogger.swift and OSLog calls in AppContainer | Partial | [ ] Add user-facing diagnostics/activity export if required. [ ] Verify privacy-redacted logs. |
| CFG-005 | StartUpParams.Parse, CommandLineHandler.HandleStartupParams, PrepareConsole: CLI startup and preset invocation | No native command-line or URL/App Intent boundary | Missing | [ ] Decide whether CLI, URL scheme, or App Intents are product requirements. [ ] Add only retained LG/Samsung/game actions. |
| MOD-001 | ServiceManager.LoadModules, AddModule, ActivateModule, HandleExternalServiceAsync, Save | AppContainer, typed repositories, PresetDeviceActionRouter | Partial | [ ] Replace the generic module catalog with a complete native capability registry. [ ] Test cross-feature action routing. |
| MOD-002 | Module.CreateService, ServiceBase.Initialize, Uninitialize, LoadServices | Swift actors and app-owned adapters; no equivalent generic service factory | Partial | [ ] Document ownership and shutdown for each actor. [ ] Verify no task or WebSocket survives app termination. |

## B. Events, automation, power, session, process, and shortcuts

| ID | Legacy function or behavior | Native mapping and evidence | Status | Remaining checklist |
|---|---|---|---|---|
| AUTO-001 | EventDispatcher.RegisterEventHandler, RegisterAsyncEventHandler, DispatchEvent, DispatchEventAsync, HasHandlers | Application/AutomationCoordinator.swift, typed AsyncStream platform signals | Implemented (static) | [ ] Run the concurrency and cancellation tests on macOS. [ ] Verify duplicate-handler and shutdown behavior. |
| AUTO-002 | PowerEventDispatcher.SendEvent, OnPowerModeChanged: suspend, resume, startup, shutdown, monitor off/on | Platform/PlatformEvents.swift, Platform/MacPlatformEventSource.swift, TVPowerCoordinator.swift | Partial | [ ] Verify actual sleep, wake, display-sleep, and shutdown notifications on macOS. [ ] Add event ordering tests. |
| AUTO-003 | SessionSwitchDispatcher: lock, unlock, connect, disconnect and service-specific session handlers | MacPlatformEventSource, TVPowerPolicyEngine, TVPowerPolicyCoordinator | Partial | [ ] Verify lock/unlock semantics on the target macOS versions. [ ] Confirm actions do not run when no user session is active. |
| AUTO-004 | DisplayChangeEventDispatcher, MainWorker display broadcasts: react to topology/configuration changes | MacPlatformEventSource screen-change observation and MacDisplayService | Partial | [ ] Add CoreGraphics display callback and a stable display snapshot comparison. [ ] Test hot-plug and unplug. |
| AUTO-005 | ProcessEventDispatcher.CheckProcesses, FillContext: polling, started/stopped/running/foreground process state | MacPlatformEventSource observes application launch/terminate/activate and stores bundle identifiers | Partial | [ ] Add robust process state tracking. [ ] Define permission behavior and polling fallback. |
| AUTO-006 | PresetTrigger.TriggerActive: included/excluded processes, connected-display regex, HDR, fullscreen, notification-disabled, G-SYNC | PresetTrigger.matches and AutomationEventContext in Domain/Models.swift | Partial | [ ] Verify process/display matching. [ ] Implement or explicitly reject fullscreen and notification-disabled context. [x] Exclude G-SYNC as NVIDIA-only. |
| AUTO-007 | StartScreenSaver, screen-saver process transitions, ExecuteScreenSaverPresets, minimum-duration handling | PlatformSignalKind.screensDidSleep/screensDidWake, TVPowerPolicyEngine | Partial | [ ] Verify manual versus automatic screen-saver behavior. [ ] Preserve minimum-duration semantics. |
| AUTO-008 | KeyboardShortcutDispatcher.ParseShortcut, register/unregister raw/global shortcuts, ServiceBase.SetShortcuts, HotKeyPressed | No global hotkey implementation in the native target | Missing | [ ] Choose AppKit event monitor or an accessibility-permission design. [ ] Add permission diagnostics and shortcut conflict handling. |
| AUTO-009 | SetThreadExecutionState and other keep-awake behavior during operations | No native power assertion adapter | Missing | [ ] Implement an IOKit IOPMAssertion boundary if the product needs to prevent sleep. [ ] Test release on success, error, and cancellation. |
| AUTO-010 | ServiceBase.CreateTriggerContext, ExecuteEventPresets, ExecuteProcessPresets, ExecuteScreenSaverPresetsCustom | AutomationCoordinator, PresetExecutionCoordinator, app platform event loop | Partial | [ ] Connect every retained signal to real preset lookup and execution. [ ] Record per-trigger result and error. |

## C. Presets, step parsing, execution, and cross-feature actions

| ID | Legacy function or behavior | Native mapping and evidence | Status | Remaining checklist |
|---|---|---|---|---|
| PRE-001 | ServiceBase.LoadPresets, SavePresets, AfterPresetsLoaded, default preset fallback and backup | Persistence/NativeStore.swift, schema-v2 snapshot and .bak write | Partial | [ ] Verify corrupt-primary recovery. [ ] Add version migration and default-data fixtures. |
| PRE-002 | GetPresets, GetPresetByIdOrName, GetPresetById, PresetBase.IdOrName | PresetRepository, InMemoryPresetRepository, target matching in PresetDeviceActionRouter | Partial | [ ] Add explicit repository lookup by stable UUID, legacy numeric ID, and name. [ ] Define duplicate-name behavior. |
| PRE-003 | CreateNewPreset, CreateNewPresetName, UpdatePreset, DeletePreset, SetCloneValues, reorder and clone UI | Features/MainWindowView.swift preset CRUD/editor and NativeStore persistence | Partial | [ ] Add clone, reorder, validation, duplicate-name handling, and undo-safe editing. |
| PRE-004 | PresetStep.Parse, CustomStepItem, UpdatedRaw, simple and parenthesized action syntax with delay/option | Domain/PresetStepParser.swift, PresetStep.updatedRawValue, parser tests | Tested (host-independent only) | [ ] Run PresetStepParserTests on macOS. [ ] Add fixtures for every retained legacy action syntax. |
| PRE-005 | ServiceBase.ApplyPreset, ApplyPresetWithId, ApplyPresetUi, PresetApplied: ordered execution, delay, retry, cancellation, result/error | Application/PresetExecutor.swift, PresetExecutionCoordinator, typed result model | Implemented (static) | [ ] Run tests on macOS. [ ] Verify cancellation while a TV request, WOL delay, or app launch is active. |
| PRE-006 | ServiceManager.HandleExternalServiceAsync and module-specific preset steps | Application/PresetDeviceActionRouter.swift: TV command, WOL/power-on, display refresh, application launch | Partial | [ ] Implement the remaining retained action capabilities. [ ] Keep unsupported actions as explicit user-visible failures. |
| PRE-007 | PresetBase.UpdateTrigger, UpdateTriggers, SetSteps, PresetTrigger.TriggerActive | Typed Preset, PresetTrigger, and action model in Domain/Models.swift | Partial | [ ] Compare every legacy trigger field and default. [ ] Persist all supported trigger conditions. |
| PRE-008 | GetLastAppliedPreset, LastUsed, quick-access visibility, NotifyIconManager preset actions | DashboardView, MenuBarView, Preset.showInQuickAccess | Partial | [ ] Persist and update last-used state after successful execution. [ ] Add failure feedback to menu-bar actions. |
| PRE-009 | ValidatePreset, AddJsonConverter, unknown action compatibility and error popup policy | ColorControlCoreError, typed failures, preserved raw/unknown action warnings | Implemented (static) | [ ] Add validation rules for device references, action parameters, and destructive actions. [ ] Verify no silent action loss. |
| PRE-010 | ExecuteInvokableAction, GetInvokableActions, GetInfo for retained modules | Native device command router and basic device UI | Partial | [ ] Expose a capability-driven action list instead of hard-coded bounded buttons. [ ] Add per-action availability and confirmation. |

## D. LG WebOS functions

| ID | Legacy function or behavior | Native mapping and evidence | Status | Remaining checklist |
|---|---|---|---|---|
| LG-001 | LgService.GetDevices, UpdateDevice, TestDevice, SetSelectedDevice, RemoveDevice, AddCustomDevice, MatchDevice | TVDeviceDescriptor, AppContainer, DevicesView, TVDeviceEditorView | Partial | [ ] Verify add/edit/delete/test flows on macOS. [ ] Preserve selected-device behavior across reload. |
| LG-002 | LgService.RefreshDevices, DeviceSearchKey, discovery and refresh-on-startup | No Bonjour/discovery implementation; manual host/MAC configuration exists | Missing | [ ] Implement Bonjour/WebOS discovery or document manual setup as the supported path. [ ] Add discovery timeout/error UI. |
| LG-003 | LgTvApi.CreateLgTvApi, MakeHandShake, ClientKeyStore, registration resources | LGWebOSRegistration, KeychainCredentialStore, LGWebOSDeviceClient.connect | Partial | [ ] Test first pairing, existing key, rejected key, and key deletion on real LG hardware. [ ] Add pairing UI and confirmation state. |
| LG-004 | LgTvConnectionCws.Connect, SendMessageAsync, SendCommandAsync, Receive, HandleMessage, reconnect and pending-token cleanup | MacTVWebSocketTransport, LGWebOSRequestFactory, actor client | Partial | [ ] Add request correlation timeout, reconnect policy, pending-request cleanup, and TLS/trust diagnostics. |
| LG-005 | SubscribeVolume, SubscribePowerState, SubscribeForegroundApp, SubscribePictureSettings, and device state callbacks | No subscription/state-machine implementation; only request/receive slices exist | Missing | [ ] Implement subscriptions as actor-owned streams. [ ] Reconcile updates with UI and automation without polling races. |
| LG-006 | TurnOff, TurnScreenOff, TurnScreenOn, Reboot, Wake, WakeAndConnect, PowerOffDevices, PowerOnDevices | TVCommand, TVPowerPolicyCoordinator, MacWakeOnLANSender, LG client | Partial | [ ] Test power-off, screen-off, wake by WOL, retries, and offline devices on hardware. [ ] Confirm safe handling of a manually powered-off TV. |
| LG-007 | VolumeDown, VolumeUp, SetVolume, SetMute, ToogleMute, GetVolume, IsMuted | TVCommand.volumeUp, volumeDown, setVolume, mute and basic remote UI | Partial | [ ] Add read-state and mute toggle support. [ ] Verify model capability differences and error presentation. |
| LG-008 | ChannelList, GetChannel, SetChannel, ChannelInfo, ChannelUp, ChannelDown, GetInputList, SetInput | No native channel/input model or UI | Missing | [ ] Add typed capability models and UI only if these actions remain in product scope. |
| LG-009 | GetLaunchPoints, GetApps, LaunchApp, CloseApp, OpenWebBrowser, LaunchYouTube | TVCommand.launchApplication and TVDeviceClients; no app catalog/browser/media UI | Partial | [ ] Add app discovery/catalog and launch/close UI. [ ] Map URL/video parameters safely. |
| LG-010 | SetSystemSettings, SetConfig, SetSystemProperty, SetDeviceConfig, SetTpcOrGsr, picture actions and GetSystemInfo | No general LG settings/picture action surface; only typed bounded commands | Missing | [ ] Inventory safe public WebOS actions. [ ] Add capability/firmware gating and confirmation for destructive settings. |
| LG-011 | GetMouseAsync, LgWebOsMouseService, SendKey, remote pointer WebSocket | MacLGPointerWebSocketTransport, normalized LG remote-button set, TVRemoteControls | Partial | [ ] Test pointer socket URL and button semantics. [ ] Expand button coverage from the legacy remote definitions. |
| LG-012 | LoadRemotes, GetRemotes, UpdateRemote, DeleteRemote, LgRemotes.json | LegacyRemoteImporter, TVRemoteDefinition, native storage | Partial | [ ] Add custom remote editor, button placement/editing, duplicate handling, and preview. |
| LG-013 | GetRemoteControlButtons, GenerateDefaultRemoteControlButtons, LgPreset_GetAppName, LG preset import and invocation | LegacyPresetImporter, native presets and basic remote controls | Partial | [ ] Reconcile legacy LG preset IDs/app IDs with native stable IDs. [ ] Test each imported step and show unmappable actions. |
| LG-014 | LgDevice.AddInvokableAction, GetInvokableActions, ExecuteInvokableAction, generic picture/device/config/Luna/volume action factories | No capability-driven LG action registry; only bounded typed commands | Missing | [ ] Port retained safe actions through typed command definitions. [ ] Keep model-year and firmware constraints. |
| LG-015 | ToggleGameBar, LgGameBar, game-bar shortcut and quick-action controls | No native game-bar window or global shortcut | Missing | [ ] Decide whether a native floating game bar is still required. [ ] Implement only after shortcut and window-level design is approved. |
| LG-016 | LgDevice power flags: PowerOnAfterStartup, PowerOnAfterResume, PowerOffOnShutdown, PowerOffOnStandby, PowerOffOnScreenSaver, ScreenSaverMinimalDuration, TurnScreenOffOnScreenSaver, PowerOnAfterScreenSaver, TurnScreenOnAfterScreenSaver, PowerOnAfterManualPowerOff, PowerOnByWindows, PowerOffByWindows, session flags, TriggersEnabled, HDMIPortNumber | TVPowerPolicy, TVPowerPolicyEngine, TVPowerCoordinator; Windows monitor flags map to macOS screen sleep/wake | Partial | [ ] Add manual screen-saver distinction, HDMI routing, and manual-power-off state. [ ] Verify every policy option and delay/retry on macOS. |

## E. Samsung Tizen functions

| ID | Legacy function or behavior | Native mapping and evidence | Status | Remaining checklist |
|---|---|---|---|---|
| SAM-001 | SamsungService.GetDevices, UpdateDevice, TestDevice, SetSelectedDevice, RemoveDevice, custom device matching | TVDeviceDescriptor, AppContainer, DevicesView, TVDeviceEditorView | Partial | [ ] Verify Samsung add/edit/delete/test/selection flows on macOS. |
| SAM-002 | SamsungService.RefreshDevices, preferred MAC/search key and startup refresh | No discovery implementation; manual host/MAC configuration exists | Missing | [ ] Implement or explicitly document manual discovery. [ ] Add timeout and offline state. |
| SAM-003 | SamsungDevice.ConnectAsync, token refresh, Connection_Connected, pairing prompt and token persistence | SamsungMessageParser, SamsungTizenDeviceClient, KeychainCredentialStore | Partial | [ ] Test authorized, unauthorized, first-pair, token-reuse, and token-delete paths. [ ] Add pairing confirmation UI. |
| SAM-004 | SamTvConnection.Connect, SendMessageAsync, SendCommandAsync, Receive, reconnect | SamsungWebSocketEndpoint, MacTVWebSocketTransport, actor client | Partial | [ ] Add timeout, reconnect, close/error state, and secure/non-secure trust diagnostics. |
| SAM-005 | PowerOffAsync, Wake, WakeAndConnect, WakeAndConnectWithRetries, GetPowerStateAsync, SendWol | TVPowerCoordinator, MacWakeOnLANSender, Samsung client power path | Partial | [ ] Verify WOL and power commands on real Samsung models. [ ] Preserve retry and shutdown-delay semantics. |
| SAM-006 | SendKeyAsync, remote keys, custom remote definitions and remote UI | SamsungRemoteCommand, TVDeviceClients, LegacyRemoteImporter, basic TVRemoteControls | Partial | [ ] Expand key coverage from SamsungRemotes.json. [ ] Add custom remote editor and capability validation. |
| SAM-007 | GetAppsAsync, RefreshAppsAsync, SamsungApp launch behavior | No Samsung app catalog or launch UI | Missing | [ ] Port app discovery/launch only after protocol fixtures and capability rules exist. |
| SAM-008 | TurnPictureOff, TurnPictureOn, PerformActionOnScreenSaver, PerformActionAfterScreenSaver | TVPowerPolicyEngine supports generic screen-off/on commands, Samsung client reports unsupported screen control | Partial | [ ] Implement/test Samsung screen control where the protocol supports it. [ ] Otherwise show a model-specific limitation. |
| SAM-009 | ServiceMenuAction, OpenHospitalityMenu, OpenFactoryMenu | No native implementation | Missing | [ ] If retained, add explicit dangerous-action confirmation, audit log, and model gating. [ ] Never expose by default. |
| SAM-010 | SamsungPreset, ApplyPreset, ExecuteStepsAsync, GetInvokableActions, ExecuteInvokableAction | Generic native Preset, parser, executor, router | Partial | [ ] Map every Samsung action and parameter. [ ] Preserve progress, failure, and cancellation semantics. |
| SAM-011 | Samsung power flags, retries, shutdown delay, manual-power-off rules, screen-saver and session behavior | TVPowerPolicy and TVPowerPolicyCoordinator | Partial | [ ] Add manual-power-off tracking and exact retry/delay behavior. [ ] Verify startup/resume/standby/shutdown/lock/unlock. |
| SAM-012 | LoadRemotes, GetRemotes, UpdateRemote, DeleteRemote, SamsungRemotes.json | LegacyRemoteImporter, TVRemoteDefinition, native storage | Partial | [ ] Build remote editor/layout and migrate all button metadata. |
| SAM-013 | SamsungService.ExecuteEventPresets, ProcessChanged, screen-saver custom handling | AutomationCoordinator, macOS event source, generic trigger model | Partial | [ ] Connect Samsung device presets to every retained platform event. [ ] Add process/screen-saver fixtures. |
| SAM-014 | GetInfo, connection status and selected-device UI feedback | ActivityView, device rows, OSLog | Partial | [ ] Add persistent connection state, last error, retry action, and offline empty states. |

## F. Game launcher and game automation

| ID | Legacy function or behavior | Native mapping and evidence | Status | Remaining checklist |
|---|---|---|---|---|
| GAME-001 | GamePreset: path, parameters, pre-launch, post-launch, finalize steps, AllowAutoApply, ProcessAutoAction | Application/GameWorkflow.swift, GamePreset, typed PresetStep | Partial | [ ] Add native fields for arguments, working directory, app identity, and migration warnings. [ ] Add editor validation. |
| GAME-002 | GameService.GetPresets, UpdatePreset, GetMruApps, SelectPath, add/clone/delete/edit UI | GamesView displays/launches native presets; no complete editor or file picker | Partial | [ ] Add create/edit/clone/delete/reorder and NSOpenPanel/bookmark handling. |
| GAME-003 | GameService.ExecutePreset, WinApiAdminService.StartProcess: launch executable with arguments and working directory | MacGameProcessLauncher, MacApplicationLauncher, GameLaunchSpecification | Partial | [ ] Build and run on macOS for .app, bundle ID, executable, arguments, and working directory. [ ] Handle sandbox/security-scoped URLs. |
| GAME-004 | ExecuteSteps, ExecuteFinalizationStepsAsync, wait for process exit, delays and failure behavior | GameWorkflowCoordinator, PresetExecutionCoordinator | Implemented (static) | [ ] Run GameWorkflowTests on macOS. [ ] Verify finalization on crash, cancellation, and early launch failure. |
| GAME-005 | GameService.ProcessChanged, HandleStartedProcess, external process matching and ApplyExternallyLaunched | MacPlatformEventSource application notifications and GameProcessAutoAction model | Partial | [ ] Track process identity and started/terminated state robustly. [ ] Add externally launched game detection. |
| GAME-006 | AllowAutoApply, automatic game preset selection and process action suspend/restart | No automatic game-preset execution path is wired from platform events | Missing | [ ] Connect process events to a safe auto-apply coordinator. [ ] Add user confirmation/loop prevention and tests. |
| GAME-007 | ProcessAutoAction.Suspend, Restart, thread resume, affinity, priority, RunAsAdministrator | No public macOS equivalent in current target | Not applicable | [x] Exclude Windows thread/affinity/elevation semantics. [ ] Document the limitation in the game editor and migration report. |
| GAME-008 | Game quick access and shortcuts from GamePanel and NotifyIconManager | GamesView and MenuBarView have bounded launch surfaces | Partial | [ ] Add quick-launch entries, shortcut design, and per-game error/status feedback. |

## G. Display, mode, brightness, DDC, HDR, and ColorSync

| ID | Legacy function or behavior | Native mapping and evidence | Status | Remaining checklist |
|---|---|---|---|---|
| DISP-001 | GraphicsService.HasDisplaysAttached, display enumeration, names, IDs, resolutions, refresh rates | MacDisplayService, MacDisplaySnapshot, DevicesView display inventory | Partial | [ ] Build on macOS and verify internal/external display identity, scale, HDR, and hot-plug. |
| DISP-002 | GraphicsService.SetMode, GetAvailableRefreshRatesV2, GetAvailableResolutionsInternalV2 | MacDisplayControl.modes, apply, CGDisplaySetDisplayMode | Partial | [ ] Test mode enumeration/application and rollback when a mode is rejected. |
| DISP-003 | SetSDRBrightness, GetSDRBrightness | No native brightness adapter | Missing | [ ] Decide public CoreBrightness/DisplayServices or DDC scope. [ ] Do not use private APIs without an explicit product decision. |
| DISP-004 | SetMonitorScaling, rotation, topology and generic display configuration | Only display mode path exists | Missing | [ ] Add only documented macOS APIs that are available for the supported OS range. [ ] Test multi-display topology. |
| DISP-005 | EnumeratePhysicalMonitors, ReadDDC, WriteDDC | No native DDC/IOKit adapter | Blocked | [ ] Run a macOS/hardware feasibility spike. [ ] Record monitor compatibility and permission requirements before implementation. |
| COLOR-001 | ColorProfileService.GetAllColorProfileNames, GetDisplayColorProfiles, GetAllDisplayColorProfiles, GetColorProfile | MacColorProfileService.installedProfiles, ICC inventory/validation | Partial | [ ] Verify ColorSync inventory and per-display association on macOS hardware. |
| COLOR-002 | InstallColorProfile, UninstallColorProfile, AddDisplayColorProfile, RemoveDisplayColorProfile, SetDisplayDefaultColorProfile | No profile installation/association/default-write path; MacColorProfileService validates only | Missing | [ ] Implement with documented ColorSync APIs or document an accepted limitation. [ ] Add permission and rollback handling. |
| COLOR-003 | UpdateColorProfile, InstallAndActivateColorProfile, RGB/EDID conversion and profile editing | No native ICC/MHC2 editor/generator | Missing | [ ] Port or replace LittleCMS/MHC2 functionality with a maintained native implementation. [ ] Add golden ICC fixtures. |
| COLOR-004 | GetDisplayInfos, HDR filtering, PresetTriggerContext.IsHDRActive | MacDisplaySnapshot.isHDR and optional AutomationEventContext.isHDR | Partial | [ ] Feed actual HDR state into trigger context. [ ] Verify HDR transitions and profile association. |
| COLOR-005 | SetMinTmlAndMaxTml, Chrome font fix and other Windows display workarounds | Removed as Windows/GDI/Chrome-specific settings | Not applicable | [x] Exclude from native scope. [ ] Preserve a migration warning so users know why the setting disappeared. |

## H. Wake-on-LAN and network helpers

| ID | Legacy function or behavior | Native mapping and evidence | Status | Remaining checklist |
|---|---|---|---|---|
| WOL-001 | WolService.GetWolPacket: magic packet construction and MAC normalization | Protocols/WakeOnLAN.swift, WakeOnLANPacket | Tested (host-independent only) | [ ] Run ProtocolAndWakeTests on macOS. [ ] Add malformed-MAC and broadcast-address fixtures. |
| WOL-002 | WolService.SendWol, BroadcastWol, SendWolToIpAddress | Platform/MacWakeOnLANSender.swift, Network.framework UDP broadcast | Partial | [ ] Verify local-network permission, broadcast routing, and real LG/Samsung wake. |
| WOL-003 | IsViableWOLInterface, enumerate all NICs and choose viable local/broadcast addresses | No multi-interface selection policy | Missing | [ ] Add interface enumeration and deterministic selection for Wi-Fi, Ethernet, VPN, and inactive interfaces. |
| WOL-004 | CreateTransientLocalNetEntry, DeleteNetEntry, ARP/route fallback and retry behavior | No native route/ARP fallback | Not applicable | [x] Do not port Windows route-table mutation. [ ] Add a safe macOS fallback or document networks where WOL cannot work. |

## I. Data migration, persistence, secrets, and compatibility

| ID | Legacy function or behavior | Native mapping and evidence | Status | Remaining checklist |
|---|---|---|---|---|
| MIG-001 | Global Config and retained settings import, including startup, menu-bar, polling, log settings | LegacySettingsImporter, LegacyMigrationCoordinator, NativeAppSettings | Partial | [ ] Compare every retained field/default. [ ] Produce a user-visible preview and warning list. |
| MIG-002 | LgServiceConfig, SamsungServiceConfig, device lists and selected-device fields | LegacyDeviceImporter, TVDeviceDescriptor, stable UUID mapping | Partial | [ ] Add fixtures for real config variants. [ ] Verify duplicate host/MAC and missing-secret handling. |
| MIG-003 | LgPresets.json, Samsung preset objects, generic PresetBase, step syntax | LegacyPresetImporter, LegacyPresetImporterTests, typed Preset | Partial | [ ] Import all supported steps and report every omitted action. [ ] Verify stable IDs and duplicate names. |
| MIG-004 | GamePreset, game config, remotes and LgRemotes.json/SamsungRemotes.json | LegacyGameImporter, LegacyRemoteImporter, NativeStore | Partial | [ ] Verify app paths, remote button geometry, image names, and unsupported fields. |
| MIG-005 | LG client keys and Samsung tokens from legacy storage | KeychainCredentialStore; native JSON stores only credential references | Partial | [ ] Implement source-secret detection/redacted import. [ ] Test Keychain write/read/delete and no-secret-in-JSON invariant. |
| MIG-006 | Dry run, backup, atomic save, unknown-field preservation, repeat import and rollback | LegacyMigrationCoordinator, NativeStore primary plus .bak | Partial | [ ] Add idempotency tests, explicit rollback, migration version markers, and golden fixtures. |
| MIG-007 | Migration UI, file/folder selection, progress, conflict resolution and actionable warnings | No migration wizard/file picker in native UI | Missing | [ ] Build a SwiftUI migration assistant with preview, conflict choices, commit, backup location, and report export. |
| MIG-008 | GPU, web, Windows-service, registry, RPC, elevation and unknown legacy settings | Importers emit omission/warning information; native model excludes those fields | Implemented (static) | [ ] Verify warnings are shown to the user and written to the migration report. |

## J. Native macOS UI and user workflows

| ID | Legacy function or behavior | Native mapping and evidence | Status | Remaining checklist |
|---|---|---|---|---|
| UI-001 | MainForm tabs, module panels, load/activated/deactivated/resize behavior | MainWindowView navigation: Overview, Devices, Presets, Games, Automation, Activity, Settings | Partial | [ ] Verify window sizing, restoration, keyboard navigation, and macOS toolbar/menu conventions. |
| UI-002 | NotifyIconManager.Build, tray context menu, quick preset actions, open/exit/restart | MenuBarView, MenuBarExtra | Partial | [ ] Add all retained quick actions and correct menu-bar state. [ ] Verify Quit/Open Window behavior. |
| UI-003 | LG/Samsung device add/edit/test/remove and per-device power options | DevicesView, TVDeviceEditorView, AppContainer | Partial | [ ] Add connection test, pairing state, secret management, and unsupported-option explanations. |
| UI-004 | Legacy remote forms/panels and remote button actions | TVRemoteControls with bounded LG pointer/Samsung key commands | Partial | [ ] Add complete remote layout, custom remotes, focus/accessibility, and offline state. |
| UI-005 | LG game bar and advanced LG/Samsung action panels | No native game bar or advanced action editor | Missing | [ ] Decide retained scope. [ ] Add confirmation for service/factory/destructive actions. |
| UI-006 | Preset list, add/edit/delete/clone, steps, triggers, quick access and apply result | PresetsView, PresetEditorView, PresetRow, AppContainer.apply | Partial | [ ] Complete editor fields, step reorder/validation, trigger conditions, clone, and result detail. |
| UI-007 | Game list/editor, browse, add steps, launch, clone, process options | GamesView and GameWorkflowCoordinator launch surface | Partial | [ ] Add full native editor, bundle/file picker, phases, auto-apply explanation, and limitation labels. |
| UI-008 | Options/info panels, update controls, log viewer, module status | SettingsView, ActivityView, OSLog | Partial | [ ] Add retained settings, diagnostics export, update surface, and clear per-device errors. |
| UI-009 | Migration prompts and import status | No native migration wizard | Missing | [ ] Implement MIG-007 before declaring data migration complete. |
| UI-010 | Empty/loading/error states, destructive confirmations, accessibility, dark/light appearance and Liquid Glass layout | SwiftUI empty/error cards and glass-style surfaces in MainWindowView | Partial | [ ] Run VoiceOver/keyboard/contrast checks. [ ] Perform visual QA on supported macOS versions and actual window sizes. |

## K. Explicit exclusions and replacements

| ID | Legacy area | Decision | Status | Checklist |
|---|---|---|---|---|
| EX-001 | NVIDIA services, NvAPI, G-SYNC, NVIDIA presets, Nspector, novideo_srgb | Remove from native product. GPU-specific trigger/settings are not migrated as executable behavior. | Not applicable | [x] Keep out of Swift runtime. [ ] Show migration warnings for dropped settings. |
| EX-002 | AMD services, ADL, AMD presets and AMD quick access | Remove from native product. | Not applicable | [x] Keep out of Swift runtime. [ ] Show migration warnings for dropped settings. |
| EX-003 | ColorControl.UI, Blazor, Razor pages, web server, browser UI, remote web connections | Remove web UI entirely by product decision. Native SwiftUI is the only UI. | Not applicable | [x] Keep web files only under read-only legacy source. [ ] Do not add WebView or HTTP server dependencies. |
| EX-004 | Windows Service, Win32 message window, registry, WMI, named pipe, RPC/elevated helper, Task Scheduler | Replace retained behavior with app lifecycle, actors, Application Support, Keychain, NSWorkspace, IOKit/CoreGraphics/ColorSync where public. | Not applicable | [x] Do not port implementation details. [ ] Complete each replacement row above and document unsupported behavior. |
| EX-005 | Windows GDI/DXGI/private display DLL and lcms2.dll/Windows native binaries | Do not copy binaries. Use public macOS display/ColorSync APIs or a separately maintained native dependency. | Not applicable | [x] Keep native binaries out of the macOS target. [ ] Resolve COLOR/DISP feasibility rows independently. |
| EX-006 | Windows game elevation, thread suspend, affinity, priority and process-class manipulation | Not portable as a guaranteed feature. Retain safe launch, arguments, working directory, waiting, and automation only. | Not applicable | [x] Preserve the limitation in UI and migration reports. [ ] Test the retained game workflow. |

## Current conclusion

The conversion is not complete. The native source currently covers a meaningful
foundation and several host-independent behaviors: typed presets and triggers,
step parsing, ordered execution with cancellation/retry, WOL packet generation,
basic LG/Samsung transport boundaries, Keychain boundaries, migration importers,
basic TV power policy, game launch workflow, display mode access, SwiftUI window,
and MenuBarExtra.

The highest-impact parity gaps are:

1. macOS build/test/signing and real-hardware verification.
2. LG/Samsung pairing, reconnect, subscription/state handling, discovery, and
   complete command/capability coverage.
3. Native process-trigger automation, global shortcuts, power assertions, and
   exact screen-saver/session semantics.
4. Full preset/game/remote/migration editors and error/status UX.
5. Display brightness/DDC, ColorSync association/default writes, ICC/MHC2
   generation, and HDR trigger context.
6. Single-instance/window lifecycle, updates, diagnostics, and release packaging.

## Required close-out rule

Do not change the conclusion to “complete” until every retained row is either
Tested or explicitly Accepted with a documented limitation, every Missing row
that is in product scope is implemented, every Blocked row has a recorded
decision, and the macOS build plus required TV/display/power tests have evidence.

## Next audit continuation point

1. On a macOS build machine, run swift test and build
   macOS/ColorControlMac/Package.swift in Xcode.
2. Fix Swift 6 and SDK diagnostics before adding more behavior.
3. Continue with LG pairing -> reconnect/subscription -> pointer remote -> WOL
   and power policy, then Samsung token flow.
4. Update this checklist, migration/docs/FEATURE_PARITY_MATRIX.md,
   migration/docs/LEGACY_SOURCE_MAP.md, and migration/PROGRESS.md after each
   verified slice.

