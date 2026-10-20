import Foundation

public protocol PresetActionExecutor: Sendable {
    func execute(_ action: PresetStepAction) async throws
}

public protocol PresetClock: Sendable {
    func sleep(for milliseconds: Int) async throws
}

public struct SystemPresetClock: PresetClock {
    public init() {}

    public func sleep(for milliseconds: Int) async throws {
        guard milliseconds >= 0 else {
            throw VibeScreenCoreError.invalidDelay
        }

        let (nanoseconds, overflowed) = UInt64(milliseconds).multipliedReportingOverflow(by: 1_000_000)
        guard !overflowed else {
            throw VibeScreenCoreError.invalidDelay
        }

        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

/// Executes a preset with injected platform actions and time. The coordinator
/// is device-agnostic; LG, Samsung, display, power, and process adapters are
/// supplied later through `PresetActionExecutor` implementations.
public actor PresetExecutionCoordinator {
    private let actionExecutor: any PresetActionExecutor
    private let clock: any PresetClock

    public init(
        actionExecutor: any PresetActionExecutor,
        clock: any PresetClock = SystemPresetClock()
    ) {
        self.actionExecutor = actionExecutor
        self.clock = clock
    }

    public func execute(
        _ preset: Preset,
        policy: PresetExecutionPolicy = PresetExecutionPolicy()
    ) async -> PresetExecutionResult {
        guard !preset.steps.isEmpty else {
            return PresetExecutionResult(
                presetID: preset.id,
                status: .failed,
                steps: [
                    PresetStepResult(
                        id: UUID(),
                        action: .legacy(name: "preset", value: nil),
                        succeeded: false,
                        failure: PresetStepFailure(
                            message: VibeScreenCoreError.emptyPreset.localizedDescription
                        )
                    )
                ]
            )
        }

        var results: [PresetStepResult] = []

        for step in preset.steps {
            if Task.isCancelled {
                return PresetExecutionResult(
                    presetID: preset.id,
                    status: .cancelled,
                    steps: results
                )
            }

            do {
                try await clock.sleep(for: step.delayMilliseconds)
                let action = effectiveAction(for: step, preset: preset)
                try await executeWithRetry(action, retryCount: policy.retryCount)
                results.append(
                    PresetStepResult(id: step.id, action: action, succeeded: true)
                )
            } catch is CancellationError {
                return PresetExecutionResult(
                    presetID: preset.id,
                    status: .cancelled,
                    steps: results
                )
            } catch {
                let failure = PresetStepFailure(message: error.localizedDescription)
                let action = effectiveAction(for: step, preset: preset)
                results.append(
                    PresetStepResult(
                        id: step.id,
                        action: action,
                        succeeded: false,
                        failure: failure
                    )
                )

                if !policy.continueAfterFailure {
                    return PresetExecutionResult(
                        presetID: preset.id,
                        status: .failed,
                        steps: results
                    )
                }
            }
        }

        let status: PresetExecutionStatus = results.allSatisfy(\.succeeded) ? .succeeded : .failed
        return PresetExecutionResult(presetID: preset.id, status: status, steps: results)
    }

    private func effectiveAction(for step: PresetStep, preset: Preset) -> PresetStepAction {
        guard let target = preset.targetDeviceAddress?.trimmingCharacters(in: .whitespacesAndNewlines),
              !target.isEmpty else {
            return step.action
        }

        // Legacy preset files store the target once at preset level. Convert
        // only legacy actions here so the native router can select exactly
        // that TV without changing the persisted step syntax.
        guard case .legacy = step.action else { return step.action }
        return .deviceCommand(target: target, command: step.updatedRawValue)
    }

    private func executeWithRetry(
        _ action: PresetStepAction,
        retryCount: Int
    ) async throws {
        var attempts = 0

        while true {
            do {
                try await actionExecutor.execute(action)
                return
            } catch {
                guard attempts < retryCount else { throw error }
                attempts += 1
            }
        }
    }
}
