# Legacy data schema map

This is a discovery template. Confirm every field/default from source before treating it as authoritative.

| Legacy data | Expected source name/location | Secret? | Native destination | Audit focus |
|---|---|---:|---|---|
| Global settings | `Settings.json` | No | versioned Application Support store | startup, UI, logging, update, service/web/GPU-only options |
| LG service config | `LgConfig.json` | No | device/settings store | selected device, IP/MAC, options, delays, power/event behavior |
| LG presets | `LgPresets.json` | No | preset store | stable IDs, order, steps, triggers, quick access, hotkeys |
| LG remotes | `LgRemotes.json` and bundled resource | No | custom/bundled remote model | layout, keys, labels, delay/hold behavior |
| LG client key | `<ip>_ClientKey.txt` or audited equivalent | Yes | Keychain | address-to-device mapping, stale/re-pair behavior |
| Samsung service config | `SamsungConfig.json` | Mixed | device/settings store plus Keychain | token placement, selected device, delays/options |
| Samsung presets | `SamsungPresets.json` | No | preset store | IDs, order, steps, triggers, quick access, hotkeys |
| Samsung remotes | `SamsungRemotes.json` and bundled resource | No | custom/bundled remote model | key names, layout, advanced actions |
| Samsung pairing token | field/file found by audit | Yes | Keychain | device identity, invalidation, duplicate devices |
| Game config | `GameConfig.json` | No | game settings store | process scanning/detection and Windows-only options |
| Game presets | `GamePresets.json` | No | game workflow store | executable/path mapping, args, workdir, pre/post/final steps |
| Color/profile metadata | source-discovered files/settings | Usually no | profile metadata store | file URLs/bookmarks, display association, unsupported tags |
| Backups | `*.backup` or source-derived naming | Could contain secrets | import source only after warning | precedence, recency, duplicate detection |
| Logs | `LogFile*.txt` or source-derived naming | May contain sensitive data | not imported by default | optional user export only; redact before diagnostics |

## Required field evidence

For each schema, record in `migration/docs/DATA_MIGRATION.md`:

- serializer and options, including case/enums/null/default handling;
- root type and version marker if any;
- required/optional fields and defaults;
- stable ID and cross-file references;
- ordering semantics;
- secret fields;
- obsolete web, Windows service, NVIDIA, and AMD fields;
- malformed/unknown-field behavior;
- write path and backup behavior;
- target model and semantic transformation.

## Native storage boundaries

- Non-secret durable data: versioned Codable representation or selected native store under Application Support.
- Pairing credentials: Keychain behind `CredentialStore`.
- User-selected app/profile/file URLs: security-scoped bookmarks when required by distribution/sandbox design.
- Cache/discovery results: Caches, never migration source of truth.
- Logs: OSLog; do not migrate old logs automatically.

## Legacy action disposition

Classify every preset step and trigger as:

- directly mapped;
- mapped with semantic change;
- requires user repair, such as Windows executable path;
- intentionally unsupported NVIDIA/AMD/web/Windows-only action;
- unknown and preserved for reporting.

Never drop an unknown action while still reporting the preset as fully migrated.
