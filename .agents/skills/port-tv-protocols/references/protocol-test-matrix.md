# TV protocol test matrix

## Codec fixtures

- [ ] Registration/pairing request encoding.
- [ ] Normal command request encoding.
- [ ] Success response decoding and request correlation.
- [ ] Error response decoding.
- [ ] Subscription/event decoding.
- [ ] Unknown fields and unknown event types.
- [ ] Malformed, truncated, and wrong-type JSON.
- [ ] Fixture redaction verified.

## Connection state

- [ ] Connect success and explicit disconnect.
- [ ] DNS/address failure and timeout.
- [ ] Pairing accepted, rejected, cancelled, and timed out.
- [ ] Stored credential accepted and invalidated.
- [ ] Disconnect with pending requests.
- [ ] Bounded reconnect and backoff cancellation.
- [ ] Duplicate connect/disconnect calls are idempotent.
- [ ] App termination cleans sockets, tasks, timers, and continuations.
- [ ] One device failure does not affect another connection actor.

## Requests and subscriptions

- [ ] Unique request IDs under concurrency.
- [ ] Out-of-order responses.
- [ ] Duplicate response/event.
- [ ] Request timeout and caller cancellation.
- [ ] Subscription restore after reconnect where intended.
- [ ] Slow consumer/backpressure policy.
- [ ] Capability unavailable versus transport failure.

## WOL/discovery

- [ ] Correct magic packet from normalized MAC.
- [ ] Invalid MAC rejected.
- [ ] Multiple interfaces/broadcast destinations handled as designed.
- [ ] Discovery timeout and cancellation.
- [ ] Duplicate discoveries merged by stable identity.
- [ ] Manual device setup works without discovery.

## Safety and privacy

- [ ] Logs contain no token/client key/authorization payload.
- [ ] TLS/trust behavior follows the approved security decision.
- [ ] Power-off and service/factory actions excluded from default automated tests.
- [ ] Real-device tests require explicit opt-in and external secret/config input.

## Evidence level

Classify each parity row as codec-tested, state-machine-tested, integration-tested, hardware-verified, or accepted limitation. Unit tests alone do not prove TV firmware compatibility.
