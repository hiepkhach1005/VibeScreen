---
name: implement-macos-platform-services
description: Implement and verify ColorControl adapters for documented macOS APIs, including app and session lifecycle, sleep/wake and power assertions, screensaver and display events, CoreGraphics display control, ColorSync profiles, global shortcuts, process monitoring, Login Items or LaunchAgents, OSLog, permissions, and optional XPC boundaries. Use when replacing Win32, WMI, Windows Service, registry, Task Scheduler, named-pipe, display, hotkey, process, power, or privilege behavior under macOS/VibeScreen/Platform.
---

# Implement macOS Platform Services

Replace Windows integrations with narrow, testable adapters around public macOS APIs. Do not reproduce Windows Service or admin-process architecture unless the required macOS behavior proves it necessary.

## Required context

Read the source/parity row, architecture ADRs, and current deployment target. Load:

- `references/apple-api-map.md` before selecting a framework or API;
- `references/permission-matrix.md` before adding capabilities, entitlements, usage descriptions, global input, automation, or helper behavior.

Browse current official Apple documentation and inspect the installed stable SDK for availability. Treat the reference map as candidate routing, not proof that an API supports every legacy behavior.

## Workflow

1. Define the exact observable behavior and lifecycle from legacy evidence.
2. Identify the least-privileged documented macOS API and its availability, permission, sandbox, signing, and distribution implications.
3. Add a platform-neutral protocol in the owning core module if one does not exist.
4. Implement one adapter with explicit registration, event normalization, cancellation, cleanup, and typed errors.
5. Build a fake event source/service and deterministic tests before connecting the adapter to automation.
6. Test denial, unavailable API, sleep/wake, app termination, duplicate notifications, multiple displays, and resource cleanup.
7. Validate on a real Mac. Hardware-dependent display/power behavior cannot be accepted from mocks alone.
8. Update the platform API map, permission matrix, parity/limitations, ADR if needed, and progress log.

## Guardrails

- Use public documented APIs only.
- Prefer a user-session app and `SMAppService` Login Item. Add a LaunchAgent or XPC helper only with evidence and an ADR; require approval before a privileged helper.
- Do not make the whole app root, bypass signing, disable security checks, or depend on undocumented shell commands for core behavior.
- Event adapters emit normalized facts and never execute presets directly.
- Registration must have symmetric unregistration; power assertions and event taps must always be released.
- Explain optional permissions in context and keep unaffected features usable after denial.
- Separate API support from hardware support. Record model, connection type, and test environment for display/DDC/HDR claims.
- Do not claim build/runtime verification when working on Windows.

## Completion evidence

Require an official API link, availability and permission notes, protocol and fake, focused tests, real-Mac verification where applicable, resource-cleanup evidence, and updated parity/limitation documents.
