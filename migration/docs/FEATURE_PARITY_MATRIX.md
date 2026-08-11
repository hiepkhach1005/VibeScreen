# Feature parity matrix

This is the high-level feature matrix. For the function-level audit, legacy
symbols, native targets, status, and remaining checkboxes, see
[FUNCTION_PARITY_CHECKLIST.md](FUNCTION_PARITY_CHECKLIST.md).

`Mapped` means legacy behavior and intended macOS disposition are documented;
it does not mean the feature is implemented or accepted.

| Feature ID | Module | Legacy behavior | Legacy source/symbol | macOS mapping | Target source | Tests | Status | Notes/limitations |
|---|---|---|---|---|---|---|---|---|
| APP-001 | App | Start one interactive process and initialize services | `Program.MainAsync`, `RunApp` | Native SwiftUI app composition root | `macOS/ColorControlMac/App` | App launch smoke | Partial | SwiftUI app shell exists; build pending Mac |
| APP-002 | App | Prevent duplicate instance and bring existing window front | `Program` mutex, `EnumThreadWindows`, `MainForm.WndProc` | App lifecycle/window activation; no Win32 mutex | `AppLifecycleCoordinator` | Mac UI test | Mapped | Exact activation path pending |
| APP-003 | App | Start minimized/minimize to tray/minimize on close | `Config`, `MainForm_FormClosing`, `MainForm_Resize` | Menu bar app/window restoration settings | `Features/MenuBar`, `Features/Root` | UI tests | Partial | MenuBarExtra exists; native close policy pending |
| APP-004 | App | Save module/global settings during close/shutdown | `MainWorker`, `MainForm.GlobalSave`, `ServiceManager.Save` | Application termination coordinator + atomic store | `ColorControlCore/Persistence/NativeStore`, `App/AppContainer` | Store tests | Partial | Atomic snapshot and mutation saves exist; app termination wiring pending |
| APP-005 | App | Windows Service background execution | `Program.RunService`, `UseWindowsService` | User-session app + `SMAppService`/LaunchAgent if justified | `Platform/macOS/LoginItem` | Mac integration | Not applicable | Architecture replaces Windows service |
| CFG-001 | Settings | Load/save defaults and logging settings | `Program.LoadConfig`, `Config` | Versioned Application Support Codable store | `Domain/Settings`, `Infrastructure/Persistence` | Migration/unit | Mapped | Web/GPU/elevation fields removed |
| PRE-001 | Presets | Load JSON, backup, fallback to defaults | `ServiceBase.LoadPresets` | Versioned atomic store with backup | `Infrastructure/Persistence` | Golden/migration | Mapped | Exact schema audit pending |
| PRE-002 | Presets | Find preset by name or ID | `ServiceBase.GetPresetByIdOrName` | Typed repository lookup | `Domain/Presets` | Unit | Mapped | IDs become stable value type |
| PRE-003 | Presets | Apply preset and expose last-used/error | `ServiceBase.ApplyPreset`, `PresetApplied` | Actor/use-case executor with typed result | `ColorControlCore/Application/PresetExecutor`, `PresetDeviceActionRouter` | `PresetExecutionTests`, router tests | Partial | Native TV/WOL/display/app adapters exist; unsupported ColorSync and hardware paths remain |
| PRE-004 | Presets | Clone/delete/create preset | `ServiceBase`, `PresetBase` | Repository/use case with validation | `Domain/Presets`, `Features/MainWindowView` | Unit/UI | Partial | Native CRUD/editor exists; clone and validation polish pending |
| PRE-005 | Presets | Parse compact step syntax and delays/options | `PresetStep.Parse` | Import codec + typed action model | `ColorControlCore/Domain/PresetStepParser` | `PresetStepParserTests` | Partial | Parser handles parenthesized/simple actions and preserves unknown actions; Mac test run pending |
| PRE-006 | Automation | Trigger on startup | `LgService.PowerStateChanged`, `ServiceBase.ExecuteEventPresets` | App lifecycle event | `ColorControlCore/Application/AutomationCoordinator`, `MacPlatformEventSource` | Core tests/Mac | Partial | Startup signal and routing exist; real presets pending |
| PRE-007 | Automation | Trigger resume/standby/shutdown/monitor events | `PowerEventDispatcher`, service handlers | IOKit/NSWorkspace normalized events | `MacPlatformEventSource`, `TVPowerPolicyEngine` | Fake events/Mac | Partial | NSWorkspace signals/policy mapped; Mac build pending |
| PRE-008 | Automation | Trigger lock/unlock/session changes | `SessionSwitchDispatcher`, LG/Samsung handlers | NSWorkspace/session adapter | `MacPlatformEventSource`, `TVPowerPolicyEngine` | Fake events/Mac | Partial | Signals exist; device action wiring pending |
| PRE-009 | Automation | Trigger display changes | `DisplayChangeEventDispatcher`, service handlers | CoreGraphics display callback | `MacPlatformEventSource` | Fake/Mac | Partial | AppKit screen-change signal exists; CoreGraphics facts pending |
| PRE-010 | Automation | Trigger process switch/fullscreen/screensaver | `ProcessEventDispatcher`, `PresetTrigger.TriggerActive` | NSWorkspace/process adapter; unsupported conditions explicit | `Platform/macOS/ProcessMonitoring` | Unit/Mac | Mapped | Fullscreen/notification parity unresolved |
| PRE-011 | Shortcuts | Register preset/quick-access shortcuts | `ServiceBase.SetShortcuts`, `KeyboardShortcutDispatcher` | App commands or global event tap with permission | `Platform/macOS/GlobalHotkeys` | Parser/fake/Mac | Mapped | Permission required for global capture |
| LG-001 | LG | Discover/configure/select LG devices | `LgService.RefreshDevices`, `LgServiceConfig` | Bonjour/manual IP/MAC + actor repository | `Infrastructure/LGWebOS` | Fixture/integration | Mapped | Deep protocol audit pending |
| LG-002 | LG | Pair and persist client key | `LgTvApi`, `ClientKeyStore`, `LgTvConnectionCws` | Keychain credential store | `KeychainCredentialStore`, `TVDeviceClients` | Fixture/Keychain | Partial | Registration response polling and Keychain write exist; Mac pairing test pending |
| LG-003 | LG | Connect/reconnect/subscribe WebOS | `LgTvConnectionCws`, `LgTvApi` | Swift transport actor/state machine | `MacTVWebSocketTransport`, `TVDeviceClients`, `LGWebOSRequestFactory` | State/fixture | Partial | Registration and command transport exist; reconnect/subscription state machine pending |
| LG-004 | LG | WOL/power/screen on/off | `LgService`, `LgDevice`, `WolService` | UDP WOL + typed TV commands | `LGWebOSCommand`, `WakeOnLANPacket`, `TVPowerPolicyCoordinator` | Packet/policy | Partial | WOL sender/policy/commands exist; hardware evidence pending |
| LG-005 | LG | Remote/media/channel/volume/input/app actions | `LgTvApi`, `LgService` | Typed command capability | `TVDeviceClients`, `MacTVWebSocketTransport`, `LGWebOSCommand` | Codec/integration | Partial | Volume, mute, launch, and pointer-button flow exist; subscriptions/media/input coverage pending |
| LG-006 | LG | Custom remotes/game bar/presets | `LgService`, `LgRemotes.json`, `LgGameBar` | SwiftUI feature + domain presets | `Persistence/LegacyRemoteImporter`, `Features/MainWindowView` | UI/fixture | Partial | Remote definitions migrate; dedicated remote editor/game bar pending |
| SAM-001 | Samsung | Discover/configure/select Samsung devices | `SamsungService`, `SamsungServiceConfig` | Bonjour/manual IP/MAC + actor repository | `Infrastructure/SamsungTizen` | Fixture/integration | Mapped | Deep protocol audit pending |
| SAM-002 | Samsung | Pair/persist/refresh token | `SamsungDevice.ConnectAsync`, `SamsungService` | Keychain credential store | `KeychainCredentialStore`, `LegacyDeviceImporter`, `TVDeviceClients` | State/Keychain | Partial | Token redirect and connect event handling exist; Mac pairing flow pending |
| SAM-003 | Samsung | Secure/non-secure connect/reconnect | `SamTvConnection`, `SamsungDevice` | Swift transport actor/state machine | `MacTVWebSocketTransport`, `SamsungWebSocketEndpoint`, `TVDeviceClients` | Fixture/state | Partial | Endpoint and basic actor transport exist; reconnect/state machine pending |
| SAM-004 | Samsung | WOL/power/screen control | `SamsungDevice`, `WolService` | UDP WOL + typed commands | `SamsungRemoteCommand`, `WakeOnLANPacket`, `TVPowerPolicyCoordinator` | Packet/policy | Partial | WOL/policy/key-power path exists; screen-control capability and hardware pending |
| SAM-005 | Samsung | Keys/apps/custom remote/presets | `SamsungDevice`, `SamsungService` | Typed capabilities + SwiftUI | `TVDeviceClients`, `Persistence/LegacyRemoteImporter`, `Features/MainWindowView` | Codec/UI | Partial | Remote-key path and migration exist; dedicated remote/app UI pending |
| SAM-006 | Samsung | Service/hospitality/factory menu sequences | `SamsungDevice` advanced actions | Explicit dangerous action service with warnings | `Features/Devices/Samsung` | Fake/manual only | Mapped | Never default CI |
| GAME-001 | Game | Match external process and auto-apply preset | `GameService.ProcessChanged`, `GamePreset` | NSWorkspace/process stream + trigger evaluator | `MacPlatformEventSource`, `AutomationCoordinator`, `GameWorkflow` | Fake process tests | Partial | Process events and trigger routing exist; automatic game-preset selection remains |
| GAME-002 | Game | Launch executable with args/workdir/pre/post steps | `GameService.ExecutePreset` | `NSWorkspace`/`Process` + workflow executor | `Domain/Game`, `MacGameProcessLauncher` | `GameWorkflowTests` | Partial | Native workflow/launcher exists; Windows paths need user repair and Mac test |
| GAME-003 | Game | Elevation/affinity/priority/suspend/restart | `GameService`, `WinApiAdminService` | Public macOS support only; otherwise limitation | `Platform/macOS/ProcessMonitoring` | API review | Mapped | Windows-specific features not guaranteed |
| DISP-001 | Display | Enumerate displays and modes | `GraphicsService`, `CCD` | CoreGraphics | `MacDisplayService`, `MacDisplayControl` | Mac hardware | Partial | Snapshot/mode code exists; Mac verification required |
| DISP-002 | Display | Rotation/scaling/brightness/DDC | `GraphicsService` | CoreGraphics/IOKit/public hardware path | `Platform/macOS/Displays` | Hardware | Mapped | May be limited by macOS/hardware |
| DISP-003 | Color | Install/associate/default ICC profiles | `ColorProfileService`, `CCD` | ColorSync | `MacColorProfileService` | Mac/profile fixtures | Partial | ICC inventory/validation exists; association/default write requires verified public adapter |
| DISP-004 | Color | Generate/edit MHC2/ICC profiles | `MHC2Gen`, `LittleCms`, `ColorProfileService` | Native ColorSync and optional native LittleCMS | `Infrastructure/ColorProfiles` | Golden ICC | Mapped | `lcms2.dll` cannot be reused |
| WOL-001 | Network | Build/send magic packet across interfaces | `WolService` | UDP Network.framework/Foundation implementation | `WakeOnLANPacket`, `MacWakeOnLANSender` | `ProtocolAndWakeTests`, power/router tests | Partial | Packet and sender exist; interface discovery/retry policy pending |
| MIG-001 | Migration | Import settings/device/preset/game/remote JSON | `Program`, `ServiceBase`, service configs | Dry-run versioned importer | `LegacyMigrationCoordinator`, importers, `NativeStore` | Importer/store tests | Partial | All bounded JSON categories have dry-run importers; UI/file-selection and Mac run pending |
| MIG-002 | Migration | Move LG/Samsung secrets safely | client-key/token sources | Keychain | `KeychainCredentialStore` | Keychain fake/integration | Partial | Secret boundary exists; Mac Keychain test pending |
| SYS-001 | Logging | File log, update checks, diagnostics | `InitLogger`, `LoggingService`, `UpdateManager` | OSLog + signed update/release flow | `Infrastructure/Logging`, `Updates` | Unit/Mac | Mapped | Build/signing pending |
| WEB-001 | Web | Blazor UI/browser/server | `BlazorUiManager`, `ColorControl.UI` | None | None | None | Not applicable | User decision: remove web |
| GPU-001 | NVIDIA | NVIDIA controller and presets | `Services/NVIDIA`, `NvAPIWrapper` | None | None | None | Not applicable | User decision |
| GPU-002 | AMD | AMD controller and presets | `Services/AMD` | None | None | None | Not applicable | User decision |

## Status rule

`Mapped` means only documented intent. `Partial` means reachable Swift code
exists for a bounded slice but feature parity is not complete. A row becomes
`Implemented` only when the complete feature is reachable; `Tested` requires
relevant tests; `Accepted` requires parity review and documented limitations.
