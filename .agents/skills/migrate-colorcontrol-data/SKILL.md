---
name: migrate-colorcontrol-data
description: Design, implement, and verify non-destructive migration of legacy ColorControl Windows data into versioned macOS Application Support storage and Keychain secrets. Use for legacy JSON schema discovery, import assistants, dry-run previews, conflict resolution, stable-ID mapping, custom remotes, presets, device configuration, LG client keys, Samsung tokens, backups, rollback, atomic writes, migration fixtures, or persistence-version changes.
---

# Migrate ColorControl Data

Treat migration as an auditable transaction, not a collection of ad hoc decoders. Preserve user intent and data while isolating unsupported GPU/web records and secrets.

## Required context

Read persistence call sites and current source/parity maps. Load:

- `references/legacy-schema-map.md` before creating decoders or fixtures;
- `references/migration-checklist.md` before changing import execution or marking migration complete.

Use `map-legacy-colorcontrol` when a schema/default/write path remains unclear. Use the platform skill for Keychain and file-picker/security-scoped URL behavior.

## Workflow

1. Discover actual filenames, serializers, defaults, enum values, backup behavior, secret locations, and cross-file references from source.
2. Create redacted golden fixtures for valid, partial, malformed, duplicate, old, and unknown/future data.
3. Decode into legacy transport models that preserve unknown/unsupported records; never decode directly into current domain models.
4. Normalize and validate without side effects. Produce a dry-run report containing imports, warnings, conflicts, unsupported items, and secret actions.
5. Build a deterministic migration plan with stable ID mapping and explicit conflict policy.
6. Back up existing native data, write non-secret data atomically, then place secrets in Keychain through an injected interface.
7. Verify the committed state; on failure, roll back or produce a recoverable partial-commit report without deleting legacy input.
8. Re-run the same import and prove idempotency.
9. Update schema maps, data-migration documentation, parity rows, tests, and progress.

## Invariants

- Never modify or delete the user-selected legacy folder.
- Never store client keys or pairing tokens in new JSON, logs, analytics, crash text, or fixtures.
- Preserve preset/step order, delays, trigger associations, device relationships, and custom remotes.
- Make unknown GPU-only actions visible as intentionally unsupported; do not execute or silently discard them.
- Separate parsing, normalization, planning, committing, and verification so dry run performs no writes.
- Make atomic writes and backups explicit; do not overwrite durable data in place.
- Preserve enough provenance to explain where each imported item came from.
- A migration version runs at most once per destination state but remains safe if interrupted and retried.

## Completion evidence

Require schema evidence, redacted fixtures, dry-run and rollback tests, idempotency proof, Keychain verification, no plaintext secrets, and updated migration/progress documentation.
