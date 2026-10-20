# VibeScreen

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
- A native System Monitor for public CPU, memory, network, thermal-pressure,
  and power-source telemetry, with explicit unavailable states for private
  hardware sensors.

## Explicit exclusions

- .NET and C# runtime/application code.
- Blazor, WebView, and local web UI.
- NVIDIA and AMD modules.
- Private Apple APIs or undocumented system hacks.

## Current state

The native foundation is present as a Swift Package Manager project:

- `VibeScreenCore` contains typed preset models, target-aware legacy step
  parsing, actor-based execution with retry/cancellation, automation/power
  routing, schema-v2 persistence, migration importers, LG/Samsung codecs, and
  Wake-on-LAN contracts.
- `VibeScreen` contains SwiftUI/AppKit menu-bar and window UI, preset/device/game flows,
  AppKit/NSWorkspace events, production Keychain storage, an explicit
  owner-only local-development credential-file mode, WebSocket clients, LG pointer remote,
  Network.framework WOL, native app/process launch, display modes, and ICC
  inventory/validation boundaries.
- Branding is native: `VibeScreenMark.swift` draws the monochrome menu-bar
  mark, while `Resources/VibeScreenIcon.icns` is the packaged Dock/Finder
  artwork. Regenerate the artwork with `swift Scripts/render-app-icon.swift`
  followed by the documented `sips`/`iconutil` iconset step when the mark
  changes.
- `VibeScreen.entitlements` is the minimum sandbox profile for outgoing
  TV/WOL networking. Select it in the Xcode target when packaging the app;
  Swift Package Manager alone does not sign an executable with entitlements.
- Core tests cover parser compatibility, target mapping, execution ordering and
  retry policy, event matching, protocol message shapes, migration/store,
  Samsung endpoint construction, TV power coordination, and WOL.

The source is not yet a released hardware build. The SwiftPM development app
bundle builds with Xcode 27.0 / Swift 6.4 and is assembled by
`Scripts/build-dev-app.sh`; the current ad-hoc signed bundle was copied to
`$HOME/Documents/VibeScreen.app`. XCTest, Xcode archive,
distribution signing/notarization, ColorSync association, UI smoke, and
complete real-TV behavior remain acceptance gates.

Read `../../migration/PROGRESS.md` and `../../migration/MASTER_PROMPT.md` before
continuing the migration.
