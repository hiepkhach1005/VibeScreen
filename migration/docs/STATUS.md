# Migration status

## As of 2026-09-29

- Phase: `1 — Native foundation and platform adapters`
- Current slice: Swift package, native core execution, migration coordinator,
  TV/WOL/power adapters, game/display adapters, and SwiftUI/AppKit menu-bar shell
  are present.
- Native code: implemented foundation under `macOS/VibeScreen/`, including
  a dynamic Devices sidebar tree, inline device details, and a public-API
  System Monitor with a persisted sampling interval.
- macOS build: the SwiftPM development app bundle built with Xcode 27.0 / Swift
  6.4 and was replaced at `$HOME/Documents/VibeScreen.app`;
  strict signature verification and binary hash comparison passed. Menu-bar
  click UI smoke, XCTest, Xcode archive, distribution signing, and hardware
  checks remain open.
- Legacy source: read-only and integrity-baselined.
- Repository skills: 8/8 validated.
- Feature matrix: rows now distinguish host-independent code from Mac/hardware evidence.

## Evidence completed

- `Program`, `MainWorker`, `MainForm`, `ServiceManager`, `ServiceBase`, module/config/startup contracts, preset contracts and core dispatchers inspected.
- LG/Samsung/Game/ColorProfile/Graphics/WOL/Update entry points and symbols inventoried.
- Windows/web/GPU boundaries identified.
- Swift core tests and protocol/migration fixtures are present. They were not
  run in this work session.
- Native code now includes NSWorkspace/AppKit event normalization, TV power
  coordination, atomic schema-v2 store, Keychain boundary, LG/Samsung WebSocket
  clients, LG pointer-input remote transport, WOL sender, game launch/process
  adapter, display mode/profile inventory adapters, migration importers, and
  actor-isolated Mach/BSD/Foundation/IOKit system telemetry.
- `legacy-windows/` remains unchanged against the recorded integrity baseline.

## Current risks

- XCTest, Xcode archive/distribution signing, and packaged-app UI smoke remain
  unverified on the current Xcode 27.0 toolchain.
- Full protocol response state machines, exact JSON schemas for all services,
  remote UI inventory, and global shortcut scope still need audit.
- Display/HDR/DDC/ColorSync association, power/session behavior, and TV pairing
  cannot be accepted without Mac/hardware evidence.

## Next milestone

Manually verify the replacement app's menu-bar-only startup and explicit Open
action. Then run the authorized XCTest/Xcode packaging gates and continue the
LG vertical slice behind the existing transport/credential-store/core
contracts. Keep hardware parity open until real TVs, power events, display
modes, ColorSync, and reconnect paths are tested.
