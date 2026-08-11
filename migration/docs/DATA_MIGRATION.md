# Legacy data migration design

## Source data discovered

The legacy application writes data below its Windows application-data directory, with service-level files including:

- `Settings.json`
- `LgConfig.json`, `LgPresets.json`, `LgRemotes.json`
- per-device LG client-key files such as `<ip>_ClientKey.txt`
- `SamsungConfig.json`, `SamsungPresets.json`, `SamsungRemotes.json`
- Samsung pairing token on device/config DTOs
- `GameConfig.json`, `GamePresets.json`
- profile metadata and backup files
- `LogFile*.txt`

Exact fields and serializer behavior remain an audit task. Do not implement a destructive direct decoder until each schema is evidenced from source.

## Native destination

- Durable non-secret data: `Application Support/ColorControl` versioned store.
- Secrets: Keychain records keyed by product, device kind, stable device identity, and credential kind.
- Cache/discovery: Caches, never source of truth.
- Logs: OSLog; legacy logs are not imported by default.
- User-selected app/profile URLs: bookmark or security-scoped URL strategy after sandbox/distribution decision.

## Migration pipeline

```text
select legacy folder
        |
discover files and versions
        |
decode legacy transport models
        |
normalize IDs, defaults, paths, steps and triggers
        |
dry-run report / conflicts / unsupported actions
        |
backup native destination
        |
atomic non-secret commit + Keychain secret commit
        |
verify and record provenance
```

## Transformations

- Remove Windows UI, web, NVIDIA, AMD, elevation, registry, WMI, and Task Scheduler settings from active native configuration.
- Preserve unsupported or unknown preset actions as disabled migration records requiring user repair; do not silently delete them.
- Preserve order, delay, trigger, quick-access and device relationships.
- Convert LG client keys and Samsung tokens to Keychain; never copy them to native JSON.
- Convert Windows `.exe` game paths to unresolved native targets with a user reselect step.
- Keep display/profile names as provenance; re-resolve macOS display IDs by stable metadata when possible.

## Safety requirements

- User chooses the folder; legacy input is never modified.
- Dry run performs no writes.
- Existing native data is backed up before commit.
- Writes are atomic and idempotent.
- Repeated imports do not duplicate devices/presets/remotes.
- Malformed/future data produces a report, not a crash or data loss.
- Secret migration failures never fall back to plaintext.
