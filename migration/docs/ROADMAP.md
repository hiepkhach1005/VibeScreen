# Migration roadmap

## Phase 0 — Project intelligence

- [x] Repository reorganized and legacy source protected.
- [x] Master prompt, AGENTS, progress, decisions and NEXUS created.
- [x] Eight repository skills created and validated.
- [x] Initial lifecycle/core source map and parity matrix created.
- [ ] Complete LG/Samsung protocol, schema, UI and platform deep audits.
- [ ] Complete remaining architecture/security/test/ADR documents.

## Phase 1 — Native shell

- [x] Swift package/native executable target.
- [x] Main window and menu bar.
- [x] Composition root and OSLog categories (Mac build pending).
- [x] Settings/navigation skeleton.
- [x] Native preset CRUD/editor and adapter-backed preset flow.

## Phase 2 — Core and persistence

- [x] Versioned store and Keychain boundaries.
- [x] Legacy settings/preset/device/game/remote import dry run with stable IDs and warnings.
- [x] Preset/automation execution engine.
- [x] Core unit tests authored.
- [ ] Run tests and verify atomic rollback on macOS.

## Phase 3 — LG vertical slice

- [x] Transport/codec boundary, command builders, LG pointer remote, and Keychain boundary.
- [ ] WebOS registration/pairing/response actor.
- [ ] Pairing/Keychain/WOL.
- [ ] Basic command and preset.
- [ ] Reconnect/subscription tests.
- [ ] Hardware evidence.

## Phase 4 — Samsung vertical slice

- [ ] Secure/non-secure transport.
- [ ] Pairing/token/Keychain/WOL.
- [ ] Basic key/preset.
- [ ] Reconnect tests and hardware evidence.

## Phase 5 — Automation and game launcher

- [x] Native event adapters and TV power-policy coordinator.
- [ ] Shortcuts/global hotkeys.
- [x] `.app`/bundle ID launch and process waiting.
- [x] Pre/post/finalization workflows.
- [ ] Process-triggered game auto-apply.

## Phase 6 — Display and color

- [x] CoreGraphics display identity/events and mode adapter.
- [ ] ColorSync profile association/default-profile workflows.
- [ ] Native ICC/LittleCMS decision.
- [ ] Hardware-dependent limitations accepted.

## Phase 7 — Release

- [ ] Accessibility/visual QA.
- [ ] Security/privacy review.
- [ ] Universal build decision.
- [ ] Signing/notarization/update.
- [ ] Final parity audit.
