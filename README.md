# ColorControl macOS rewrite workspace

This repository has been reorganized for a native macOS rewrite.

| Path | Purpose |
|---|---|
| `legacy-windows/` | Original Windows/.NET source, retained read-only as the behavioral reference |
| `macOS/ColorControlMac/` | Destination for the new Swift 6 and SwiftUI application |
| `migration/` | Master prompt, decisions, progress log, source maps, ADRs, and migration documentation |
| `AGENTS.md` | Persistent instructions for coding agents |

Start by reading [migration/PROGRESS.md](migration/PROGRESS.md), then [migration/MASTER_PROMPT.md](migration/MASTER_PROMPT.md).

The original project README is preserved at [legacy-windows/README.md](legacy-windows/README.md).

The native rewrite has started in `macOS/ColorControlMac/` as a Swift Package
Manager project. Its first slice contains the SwiftUI window, MenuBarExtra,
platform-neutral preset/automation core, LG/Samsung protocol boundaries, WOL
packet generation, and dry-run migration importers. Build/runtime verification
must be performed on macOS; see [migration/PROGRESS.md](migration/PROGRESS.md)
for the exact stopping point.
