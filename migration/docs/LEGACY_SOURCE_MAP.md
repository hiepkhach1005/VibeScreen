# Legacy source map

Audit date: `2026-08-11`  
Environment: Windows, `C:\wsrc\ColorControl-master`  
Legacy root: `legacy-windows/`  
Audit status: lifecycle/core and function-level migratable behavior audit recorded;
protocol/UI/schema implementation and macOS verification continue.

Detailed atomic rows are tracked in
[FUNCTION_PARITY_CHECKLIST.md](FUNCTION_PARITY_CHECKLIST.md). This source map
remains the compact traceability map; the checklist is the active close-out list.

| Legacy path | Legacy type/symbol | Responsibility | New module/path | Semantic differences | Audit status |
|---|---|---|---|---|---|
| `ColorControl/Program.cs` | `Program.MainAsync`, `RunApp`, `CreateHostBuilder` | Config, logger, single instance, DI, GUI/service mode, Blazor startup | `macOS/ColorControlMac/App/ColorControlMacApp.swift`, `App/CompositionRoot.swift` | No Windows Service, mutex, WinForms loop, or web server; user-session app/menu bar | Mapped |
| `ColorControl/Program.cs` | `LoadConfig`, `InitLogger` | JSON settings and file logging | `Infrastructure/Persistence`, `Infrastructure/Logging` | Application Support + Codable/OSLog; no NLog file as primary store | Mapped |
| `ColorControl/MainWorker.cs` | `DoWork`, `Init` | Register event handlers, menu icon, modules, startup, UI loop | `App/AppLifecycleCoordinator.swift`, `Platform/macOS/*` | Replace message-only window and Windows notifications with public macOS adapters | Mapped |
| `ColorControl/MainWorker.cs` | `HandlePowerBroadcastEvent` | Monitor off/on events | `Platform/macOS/Power` | API availability and display sleep semantics require Mac verification | Mapped |
| `ColorControl/MainWorker.cs` | `HandleQueryEndSessionEvent` | Save state and shutdown trigger | `Platform/macOS/Power`, `ApplicationStateCoordinator` | Use app termination/sleep notifications; no Win32 query-end-session | Mapped |
| `ColorControl/MainWorker.cs` | `StartScreenSaver` | Shortcut starts screensaver | `Platform/macOS/ScreenSaver`, `Features/Settings` | Must use a documented macOS action or mark unsupported | Mapped |
| `ColorControl/MainForm.cs` | module tabs, close/minimize, save | Main desktop UI and module surface | `Features/Root/MainWindowView.swift` | `NavigationSplitView`/settings/window restoration; menu bar is separate | Mapped |
| `Services/Common/ServiceManager.cs` | `LoadModules`, `AddModule`, `Save` | Runtime module composition and persistence | `App/CompositionRoot`, `Domain/ModuleCatalog` | Only LG/Samsung/Game/Profile/automation retained; no GPU services | Mapped |
| `Services/Common/ServiceManager.cs` | `HandleExternalServiceAsync` | Cross-service actions and program launch | `Domain/Action`, `Application/ActionRouter` | Typed action enum; native app launch replaces Win32 process; GPU actions removed | Mapped |
| `Services/Common/ServiceBase.cs` | `LoadPresets`, `SavePresets` | Preset JSON load/backup/save | `Infrastructure/Persistence/VersionedJSONStore` | Versioned atomic migration; no destructive in-place writes | Mapped |
| `Services/Common/ServiceBase.cs` | `ApplyPreset`, `ApplyPresetUi` | Preset selection, execution, errors | `Domain/Automation/PresetExecutor` | Typed results and UI presentation; no popup from domain | Mapped |
| `Services/Common/ServiceBase.cs` | `ExecuteEventPresets`, `CreateTriggerContext` | Match and execute event presets | `Domain/Automation/TriggerEvaluator`, `PresetExecutionCoordinator` | Normalize macOS events; remove G-SYNC condition | Mapped |
| `Services/Common/ServiceBase.cs` | `SetShortcuts`, `HotKeyPressed` | Register preset/quick-access hotkeys | `Platform/macOS/GlobalHotkeys`, `Application/ShortcutRouter` | Permission/API feasibility requires Mac validation | Mapped |
| `Shared/Contracts/Module.cs` | `Module`, module constants | Module activation/config | `Domain/ModuleCatalog` | Retain LG/Samsung/Game; remove NVIDIA/AMD constants | Mapped |
| `Shared/Contracts/Config.cs` | `Config` | Global settings and defaults | `Domain/Settings`, `Infrastructure/Persistence` | Remove web/GDI/elevation/GPU fields; add migration version and macOS settings | Mapped |
| `Shared/Contracts/StartUpParams.cs` | `Parse` | CLI startup flags and preset execution | `Application/CommandLine`, App Intents/URL scheme | Retain LG/Samsung and add native Game where useful; remove GPU flags | Mapped |
| `Shared/Contracts/Presets/PresetBase.cs` | `PresetTrigger`, `PresetTriggerContext` | Trigger/condition matching | `Domain/Automation` | Replace Process/GDI/CCD types with platform-neutral values | Mapped |
| `Shared/Contracts/Presets/PresetBase.cs` | `PresetBase.id`, `SetCloneValues` | Stable ID/clone/order | `Domain/Presets/Preset` | Replace process-global random ID list with injected deterministic ID strategy | Mapped |
| `Shared/Contracts/PresetStep.cs` | `Parse`, `UpdatedRaw` | Compact step DSL | `Domain/Presets/PresetStep` | Preserve import syntax initially; convert to typed action model at boundary | Mapped |
| `Shared/EventDispatcher/EventDispatcher.cs` | event handler dictionaries | Sync/async event routing | `Domain/Automation/EventStream`, actors/AsyncSequence | Structured cancellation and typed events; no duplicate sync/async invocation | Mapped |
| `Shared/EventDispatcher/PowerEventDispatcher.cs` | suspend/resume/startup/shutdown/monitor | Power event source | `Platform/macOS/Power` | IOKit/NSWorkspace public mapping; `SetThreadExecutionState` replaced by power assertion | Mapped |
| `Shared/EventDispatcher/SessionSwitchDispatcher.cs` | lock/unlock/connect/disconnect | Session events | `Platform/macOS/Session` | Verify public NSWorkspace/session availability and user-session scope | Mapped |
| `Shared/EventDispatcher/DisplayChangeEventDispatcher.cs` | display dimensions change | Display event source | `Platform/macOS/Displays` | CoreGraphics callback provides display IDs/config changes rather than Win32 lParam | Mapped |
| `Shared/EventDispatcher/ProcessEventDispatcher.cs` | polling/foreground/fullscreen | Process and screensaver context | `Platform/macOS/ProcessMonitoring` | NSWorkspace/process APIs; fullscreen/notifications need explicit feasibility decision | Mapped |
| `Services/LG/LgService.cs` | device/config/presets/event handlers | LG module orchestration | `Infrastructure/LGWebOS`, `Features/Devices/LG` | Actor state, Keychain, native event integration | Mapped |
| `LgTv/LgTvApi.cs` | WebOS commands/subscriptions/apps/media | LG wire protocol | `Infrastructure/LGWebOS` | Typed codecs and transport; no unsafe TLS bypass | Mapped |
| `LgTv/LgTvConnectionCws.cs` | WebSocket/pairing/receive | LG transport | `Infrastructure/LGWebOS/LGConnectionActor` | Structured concurrency and pending-request cleanup | Mapped |
| `Services/Samsung/SamsungService.cs` | device/config/presets/events | Samsung module orchestration | `Infrastructure/SamsungTizen`, `Features/Devices/Samsung` | Actor state, Keychain token, native event integration | Mapped |
| `Services/Samsung/SamTvConnection.cs` | WebSocket/pairing/events | Samsung transport | `Infrastructure/SamsungTizen` | Explicit trust/pairing and bounded reconnect | Mapped |
| `Services/Samsung/SamsungDevice.cs` | WOL/power/keys/apps/presets | Samsung device behavior | `Infrastructure/SamsungTizen`, `Domain/Devices` | Dangerous service/factory actions require confirmation | Mapped |
| `Services/GameLauncher/GameService.cs` | process detection/auto preset/launch | Game automation | `Features/GameLauncher`, `Domain/Game` | `.app`/bundle ID/Mach-O; Windows affinity/elevation/suspend may be unavailable | Mapped |
| `Shared/Contracts/Game/GamePreset.cs` | game path/args/pre/post/auto | Game preset model | `Domain/Game` | Native URL/bookmark identity replaces `.exe` assumptions | Mapped |
| `Services/Common/GraphicsService.cs` | modes/scaling/rotation/DDC/brightness | Generic display control | `Platform/macOS/Displays` | CoreGraphics/IOKit feasibility must be hardware-tested | Mapped |
| `Services/Common/ColorProfileService.cs` | install/associate/generate ICC | Color profile workflows | `Platform/macOS/ColorSync`, `Features/ColorProfiles` | ColorSync/public API; HDR/MHC2 parity not assumed | Mapped |
| `MHC2Gen/`, `LittleCms/` | ICC/MHC2 generation | Profile generation | `Infrastructure/ColorProfiles`, optional native C target | `lcms2.dll` cannot be reused; native port required | Mapped |
| `Shared/Services/WolService.cs` | magic packet/interfaces/ARP fallback | Wake-on-LAN | `Infrastructure/WakeOnLAN` | UDP magic packet retained; Windows route/ARP helper replaced | Mapped |
| `Services/Common/UpdateManager.cs` | GitHub check/install/restart | Updates | `Infrastructure/Updates` | Signed/notarized updater or release page; no Windows service installer | Mapped |
| `ColorControl.UI/` | Razor pages/layout | Feature inventory only | `Features/*` SwiftUI | Web UI intentionally discarded; behavior retained | Mapped |
| `Nspector/`, `NvAPIWrapper/`, `novideo_srgb/` | NVIDIA/GPU | Excluded | None | Not applicable by product decision | Not applicable |
| `ColorControl.UI` web server/browser | Blazor hosting | Web infrastructure | None | Not applicable by product decision | Not applicable |

## Remaining audit work

- Read the remaining LG/Samsung protocol bodies and build redacted message fixtures.
- Resolve exact legacy secret-storage variants and add migration golden fixtures.
- Finish the protocol, display/color, and UI implementation rows in
  FUNCTION_PARITY_CHECKLIST.md.
- Verify public macOS event and display APIs on a Mac.
