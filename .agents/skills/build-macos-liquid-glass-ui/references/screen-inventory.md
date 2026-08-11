# Native screen inventory

Use this inventory as the minimum planning surface. Link every row to feature-parity IDs before implementation.

| Surface | Primary job | Required states |
|---|---|---|
| Menu bar | Inspect current state and run frequent safe actions | no devices, connecting, online, partial offline, automation running, update available |
| Dashboard | Understand system/device status and recent automation | empty, loading, healthy, warnings, permission blocked |
| Devices | Discover, add, pair, rename, select, and remove TVs | scanning, none found, manual entry, pairing, trust warning, offline, error |
| LG detail | Inspect connection and run LG capabilities | capability unavailable, reconnecting, command progress/failure |
| LG remote | Send grouped remote/media/input commands | disconnected, key hold, custom layout, dangerous service action |
| Samsung detail | Inspect connection and run Samsung capabilities | token missing/invalid, reconnecting, capability unavailable |
| Samsung remote | Send keys, apps, screen, and service actions | disconnected, key delay/hold, custom layout, warning |
| Presets | Browse, create, duplicate, reorder, and apply presets | empty, dirty, applying, partial failure, validation error |
| Preset editor | Edit ordered steps, delays, targets, and policy | invalid step, missing device, unsupported migrated action |
| Automation | Configure triggers and inspect executions | permission missing, trigger unavailable, disabled, running, failed |
| Game launcher | Associate and launch macOS apps with workflows | app missing, already running, launch failure, finalizing |
| Displays | Inspect displays and supported controls | display disconnected, unsupported API/hardware, permission failure |
| Color profiles | List, import, generate, associate, and restore profiles | invalid ICC, write failure, unsupported metadata, confirmation |
| Migration assistant | Select legacy folder, preview, import, and roll back | no data, malformed data, conflicts, dry-run warnings, success |
| Settings | Configure startup, behavior, permissions, logs, and updates | managed/disabled option, permission denied, restart required |
| Logs | Filter, inspect, copy, and export redacted diagnostics | empty, live updates paused, export error |
| About/update | Show version, licenses, update state, and release action | checking, current, available, failed |

## Navigation ownership

- Put persistent destinations in the main-window sidebar.
- Put feature-scoped configuration in a detail view or inspector.
- Use a sheet for short, reversible setup flows and confirmation.
- Use a separate window only when the task benefits from independent persistence, such as logs or a remote; document the reason.
- Keep menu-bar destinations shallow: status, quick presets, safe device actions, open app, settings, quit.

## State requirement

For each implemented surface, record:

- authoritative state owner;
- async loading and cancellation behavior;
- empty/offline/error copy;
- permission dependency;
- destructive confirmation;
- keyboard commands and focus order;
- accessibility labels/values;
- preview fixture;
- UI test identifiers.
