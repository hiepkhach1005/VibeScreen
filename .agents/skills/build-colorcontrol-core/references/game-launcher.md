# macOS game launcher mapping

## Supported identities

Model a launch target using one or more of:

- application bundle URL;
- bundle identifier;
- executable URL for a native Mach-O tool;
- display name only as non-authoritative metadata.

Do not rely solely on process name. Preserve security-scoped bookmarks when user-selected URLs must remain accessible in a sandboxed distribution.

## Launch plan

A plan may contain:

- target identity;
- arguments and environment allowed by policy;
- working directory for executable launches;
- pre-launch preset/steps;
- readiness condition or bounded delay;
- post-launch steps;
- termination/finalization steps;
- timeout, duplicate-instance, and failure policies.

Use an `AppLaunching` boundary. The platform adapter chooses `NSWorkspace` for application bundles and `Process` for direct executables when appropriate.

## Monitoring

- Prefer workspace launch/activation/termination notifications for app bundles.
- Use public process lifecycle APIs for direct child processes.
- Correlate by bundle identifier, process identifier, and resolved executable where available.
- Handle apps that spawn a helper and terminate the launcher process.
- Define whether external launches activate associated workflows.
- Remove observers and cancel monitors when configuration changes or the app exits.

## Windows-only behavior

Audit legacy elevation, CPU affinity, priority, suspension, and restart separately. Implement only with stable documented macOS APIs and a clear user value. Otherwise mark the parity row as an accepted limitation; never shell out to undocumented commands to imitate Windows behavior.

## Safety tests

Use fake launchers and lifecycle streams for unit tests. Integration tests should launch a harmless test fixture, never a real game or privileged tool. Verify duplicate launch, target missing, permission denial, child-process exit, timeout, cancellation, and finalization after failure.
