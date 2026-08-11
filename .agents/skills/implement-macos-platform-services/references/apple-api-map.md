# Apple API routing map

This is a research index, not an assurance of feature parity. Verify availability and behavior in the installed stable SDK and current official documentation before coding.

| Need | Candidate public APIs/frameworks | Required investigation |
|---|---|---|
| Menu-bar presence | SwiftUI `MenuBarExtra`; AppKit `NSStatusItem` | scene lifetime, window opening, Dock policy, deployment target |
| App launch/termination/session events | `NSApplication`, `NSWorkspace` and notification centers | exact notification availability and delivery timing |
| System sleep/wake | IOKit power-management notifications; selected workspace notifications | acknowledgement requirements, user-session limitations, cleanup |
| Prevent sleep | IOKit power assertions | assertion type, reason text, timeout/release policy |
| Login Item/background registration | ServiceManagement `SMAppService` | app/helper type, user approval UI, sandbox/distribution implications |
| Display reconfiguration | CoreGraphics display reconfiguration callbacks | callback threading, duplicate/coalesced events, display identity |
| Display enumeration/modes | CoreGraphics display APIs | mode flags, mirroring, virtual/sidecar displays, permission/OS limits |
| Color profiles | ColorSync APIs | install scope, association/default behavior, sandbox/write permissions |
| Brightness/DDC/HDR | public CoreGraphics/IOKit/ColorSync capabilities where documented | hardware/connection support; do not assume parity |
| Global input/hotkeys | app commands where app-focused; public event-tap/shortcut approaches where global | Accessibility/Input Monitoring, secure-input behavior, cancellation |
| Process/app monitoring | `NSWorkspace` running-app notifications, `NSRunningApplication`, `Process` | external launch correlation, helper processes, sandbox limitations |
| Launch `.app` | `NSWorkspace` open configuration | arguments, activation, duplicate instances, result semantics |
| Launch executable | Foundation `Process` | executable access, working directory, environment, lifecycle |
| Discovery/network | Network.framework, Bonjour APIs, URLSession/WebSocket APIs, BSD UDP where justified | local-network privacy, interfaces, multicast/broadcast behavior |
| Secrets | Security framework / Keychain Services | access group, migration, update/reinstall behavior, redaction |
| Logs | OSLog | privacy interpolation, store/query/export approach |
| User notifications | UserNotifications | authorization, foreground behavior, action safety |
| Shortcuts/automation | App Intents, URL schemes, application commands | deployment target, destructive action confirmation, headless lifecycle |
| IPC/isolation | XPC services | need, code signing, protocol versioning, crash boundary |
| Update | signed/notarized app flow; evaluate Sparkle separately | distribution channel, signature verification, sandbox, user choice |

## Official starting points

- Liquid Glass overview: `https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass`
- SwiftUI glass APIs: `https://developer.apple.com/documentation/swiftui/glass`
- MenuBarExtra: `https://developer.apple.com/documentation/swiftui/menubarextra`
- NSStatusItem: `https://developer.apple.com/documentation/appkit/nsstatusitem`
- NSWorkspace: `https://developer.apple.com/documentation/appkit/nsworkspace`
- SMAppService: `https://developer.apple.com/documentation/servicemanagement/smappservice`
- IOKit: `https://developer.apple.com/documentation/iokit`
- ColorSync: `https://developer.apple.com/documentation/colorsync`
- CoreGraphics display callback: `https://developer.apple.com/documentation/coregraphics/cgdisplayreconfigurationcallback`

Record the exact page, SDK declaration, availability annotation, and test evidence in `migration/docs/PLATFORM_API_MAP.md`; do not rely only on this skill reference.

## Adapter checklist

- Protocol boundary and normalized values defined.
- Thread/executor delivery documented.
- Start/stop are idempotent.
- Registration/unregistration are symmetrical.
- App termination and sleep cleanup tested.
- Permissions and denied-state behavior tested.
- Unsupported OS/hardware path produces a typed capability error.
- No private symbol, undocumented selector, or shell fallback introduced.
