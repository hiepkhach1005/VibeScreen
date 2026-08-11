# Known limitations and open platform risks

These are not silent feature drops. Each item requires evidence or a product decision before being marked accepted.

| Area | Limitation/risk | Current status |
|---|---|---|
| macOS build | Current environment is Windows; no Swift/Xcode/macOS runtime verification yet | Blocked until Mac |
| Liquid Glass | Exact modifier/API and minimum OS must match the stable SDK available on the Mac | Blocked until Mac SDK audit |
| Screensaver events | Public event coverage may not match Windows screensaver detection | Blocked |
| Global hotkeys | May require Accessibility/Input Monitoring and can be affected by secure input | Mapped; Mac test required |
| Display modes | CoreGraphics may not expose every Windows mode/topology/scaling behavior | Blocked |
| DDC/CI | External monitor and connection support may differ; no blanket parity claim | Blocked |
| HDR/MHC2 | ColorSync/public API and hardware support must be verified; native ICC generation may be needed | Blocked |
| Game elevation/affinity/suspend/priority | Windows-specific controls may have no public safe macOS equivalent | Mapped limitation |
| Process fullscreen/notification context | Legacy uses Windows foreground/fullscreen/notification state | Research required |
| TV discovery | Bonjour/SSDP may not find every device; manual IP/MAC remains required | Mapped |
| LG/Samsung firmware | Protocol behavior varies by model/firmware and requires opt-in hardware tests | Mapped; hardware pending |
| Update installer | Windows service installer cannot be reused; signed/notarized update strategy open | Blocked |
| Background operation | User-session app may not provide Windows-Service behavior without a user login | Architecture decision accepted; exact scope pending |
