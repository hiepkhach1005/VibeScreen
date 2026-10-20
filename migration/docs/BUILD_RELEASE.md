# Build and release plan

## Current state

Xcode 27.0 (27A266a) and Swift 6.4 are selected on macOS 27.0/arm64. On
2026-09-30, `Scripts/build-dev-app.sh` rebuilt the SwiftPM development app bundle
and replaced `$HOME/Documents/VibeScreen.app`. The latest strict
code-sign verification passed; installed executable SHA-256 is
`c09b4a62bc4e0f639f704b2d7df1e87e8dc1f3a082c6c133d19ed62c542d3778`. The
replaced bundle is retained at
`$HOME/Documents/.VibeScreen-replace-autodismiss-20260930/VibeScreen.previous.app`.
Launch Services startup smoke confirmed it stays alive as a menu-bar app with
no main window. Left/right-click popover activation and Open-window behavior
were previously confirmed. The latest build closes the popover on activation
of another app, but updated-build UI verification remains pending because an
unrelated Gatekeeper dialog blocked accessibility interaction. XCTest, Xcode
archive, distribution signing, entitlements, and notarization remain
unverified.

`Scripts/build-dev-app.sh` assembles the SwiftPM binary into a development
`VibeScreen.app` with the committed bundle identifier and Local Network
usage description. The script explicitly compiles the debug-only
`COLORCONTROL_DEVELOPMENT_FILE_CREDENTIALS` mode, which stores newly paired TV
credentials in owner-only plaintext files under Application Support and avoids
Keychain access during local hardware work. It uses ad-hoc signing and never
queries a signing identity from Keychain. File mode also never reads or deletes
an older Keychain TV credential, so the TV must be approved once when no file
exists. A normal debug build and every release build use Keychain; reconnecting
with one of those builds moves a development-file credential back and deletes
the file. This remains a local hardware-test artifact, not a substitute for an
Xcode archive, Developer ID signature, or notarization.

## Development build

- Open `macOS/VibeScreen/Package.swift` in Xcode after it is scaffolded.
- Use `macOS/VibeScreen/VibeScreen.entitlements` as the starting
  target entitlement file; keep Local Network usage text in `Resources/Info.plist`
  and verify the final signed app's sandbox/network behavior.
- Select the documented deployment target and architecture.
- Run core unit tests first, then the macOS app/UI targets.
- Treat Swift 6 concurrency warnings as design issues.
- Record commands, Xcode/macOS/Swift versions and results in `migration/PROGRESS.md`.

## Distribution decisions still open

- Bundle ID and Apple Developer team.
- Minimum macOS version and whether arm64/x86_64 universal support is required.
- App Sandbox/distribution channel, Local Network usage text, Keychain access group, and optional Accessibility/Input Monitoring permissions.
- Direct signed/notarized distribution versus Mac App Store.
- Sparkle or another signed update mechanism versus opening a release page.

## Release gates

- Clean release archive.
- Correct signing, hardened runtime and entitlements.
- Gatekeeper assessment.
- Notarization acceptance and ticket verification.
- Migration upgrade test preserving Application Support and Keychain.
- Verify release compilation cannot select development-file credential mode.
- Real-Mac menu bar, Login Item, permission, sleep/wake, display and profile smoke tests.
- Opt-in hardware matrix for LG/Samsung and external displays.
- Known limitations/release notes match actual artifact.
