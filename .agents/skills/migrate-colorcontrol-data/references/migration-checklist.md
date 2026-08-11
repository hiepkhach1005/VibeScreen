# Data migration checklist

## Discovery

- [ ] Actual filenames and path logic traced from source.
- [ ] Serializer settings, enums, defaults, and null behavior recorded.
- [ ] Cross-file IDs and ordering semantics recorded.
- [ ] Secret fields and potential secrets in backups/logs identified.
- [ ] GPU/web/Windows-only fields classified.

## Fixtures

- [ ] Valid complete fixture.
- [ ] Empty and partial folders.
- [ ] Malformed JSON and wrong field types.
- [ ] Unknown fields and future version.
- [ ] Duplicate devices/presets/remotes.
- [ ] Missing client key/token and stale credential.
- [ ] GPU-only and unknown steps.
- [ ] Existing destination data and conflict cases.
- [ ] All fixtures are synthetic and redacted.

## Dry run

- [ ] Performs no Application Support or Keychain writes.
- [ ] Reports detected files and schema versions.
- [ ] Reports counts, transformations, warnings, conflicts, unsupported records, and secret moves.
- [ ] Allows user to cancel before commit.
- [ ] Shows Windows paths requiring app/profile reselection.

## Commit and recovery

- [ ] Destination backup created and verified.
- [ ] Stable deterministic ID mapping produced.
- [ ] Non-secret writes are atomic.
- [ ] Keychain writes use an injected store and privacy-safe errors.
- [ ] Commit verification rereads destination data.
- [ ] Failure path restores backup or produces recoverable state.
- [ ] Legacy input remains unchanged.
- [ ] Interrupted migration is safe to retry.

## Idempotency and tests

- [ ] First run produces expected native data.
- [ ] Second identical run creates no duplicate state.
- [ ] Conflict policy is deterministic.
- [ ] Rollback restores the exact prior destination state.
- [ ] No secret appears in persisted JSON, output reports, test snapshots, or logs.
- [ ] Migration version/provenance is recorded.
- [ ] Progress, schema map, parity matrix, and limitations are updated.
