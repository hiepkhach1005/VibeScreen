# ColorControl macOS Rewrite Instructions

## Required reading

Before making any change, read these files in order:

1. `migration/PROGRESS.md`
2. `migration/MASTER_PROMPT.md`
3. `migration/DECISIONS.md`
4. `macOS/VibeScreen/README.md`

Continue from the `Current stopping point` recorded in `migration/PROGRESS.md`. Do not restart completed work unless verification shows it is incorrect.

## Repository boundaries

- `legacy-windows/` is the read-only source of truth for legacy behavior. Do not modify, format, rename, or delete its contents.
- All new native application code belongs under `macOS/VibeScreen/`.
- Migration plans, maps, ADRs, reports, and handoff notes belong under `migration/` until the native project creates its own `docs/` tree.
- Keep the repository root limited to shared metadata and navigation files.

## Product constraints

- Rewrite the application as native Swift 6 with SwiftUI and AppKit only where needed.
- Do not add .NET, C#, Blazor, WebView, Electron, Tauri, MAUI, or Avalonia to the macOS application.
- Do not migrate NVIDIA or AMD modules, models, UI, commands, or dependencies.
- Preserve and verify all applicable LG WebOS, Samsung Tizen, Wake-on-LAN, presets, automation, power/session/display events, game launcher, display, and color-profile behavior.
- Use documented public Apple APIs. Record unsupported parity explicitly; never hide it behind private APIs or fragile shell commands.
- Store secrets in Keychain by default and for all production builds.
- For local development only, allow an explicitly enabled credential file under the user's Application Support directory.
- The credential file must use owner-only permissions (`0600`), must never be committed, synchronized, logged, included in fixtures, or stored inside the repository.
- Clearly warn the user that file-based credential storage is less secure and provide a way to delete or migrate it back to Keychain.

## Repository skills

Use the smallest applicable set and read each triggered `SKILL.md` completely:

- `map-legacy-colorcontrol` for legacy behavior discovery and source/parity maps.
- `build-colorcontrol-core` for domain, presets, automation, and game workflows.
- `build-macos-liquid-glass-ui` for native SwiftUI/AppKit layout and visual QA.
- `port-tv-protocols` for LG WebOS, Samsung Tizen, discovery, WOL, and connection state.
- `implement-macos-platform-services` for public macOS system APIs and permissions.
- `migrate-colorcontrol-data` for legacy import, native storage, and Keychain migration.
- `enforce-swift-quality` for implementation, test, security, and release gates.
- `verify-feature-parity` before closing a feature, phase, beta, or release.

## Continuity rule

After every meaningful work session, update `migration/PROGRESS.md` with:

- completed work and evidence;
- files created or changed;
- commands/tests run and their results;
- unresolved issues and decisions;
- the exact next safe step;
- the current date and environment.

On Windows, source analysis and documentation are allowed, but do not claim macOS build or runtime verification. Build, UI inspection, signing, notarization, ColorSync, power, and hardware checks must be performed on macOS with Xcode.
