# Permission and capability matrix

Complete this matrix for each concrete feature. Verify wording, entitlement, sandbox, and distribution requirements against current Apple documentation.

| Capability | Typical trigger | User experience requirement | Failure behavior |
|---|---|---|---|
| Local Network | Discover or connect to TVs on LAN | Explain device discovery/control before request; provide manual address path | app opens; device feature shows actionable denied/unavailable state |
| Accessibility | Global control only when the selected implementation needs it | Request from the relevant settings/shortcut flow, not at first launch | local app shortcuts and unrelated features continue |
| Input Monitoring | Global keyboard event observation if required | Explain exactly which shortcut feature needs it | disable global capture; keep in-app commands |
| Automation/Apple Events | Control another app only when a scoped feature requires it | Name the target and action | that integration fails safely without blocking TV control |
| Notifications | User opts into automation/device notifications | Ask after explaining useful events | show in-app status/logs instead |
| Files/folders | Import legacy data, export logs, choose app/executable/profile | Use system picker and security-scoped access when needed | preserve current data and allow retry |
| Login Item | User enables start at login | Show current registration state and system-management path | app remains launchable manually |
| Keychain | Save pairing secret | Usually transparent; explain recovery/re-pair on failure | never fall back to plaintext secret storage |
| Privileged helper | Only an approved feature with no user-level alternative | Separate explicit installation/authorization flow and ADR | feature unavailable; app remains usable |

## Rules

- Delay optional permission prompts until the user invokes the dependent feature.
- Include usage descriptions that state the user-visible purpose, not generic framework language.
- Provide a settings diagnostics screen showing required, granted, denied, restricted, or unknown state without pretending macOS always exposes exact status.
- Link to the appropriate System Settings pane only through supported APIs.
- Do not repeatedly prompt after denial; provide instructions and a retry/check action.
- Never make optional permissions a prerequisite for opening the app.
- Record entitlement and sandbox changes in build/release documentation and test both sandboxed and intended distribution configurations.
