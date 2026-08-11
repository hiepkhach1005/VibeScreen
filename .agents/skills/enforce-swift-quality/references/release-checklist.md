# macOS release checklist

Run on a Mac with the intended stable Xcode, credentials, entitlements, and distribution configuration.

## Product identity

- [ ] Product name and bundle identifier finalized.
- [ ] Semantic version and build number set reproducibly.
- [ ] Minimum macOS version and supported architectures documented.
- [ ] App category, copyright, licenses, acknowledgements, and privacy information complete.
- [ ] App icon and asset catalog validated at required sizes.

## Build configuration

- [ ] Debug-only flags, sample data, test endpoints, and verbose secret-adjacent logging excluded.
- [ ] Release optimization and Swift strict-concurrency settings verified.
- [ ] Entitlements and usage descriptions match actual features.
- [ ] Sandboxing choice and distribution channel agree with platform features.
- [ ] Third-party packages are pinned/reviewed and licenses included.

## Functional gates

- [ ] Full unit and required UI suites pass.
- [ ] Migration golden/idempotency/rollback suites pass.
- [ ] Menu bar, Login Item, permissions, offline operation, sleep/wake, and app relaunch smoke-tested.
- [ ] Approved LG/Samsung hardware matrix completed or gaps documented.
- [ ] Display/ColorSync features tested on declared hardware or limited explicitly.
- [ ] Destructive actions and first-run safeguards manually reviewed.

## Signing and packaging

- [ ] Archive created from a clean checkout/worktree state.
- [ ] Correct Developer ID/App Store identity and team used.
- [ ] Nested helpers/frameworks/packages signed consistently.
- [ ] Hardened Runtime and required entitlements validated.
- [ ] Architecture slices inspected.
- [ ] Gatekeeper assessment performed on the packaged artifact.

## Notarization and updates

- [ ] Notarization submitted and accepted for intended distribution.
- [ ] Ticket stapled where applicable and verified on a separate/clean Mac.
- [ ] Update metadata/feed is signed and uses the approved channel.
- [ ] Upgrade preserves data and Keychain access.
- [ ] Failed/interrupted update recovery documented.

## Final evidence

- [ ] Feature matrix contains no `Not audited` accepted-scope rows.
- [ ] Known limitations and release notes match the artifact.
- [ ] Security/privacy and dependency reviews complete.
- [ ] Build commands, Xcode/macOS versions, archive identifier, test results, and unresolved credential-only steps recorded.
