# Migration decisions

This file records decisions already made with the project owner. A future coding session must not reverse them silently.

## Accepted direction

| ID | Decision | Status |
|---|---|---|
| DEC-001 | Rewrite the application instead of attempting an in-place .NET port. | Accepted |
| DEC-002 | Use Swift 6, SwiftUI, and AppKit only where SwiftUI is insufficient. | Accepted |
| DEC-003 | Remove the Blazor/web UI and do not embed a browser or local web server. | Accepted |
| DEC-004 | Remove NVIDIA and AMD functionality from the macOS product. | Accepted |
| DEC-005 | Provide both a native application window and macOS menu bar controls. | Accepted |
| DEC-006 | Follow the current macOS visual language and Liquid Glass using system components and public APIs. | Accepted |
| DEC-007 | Replace Windows services and event integrations with appropriate macOS user-session services, Login Items, LaunchAgents, NSWorkspace, IOKit, CoreGraphics, and ColorSync. | Accepted in principle; exact API mapping requires audit |
| DEC-008 | Preserve all applicable non-GPU behavior, including LG, Samsung, WOL, presets, automation, power events, game launching, display controls, and color profiles. | Accepted |
| DEC-009 | Preserve the legacy source in `legacy-windows/` as read-only until feature parity is accepted. | Accepted |
| DEC-010 | Write all new application code under `macOS/ColorControlMac/`. | Accepted |

## Decisions still required later

- Final product name and bundle identifier.
- Minimum supported macOS version, after checking the stable SDK and Liquid Glass availability.
- Apple Developer team, signing identity, distribution channel, and update mechanism.
- Whether Intel `x86_64` builds are required in addition to Apple Silicon `arm64`.
- Whether a LaunchAgent or helper is actually necessary after user-session automation is prototyped.
- Which display/HDR/DDC functions are supportable using public APIs on the target hardware.
