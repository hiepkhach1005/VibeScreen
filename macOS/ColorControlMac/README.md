# ColorControlMac

Destination for the new native macOS application.

## Scope

- Swift 6.
- SwiftUI-first UI, with AppKit only where required.
- Native full application window and menu bar controls.
- LG WebOS and Samsung Tizen device control.
- Wake-on-LAN.
- Presets, steps, shortcuts, and event automation.
- macOS power, session, process, display, and screen-state integration using public APIs.
- Native game/application launcher.
- ColorSync-based color-profile support and public-API display controls where feasible.
- Native settings, logging, migration, accessibility, signing, and update flow.

## Explicit exclusions

- .NET and C# runtime/application code.
- Blazor, WebView, and local web UI.
- NVIDIA and AMD modules.
- Private Apple APIs or undocumented system hacks.

## Current state

The native foundation is present as a Swift Package Manager project:

- `ColorControlCore` contains typed preset models, target-aware legacy step
  parsing, actor-based execution with retry/cancellation, automation/power
  routing, schema-v2 persistence, migration importers, LG/Samsung codecs, and
  Wake-on-LAN contracts.
- `ColorControlMac` contains SwiftUI/MenuBarExtra UI, preset/device/game flows,
  AppKit/NSWorkspace events, Keychain, WebSocket clients, LG pointer remote,
  Network.framework WOL, native app/process launch, display modes, and ICC
  inventory/validation boundaries.
- `ColorControlMac.entitlements` is the minimum sandbox profile for outgoing
  TV/WOL networking. Select it in the Xcode target when packaging the app;
  Swift Package Manager alone does not sign an executable with entitlements.
- Core tests cover parser compatibility, target mapping, execution ordering and
  retry policy, event matching, protocol message shapes, migration/store,
  Samsung endpoint construction, TV power coordination, and WOL.

The source is not yet a released hardware build. Swift/Xcode is unavailable in
the current Windows environment, so the package, app bundle, Keychain pairing,
power events, ColorSync association, and real-TV behavior must be compiled and
tested on macOS before parity is accepted.

Read `../../migration/PROGRESS.md` and `../../migration/MASTER_PROMPT.md` before
continuing the migration.
