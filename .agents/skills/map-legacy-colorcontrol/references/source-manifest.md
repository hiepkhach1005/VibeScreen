# Legacy source audit manifest

All paths are relative to `legacy-windows/`. Resolve related files and call sites rather than limiting the audit to this seed list.

## Lifecycle and shared behavior

- `README.md`, `ColorControl.slnx`, relevant `.csproj` files.
- `ColorControl/Program.cs`, `MainWorker.cs`, `MainForm.cs`, `CommandLineHandler.cs`.
- `ColorControl/Services/Common/ServiceManager.cs`, `NotifyIconManager.cs`, `OptionsService.cs`, `UpdateManager.cs`, `LoggingService.cs`, `ElevationService.cs`.
- `Shared/Contracts/StartUpParams.cs`, `Module.cs`, `Config.cs`.
- `ColorControl/Services/Common/ServiceBase.cs`, `IServiceBase.cs`.
- `Shared/Contracts/Presets/PresetBase.cs`, `Shared/Contracts/PresetStep.cs`.
- all `Shared/EventDispatcher/` files.

## Windows boundaries

- `Shared/Native/WinApi.cs`, `CCD.cs`, `DXWrapper.cs`.
- `Shared/Services/WinApiService.cs`, `WinApiAdminService.cs`, `WinElevatedProcessManager.cs`, `RpcClientService.cs`, `RpcServerService.cs`.
- `Shared/Common/PipeUtils.cs` and relevant helpers in `Shared/Common/Utils.cs`.

Search for Windows Service, Win32 messages, WMI, registry, named pipes, Task Scheduler, elevation, power/session/display notifications, HDR, DDC/CI, hotkeys, and screensaver handling.

## LG WebOS

- all `ColorControl/Services/LG/` and `ColorControl/LgTv/` files;
- LG remote-control classes and UI panels/pages;
- `ColorControl/Resources/LG_register.json`;
- `ColorControl/Resources/LG_register_legacy.json`;
- `ColorControl/Resources/LgRemotes.json`;
- `ColorControl/LgPresets.json` when present.

## Samsung Tizen

- all `ColorControl/Services/Samsung/` files;
- Samsung UI panels/pages;
- `ColorControl/Resources/SamsungRemotes.json`;
- `ColorControl/SamsungPresets.json` when present.

## Game launcher

- all `ColorControl/Services/GameLauncher/` files;
- all `Shared/Contracts/Game/` files;
- every process/helper call site and old Game UI.

## Displays and color profiles

- `ColorControl/Services/Common/GraphicsService.cs`;
- `ColorControl/Services/Common/ColorProfileService.cs`;
- relevant `Shared/Contracts/Display*` and profile contracts;
- all relevant `MHC2Gen/` and `LittleCms/` files.

## WOL and discovery

- `Shared/Services/WolService.cs`;
- discovery and network-interface paths in `Shared/Common/Utils.cs`;
- all WMI, ARP, route, IP, and MAC address call sites.

## UI feature inventory

- layout and applicable LG, Samsung, Game, ColorProfile, RemoteControl, Generic, Options, Logging, and Info pages under `ColorControl.UI/`;
- equivalent WinForms/WPF panels, Designer files, and resources when needed to identify options, labels, grouping, or hidden actions.

## Persistence searches

Find all reads/writes for `Settings.json`, `LgConfig.json`, `LgPresets.json`, `LgRemotes.json`, client-key text files, `SamsungConfig.json`, `SamsungPresets.json`, `SamsungRemotes.json`, pairing tokens, `GameConfig.json`, `GamePresets.json`, backups, logs, and profile metadata.

## GPU exclusion searches

Across non-GPU directories, search:

```text
NVIDIA|AMD|NvPreset|AmdPreset|Gsync|NvService|AmdService|novideo|GPU
```

Record coupling but do not port GPU implementations.

## Audit record

For each selected file, record path, symbols read, call sites followed, behavior found, associated feature IDs, unresolved questions, and audit date/environment.
