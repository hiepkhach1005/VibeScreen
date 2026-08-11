# macOS platform API map

Status: candidate mappings from source audit; exact availability and behavior must be verified on the Mac build machine.

| Legacy behavior | Candidate macOS API | New boundary | Verification needed | Status |
|---|---|---|---|---|
| App/menu icon | SwiftUI `MenuBarExtra`, fallback AppKit `NSStatusItem` | `MenuBarController` | deployment target, popover/window lifecycle | Mapped |
| Main window/activation | SwiftUI scenes + `NSApplication`/AppKit bridge | `AppLifecycleCoordinator` | duplicate activation and restoration | Mapped |
| Startup/background | ServiceManagement `SMAppService` Login Item; LaunchAgent only if justified | `LoginItemController` | user approval, signing/sandbox | Mapped |
| Sleep/wake | IOKit power notifications + applicable workspace notifications | `PowerEventSource` | exact event and cleanup semantics | Mapped |
| Prevent sleep during operation | IOKit power assertions | `SleepAssertion` | assertion lifetime, reason, cancellation | Mapped |
| Session lock/unlock | `NSWorkspace`/session notifications as documented | `SessionEventSource` | event availability/user-session scope | Mapped |
| Screensaver | public workspace/distributed notification or supported command | `ScreenSaverEventSource` | API availability; otherwise limitation | Blocked |
| Display configuration | CoreGraphics display reconfiguration callback | `DisplayEventSource` | callback threading, IDs, duplicate events | Mapped |
| Display modes | CoreGraphics display APIs | `DisplayControl` | mode/mirroring/virtual display support | Blocked |
| ICC profiles | ColorSync | `ColorProfileStore` | install/association scope and sandbox | Mapped |
| HDR/MHC2 | ColorSync/public APIs plus native profile generator | `ColorProfileControl` | exact tag/API/hardware parity | Blocked |
| DDC/CI/brightness | public CoreGraphics/IOKit path only if documented | `DisplayControl` | external monitor/connection hardware | Blocked |
| Global hotkeys | app commands; event tap only with required permission | `GlobalShortcutSource` | Accessibility/Input Monitoring and secure input | Mapped |
| App/process events | `NSWorkspace`, `NSRunningApplication`, Foundation `Process` | `ProcessEventSource`, `AppLauncher` | bundle/helper correlation and sandbox | Mapped |
| LG/Samsung discovery | Network.framework, Bonjour/mDNS, manual IP/MAC | `DeviceDiscovery` | Local Network permission and TV behavior | Mapped |
| WebSocket protocols | URLSession/WebSocket APIs or approved transport | `TVTransport` | pairing/trust/cancellation | Mapped |
| WOL | UDP socket/Network.framework | `WakeOnLAN` | interfaces/broadcast and packet evidence | Mapped |
| Credentials | Security framework Keychain | `CredentialStore` | migration, access groups, reinstall | Mapped |
| Logs | OSLog | `AppLogger` | privacy redaction and export strategy | Mapped |
| Notifications | UserNotifications, opt-in | `UserNotificationClient` | authorization and safe actions | Mapped |
| Shortcuts | App Intents/URL scheme/app commands | `AutomationIntentProvider` | deployment target and destructive confirmation | Mapped |
| Updates | signed/notarized app distribution; evaluate Sparkle separately | `UpdateService` | signing, feed integrity, rollback | Blocked |

## Official references to verify on Mac

- `https://developer.apple.com/documentation/swiftui/menubarextra`
- `https://developer.apple.com/documentation/appkit/nsstatusitem`
- `https://developer.apple.com/documentation/servicemanagement/smappservice`
- `https://developer.apple.com/documentation/appkit/nsworkspace`
- `https://developer.apple.com/documentation/iokit`
- `https://developer.apple.com/documentation/colorsync`
- `https://developer.apple.com/documentation/coregraphics/cgdisplayreconfigurationcallback`
- `https://developer.apple.com/documentation/swiftui/glass`

Record SDK availability declarations, exact API choices, entitlements, permission wording, and real-Mac evidence here after verification. A candidate API is not an accepted parity implementation.
