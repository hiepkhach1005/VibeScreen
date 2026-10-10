# Native macOS architecture

## Architecture decision

Use Swift 6 with SwiftUI-first presentation, selective AppKit bridges, a
platform-neutral domain/application core, and protocol/OS adapters behind
explicit interfaces.

```text
SwiftUI/AppKit features
          |
          v
Application use cases / presentation models
          |
          v
Domain models / trigger evaluator / preset executor
          |
   protocols for effects
    /          |          \
 LG/Samsung  storage     macOS platform
 transport   Keychain    power/display/process/login
```

## Target layout

```text
macOS/ColorControlMac/
  Package.swift
  Sources/
    ColorControlCore/
      Domain/
      Application/
      Persistence/
      Protocols/
      Platform/
    ColorControlMac/
      App/
      Features/
      Platform/
      Resources/
  Tests/
    ColorControlCoreTests/
```

The package keeps pure core tests independent from AppKit. On a Mac build
machine, open `Package.swift` in Xcode and create or verify the native app
scheme. Convert to a committed `.xcodeproj` only if signing, helper,
asset-catalog, or target configuration requires it; record that decision in an
ADR.

## Module boundaries

- `ColorControlCore.Domain`: models and pure rules; no SwiftUI/AppKit/network/file imports.
- `ColorControlCore.Application`: preset execution, event routing, repositories, power coordination, and effect protocols.
- `ColorControlMac.App`: composition root and lifecycle.
- `ColorControlMac.Features`: SwiftUI screens and presentation state.
- `ColorControlMac.Platform`: public macOS adapters for power/session/display/process/login and TV transport.
- `ColorControlMac.Infrastructure`: future release/update boundaries; production
  secrets remain in Keychain, with a compile-time local-debug file adapter.

## Concurrency

- UI and platform objects: `@MainActor`.
- Per-device socket and mutable connection state: actors.
- Preset/game execution: actor coordinators with cancellation and typed results.
- Event source: normalized `AsyncStream<PlatformSignal>`.
- Persistence: actor-backed versioned store with atomic writes and backup.

## Implemented native foundation

1. A SwiftUI `Window` scene hidden during accessory startup, a public AppKit
   `NSStatusItem`/`NSPopover` shell with both-button activation, Settings, and
   the Liquid Glass availability path.
2. Domain preset/step models, target-aware legacy parser, actor executor, retry/cancellation, and result reporting.
3. In-memory repository plus schema-v2 Application Support store and backup.
4. Automation routing and normalized NSWorkspace/AppKit power/session/display/process events.
5. TV protocol codecs, credential references and adapters, LG/Samsung WebSocket clients, LG pointer remote, WOL sender, and TV power-policy coordinator.
6. Native game launcher, display snapshots/modes, ICC inventory/validation, login-item adapter, and migration importers.

This is a bounded native foundation, not an accepted hardware release. LG and
Samsung live pairing/reconnects, ColorSync association, global shortcuts, full
remote UI, process-triggered game auto-apply, and hardware parity still
require Mac build and device evidence.

## Design constraints

- No C# class-by-class translation.
- No web server, browser, WebView, Electron, Tauri, MAUI, or Avalonia.
- No NVIDIA/AMD concept in new core models.
- No private Apple API or undocumented system hack.
- No domain-level UI popup, process object, JSON dictionary, or framework type.
- No mutable global service container.
