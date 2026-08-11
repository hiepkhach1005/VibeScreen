# Preset and automation engine contract

## Model

A normalized implementation should distinguish:

- `Preset`: stable ID, name, ordering/quick-access metadata, ordered steps.
- `PresetStep`: action kind, target, parameters, delay, timeout, retry/error behavior, destructive classification.
- `Trigger`: normalized event type plus conditions and enabled state.
- `AutomationRule`: trigger-to-preset association and conflict policy.
- `Execution`: run ID, origin, timestamps, cancellation state, and step results.
- `ExecutionResult`: succeeded, partially succeeded, failed, cancelled, or skipped with reasons.

Do not preserve GPU-specific step or condition variants. Unknown imported legacy steps must survive migration as explicit unsupported records until the user resolves them; do not execute them.

## Execution sequence

1. Validate the preset and resolve targets without side effects.
2. Check destructive-action policy and required permissions.
3. Create one execution scope and log a redacted start event.
4. For each ordered step:
   - check cancellation;
   - apply pre-step delay through an injectable clock;
   - execute with timeout;
   - apply bounded retry only to classified transient failures;
   - record one immutable result;
   - continue or stop according to explicit error policy.
5. Publish final aggregate state and persist safe history.
6. Release assertions, subscriptions, and temporary resources even on failure/cancellation.

## Event normalization

Map platform-specific notifications into stable events such as:

- app started;
- system will sleep / did wake;
- session locked / unlocked;
- screensaver started / stopped;
- display configuration changed;
- display slept / woke when publicly detectable;
- process/application launched / terminated / activated;
- global shortcut invoked.

An event adapter emits facts. A trigger evaluator matches rules. An execution coordinator applies conflict policy. Keep these responsibilities separate.

## Conflict and repetition policy

Define and test:

- debounce window for noisy events;
- whether the same preset coalesces, queues, restarts, or is ignored while running;
- priority between manual and automatic executions;
- cancellation on sleep, logout, app termination, or target loss;
- recovery after app relaunch;
- behavior when only some target devices are reachable.

Never infer these policies silently from task scheduling behavior.

## Required tests

- stable ordering and delays;
- validation without side effects;
- timeout and retry exhaustion;
- continue/stop error policies;
- cancellation before, during, and after a step;
- duplicate/noisy event handling;
- manual versus automatic conflict;
- partial target availability;
- unsupported migrated step;
- resource cleanup and final result publication.
