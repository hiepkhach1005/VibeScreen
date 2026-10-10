# Known limitations and open platform risks

These are not silent feature drops. Each item requires evidence or a product decision before being marked accepted.

| Area | Limitation/risk | Current status |
|---|---|---|
| macOS build | SwiftPM debug/release builds and an ad-hoc development app bundle run on macOS; Xcode tests/signing/archive remain unavailable | Partial; full Xcode required |
| Liquid Glass | Exact modifier/API and minimum OS must match the stable SDK available on the Mac | Blocked until Mac SDK audit |
| Screensaver/screen wake events | `NSWorkspace.screensDidWakeNotification` reports only that screens woke and carries no cause. ColorControl now waits one second and requires a CoreGraphics current-session input event within five seconds before forwarding that wake to TV WOL/preset automation; this suppresses observed maintenance/Bluetooth phantom wakes but may require the shortcut for non-input wake methods such as some remote-unlock flows | Partial; real hardware/input matrix required |
| Global hotkeys | One editable first-TV power-toggle chord is registered exclusively through Carbon without Accessibility/Input Monitoring. The app reads LG WebOS/Samsung Tizen state when possible; after standby or an unavailable state it only attempts the safe PowerOn/Wake-on-LAN path and never guesses PowerOff. Exhaustive comparison with every macOS shortcut source and real-TV execution evidence remain pending | Partial; Mac UI/hardware test required |
| Display modes | CoreGraphics may not expose every Windows mode/topology/scaling behavior | Blocked |
| DDC/CI | External monitor and connection support may differ; no blanket parity claim | Blocked |
| HDR/MHC2 | ColorSync/public API and hardware support must be verified; native ICC generation may be needed | Blocked |
| Game elevation/affinity/suspend/priority | Windows-specific controls may have no public safe macOS equivalent | Mapped limitation |
| Process fullscreen/notification context | Legacy uses Windows foreground/fullscreen/notification state | Research required |
| System hardware sensors | Public APIs provide aggregate CPU/RAM/network, thermal pressure, startup-volume capacity, uptime, processor counts, and optional power-source values, but not CPU/GPU/RAM/SSD temperatures, SMART health, whole-system GPU utilization, or fan RPM. Monitor reports these as unavailable rather than using AppleSMC, IOReport, `powermetrics`, or undocumented registry keys | Accepted implementation constraint; blocked until a public API exists |
| Upstream monitor comparison | [Macs Fan Control](https://github.com/crystalidea/macs-fan-control) documents SMC-backed fan monitoring/control and a privileged helper in its product messages. [Stats](https://github.com/exelban/stats) lists GPU/disk/sensor/fan features and its source contains an AppleSMC reader plus a privileged SMC helper. Those paths are intentionally not copied into ColorControl because the native project permits documented public macOS APIs only | Audited 2026-08-16; no safe public replacement for SMC telemetry/control |
| Live power | IOKit may expose battery voltage/current and the adapter's rated watts depending on hardware. Battery flow is an explicit `abs(voltage × current)` estimate; adapter rating is not presented as live total-system consumption | Partial; portable-Mac and signed-sandbox tests pending |
| TV discovery | Bonjour/SSDP may not find every device; manual IP/MAC remains required | Mapped |
| LG/Samsung firmware | Protocol behavior varies by model/firmware and requires opt-in hardware tests | Mapped; hardware pending |
| LG secure WebSocket trust | Legacy accepted every TV certificate. Native first tries system trust, then requires explicit SHA-256 fingerprint confirmation and pins the leaf certificate to the exact configured host | Implemented for development testing; real-TV pairing and certificate-rotation behavior need hardware evidence |
| Update installer | Windows service installer cannot be reused; signed/notarized update strategy open | Blocked |
| Background operation | User-session app may not provide Windows-Service behavior without a user login | Architecture decision accepted; exact scope pending |
| Login startup presentation | Login-item launches are implemented as menu-bar-only using Apple's launch-event marker and accessory activation policy. A real logout/login test is still required to verify timing and ensure the SwiftUI window never flashes on the target Mac | Partial; Mac login smoke test required |
