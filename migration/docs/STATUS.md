# Migration status

## As of 2026-08-11

- Phase: `1 — Native foundation and platform adapters`
- Current slice: Swift package, native core execution, migration coordinator,
  TV/WOL/power adapters, game/display adapters, and SwiftUI/MenuBarExtra shell
  are present.
- Native code: implemented foundation under `macOS/ColorControlMac/`; Mac build pending.
- macOS build: not verified.
- Legacy source: read-only and integrity-baselined.
- Repository skills: 8/8 validated.
- Feature matrix: rows now distinguish host-independent code from Mac/hardware evidence.

## Evidence completed

- `Program`, `MainWorker`, `MainForm`, `ServiceManager`, `ServiceBase`, module/config/startup contracts, preset contracts and core dispatchers inspected.
- LG/Samsung/Game/ColorProfile/Graphics/WOL/Update entry points and symbols inventoried.
- Windows/web/GPU boundaries identified.
- Swift core tests and protocol/migration fixtures were authored but cannot run
  in the current Windows environment because Swift/Xcode is unavailable.
- Native code now includes NSWorkspace/AppKit event normalization, TV power
  coordination, atomic schema-v2 store, Keychain boundary, LG/Samsung WebSocket
  clients, LG pointer-input remote transport, WOL sender, game launch/process
  adapter, display mode/profile inventory adapters, and migration importers.
- `legacy-windows/` remains unchanged against the recorded integrity baseline.

## Current risks

- Mac SDK and deployment target unavailable in current environment.
- Full protocol response state machines, exact JSON schemas for all services,
  remote UI inventory, and global shortcut scope still need audit.
- Display/HDR/DDC/ColorSync association, power/session behavior, and TV pairing
  cannot be accepted without Mac/hardware evidence.

## Next milestone

Move the package to a Mac build machine, run `swift test` and an Xcode app
build, then exercise the LG vertical slice behind the existing
transport/Keychain/core contracts. Keep hardware parity open until real TVs,
power events, display modes, ColorSync, and reconnect paths are tested.
