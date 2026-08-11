# Migration tasks

## Phase 0 — Source and platform audit

- [ ] Read full `LgTvApi.cs`, connection, service and related contracts; record message/state maps.
- [ ] Read full Samsung transport/device/service and record message/state maps.
- [ ] Read full Game service/preset and classify macOS mappings.
- [ ] Read full ColorProfile/Graphics/MHC2/LittleCms boundaries and create API questions.
- [ ] Enumerate all legacy config read/write paths and create redacted fixtures.
- [ ] Inventory old UI actions/fields into screen inventory and parity rows.
- [ ] Verify Apple API availability on Mac.

## Phase 1 — Native shell/core

- [x] Create `Package.swift` and native targets.
- [x] Add domain models and compact step parser.
- [x] Add actor-based preset executor and deterministic tests.
- [x] Add SwiftUI main window/menu bar with safe demo action.
- [x] Add core automation routing and Mac event-source boundary.
- [x] Add composition root and OSLog categories; Mac build/runtime verification remains.

## Phase 2+ — Retained features

- [x] Versioned persistence and Keychain boundary.
- [x] Migration dry-run importers for settings, LG/Samsung presets/devices, game presets, and remotes.
- [x] LG/Samsung request/endpoint codecs and generic WebSocket transport boundary.
- [x] WOL packet generation and Network.framework sender.
- [x] NSWorkspace/AppKit platform event adapter and TV power-policy coordinator.
- [x] Native `.app`/bundle-ID game launcher and pre/post/finalize workflow.
- [x] CoreGraphics display mode adapter and ICC inventory/validation boundary.
- [x] LG pointer-input remote transport and Samsung remote-key command path.
- [ ] Complete LG transport/handshake/actor and pairing flow.
- [ ] Complete Samsung transport/token/actor and pairing flow.
- [ ] Add WOL interface discovery/retry policy.
- [ ] Wire process-triggered game auto-apply.
- [ ] Complete ColorSync profile association and display capability UI.
- [ ] Accessibility/visual QA.
- [ ] Signing/notarization/update.

## Definition of done per task

- [x] Relevant skill read and used.
- [x] Source/parity row linked.
- [x] Implementation and tests added where host-independent.
- [ ] Failure/cancellation/cleanup considered.
- [ ] Security/privacy reviewed.
- [ ] Docs and `migration/PROGRESS.md` updated.
