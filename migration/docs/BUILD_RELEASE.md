# Build and release plan

## Current state

No macOS build has been run. The current environment is Windows. Build/signing/notarization evidence must be collected on a Mac with stable Xcode.

## Development build

- Open `macOS/ColorControlMac/Package.swift` in Xcode after it is scaffolded.
- Use `macOS/ColorControlMac/ColorControlMac.entitlements` as the starting
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
- Real-Mac menu bar, Login Item, permission, sleep/wake, display and profile smoke tests.
- Opt-in hardware matrix for LG/Samsung and external displays.
- Known limitations/release notes match actual artifact.
