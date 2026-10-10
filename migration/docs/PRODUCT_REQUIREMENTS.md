# ColorControl macOS product requirements

## Product goal

Provide a native macOS control room for displays and smart TVs. The app must make device state, presets, and automation understandable at a glance while preserving the applicable behavior of the legacy Windows application.

## Product scope

### Required retained capabilities

- Native main window and macOS menu-bar controls.
- LG WebOS devices: discovery/manual setup, pairing, client-key storage, reconnect, WOL, power/screen control, remote keys, apps/inputs/media/volume where supported, picture/system actions, custom remotes, presets and triggers.
- Samsung Tizen devices: discovery/manual setup, pairing/token storage, reconnect, WOL, power/screen control, remote keys, apps where supported, custom remotes, advanced service actions with warnings, presets and triggers.
- Versioned presets and ordered steps with delays, retries, error policy, quick access, and global shortcuts where macOS permissions permit.
- Automation for startup, wake/resume, sleep, session lock/unlock, screensaver, display changes, process/application changes, and manual actions where documented macOS APIs support them.
- Native macOS application/game launching with pre-launch, post-launch, and finalization workflows.
- Display enumeration and public-API display controls where feasible.
- ColorSync profile listing, association, import/generation, and restore where public APIs and hardware permit.
- WOL, native logging, settings, update checks, permission diagnostics, and legacy-data import.
- Native Mac monitoring for public aggregate CPU/RAM utilization, network
  throughput, thermal pressure, and available power-source values. Hardware
  sensors without documented public APIs must remain explicitly unavailable.

### Explicitly excluded

- NVIDIA controller, NVIDIA presets, G-SYNC-specific behavior, NvAPI, and novideo_srgb integration.
- AMD controller, AMD presets, ADL, and AMD-specific behavior.
- Blazor, Razor, WebView, local web server, browser-hosted UI, and Windows-only UI settings.
- Windows Service, registry, WMI, named-pipe elevation, Task Scheduler, Win32 messages, GDI, DXVA, and Windows DLLs as implementation dependencies.

Excluded behavior must not remove shared preset, event, persistence, or navigation functionality needed by retained modules.

## UX requirements

- Open quickly to the main window or menu bar according to user preference.
- Show connection state with text and symbols; never rely on color alone.
- Keep frequent safe actions close to the menu bar and detailed configuration in the main window.
- Make pairing, permission denial, offline devices, unsupported capability, and migration conflicts actionable.
- Require explicit confirmation/opt-in for TV power-off, service/factory menus, shutdown, restart, or other destructive actions.
- Support light/dark appearance, keyboard navigation, VoiceOver, Reduce Motion, Reduce Transparency, and Increase Contrast.

## Data requirements

- Preserve user presets, step order, delays, trigger conditions, device associations, and custom remotes.
- Import from a user-selected legacy folder without modifying it.
- Store client keys/tokens in Keychain in production. Permit only an explicitly
  compiled local-debug plaintext file mode with `0600` files, visible warning,
  no synchronization/logging/fixtures, deletion, and migration back to
  Keychain.
- Make migration dry-run, backed up, atomic, idempotent, and recoverable.

## Technical requirements

- Swift 6 strict concurrency.
- SwiftUI first, AppKit only behind small platform boundaries.
- Public documented Apple APIs only.
- No mutable global service locator.
- Domain logic independent of SwiftUI/AppKit/network/storage.
- Network operations support timeout, cancellation, bounded retry, cleanup, and redacted logging.
- Every accepted feature links source evidence, implementation, and tests.

## Acceptance criteria

The product is not complete until the parity matrix contains no unaudited accepted-scope row, the native app builds on the supported Mac toolchain, migration is verified without data loss, retained device workflows have protocol/test evidence, and documented limitations are accepted by the project owner.
