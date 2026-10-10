# macOS platform API map

Status: candidate mappings from source audit; exact availability and behavior must be verified on the Mac build machine.

| Legacy behavior | Candidate macOS API | New boundary | Verification needed | Status |
|---|---|---|---|---|
| App/menu icon | Public AppKit `NSStatusItem` and `NSStatusBarButton`, `NSClickGestureRecognizer` for secondary click, and transient `NSPopover` hosting SwiftUI content | `ColorControlApplicationDelegate`, `MenuBarStatusItemController`, `MenuBarView`, `ColorControlIcon.icns` | left/right click behavior, icon rendering, hover/VoiceOver discoverability, and popover lifecycle | Partial |
| Main window/activation | SwiftUI `Window` scene, `OpenWindowAction`, and `NSApplication` activation bridge; the scene remains hidden until menu-bar Open | `ColorControlApplicationDelegate`, `MainWindowSceneRoot`, `MainWindowView` | duplicate activation, reopen-after-close, resizing, toolbar, and startup/no-window smoke | Partial |
| Startup/background | ServiceManagement `SMAppService.mainApp` plus the public `keyAELaunchedAsLogInItem` parameter on `kAEOpenApplication`; Settings distinguishes disabled, enabled, approval-required, and unavailable states, links to the system Login Items pane, and login launches switch `NSApplication` to `.accessory` with the SwiftUI main window hidden | `LoginItemManager`, `SettingsView`, `ColorControlApplicationDelegate` | real logout/login launch, user approval/revocation, signing/sandbox, and no-window-flash smoke test | Partial |
| Sleep/wake | `NSWorkspace` sleep/wake and screen notifications; `CGEventSource.secondsSinceLastEventType` validates recent current-session user input before a screen-wake fact can trigger TV WOL | `MacPlatformEventSource`, `ScreenWakeUserIntentPolicy` | real mouse/keyboard wake, Bluetooth phantom-HID/DarkWake suppression, event ordering, and cleanup | Partial |
| Prevent sleep during operation | IOKit power assertions | `SleepAssertion` | assertion lifetime, reason, cancellation | Mapped |
| Session lock/unlock | `NSWorkspace`/session notifications as documented | `SessionEventSource` | event availability/user-session scope | Mapped |
| Screensaver | public workspace/distributed notification or supported command | `ScreenSaverEventSource` | API availability; otherwise limitation | Blocked |
| Display configuration | CoreGraphics display reconfiguration callback | `DisplayEventSource` | callback threading, IDs, duplicate events | Mapped |
| Display modes | CoreGraphics display APIs | `DisplayControl` | mode/mirroring/virtual display support | Blocked |
| ICC profiles | ColorSync | `ColorProfileStore` | install/association scope and sandbox | Mapped |
| HDR/MHC2 | ColorSync/public APIs plus native profile generator | `ColorProfileControl` | exact tag/API/hardware parity | Blocked |
| DDC/CI/brightness | public CoreGraphics/IOKit path only if documented | `DisplayControl` | external monitor/connection hardware | Blocked |
| Global hotkeys | Carbon `RegisterEventHotKey` for user-recorded modified chords; local AppKit key events while the Settings recorder has focus | `GlobalKeyboardShortcut`, `ShortcutRecorderControl`, `MacGlobalTVShortcutManager` | conflict behavior and target-Mac smoke test | Partial |
| App/process events | `NSWorkspace`, `NSRunningApplication`, Foundation `Process` | `ProcessEventSource`, `AppLauncher` | bundle/helper correlation and sandbox | Mapped |
| Live system monitor | Mach `host_statistics`/`host_statistics64`, BSD `getifaddrs`, Foundation `ProcessInfo` (thermal state, processor counts, uptime, physical memory), `URLResourceValues` (startup-volume capacity), IOKit power-source APIs | `SystemMonitorSampling`, `MacSystemMonitorSampler` | signed-sandbox behavior, portable battery keys, multi-interface rate checks, external-volume semantics | Partial |
| Hardware temperatures, SMART health, whole-system GPU load, fan RPM/control | No documented public application API; do not use AppleSMC/IOReport/private keys or privileged SMC helpers | explicit unavailable values in `SystemMonitorSnapshot` | revisit only if Apple publishes an API | Blocked |
| LG/Samsung discovery | Network.framework, Bonjour/mDNS, manual IP/MAC | `DeviceDiscovery` | Local Network permission and TV behavior | Mapped |
| WebSocket protocols | URLSession/WebSocket APIs or approved transport | `TVTransport` | pairing/trust/cancellation | Mapped |
| WOL | UDP socket/Network.framework | `WakeOnLAN` | interfaces/broadcast and packet evidence | Mapped |
| Credentials | Security framework Keychain | `CredentialStore` | migration, access groups, reinstall | Mapped |
| Logs | OSLog plus a bounded owner-only JSONL power diagnostic (`PowerDiagnostics.jsonl` + one rotated predecessor) under Application Support | `ColorControlLogger`, `MacPowerDiagnosticRecorder` | user-facing reveal/export UI and signed-build retrieval smoke | Partial |
| Notifications | UserNotifications, opt-in | `UserNotificationClient` | authorization and safe actions | Mapped |
| Shortcuts | App Intents/URL scheme/app commands | `AutomationIntentProvider` | deployment target and destructive confirmation | Mapped |
| Updates | signed/notarized app distribution; evaluate Sparkle separately | `UpdateService` | signing, feed integrity, rollback | Blocked |

## Official references to verify on Mac

- `https://developer.apple.com/documentation/swiftui/menubarextra`
- `https://developer.apple.com/documentation/swiftui/menubarextrastyle/window`
- `https://developer.apple.com/documentation/appkit/nsresponder/keydown(with:)`
- `https://developer.apple.com/documentation/appkit/nsstatusitem`
- `https://developer.apple.com/documentation/servicemanagement/smappservice`
- `https://developer.apple.com/documentation/servicemanagement/smappservice/status-swift.enum`
- `https://developer.apple.com/documentation/servicemanagement/smappservice/opensystemsettingsloginitems()`
- `https://developer.apple.com/documentation/coreservices/keyaelaunchedasloginitem`
- `https://developer.apple.com/documentation/appkit/nsworkspace`
- `https://developer.apple.com/documentation/iokit`
- `https://developer.apple.com/documentation/iokit/1523867-iopsgetpowersourcedescription`
- `https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.property`
- `https://developer.apple.com/documentation/colorsync`
- `https://developer.apple.com/documentation/coregraphics/cgdisplayreconfigurationcallback`
- `https://developer.apple.com/documentation/swiftui/glass`

Record SDK availability declarations, exact API choices, entitlements, permission wording, and real-Mac evidence here after verification. A candidate API is not an accepted parity implementation.

The editable first-TV power-toggle shortcut uses the public Carbon hot-key
registration API available in the installed macOS SDK. Settings captures the
replacement only from ordinary key events delivered to the focused app. The
implementation does not install an event tap or global event monitor, so it
does not request Accessibility or Input Monitoring permission. Registration is
exclusive; an occupied chord fails visibly and the last working binding is
restored. Invocation reads the TV's current power state before selecting
PowerOn/Wake-on-LAN or PowerOff.
