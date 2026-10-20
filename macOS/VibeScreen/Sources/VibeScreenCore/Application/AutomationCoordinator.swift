import Foundation

/// Routes typed platform events to matching presets. This is the native
/// counterpart of the legacy event-dispatcher fan-out and remains independent
/// from AppKit so it can be tested on every host.
public actor AutomationCoordinator {
    private let repository: any PresetRepository
    private let executionCoordinator: PresetExecutionCoordinator

    public init(
        repository: any PresetRepository,
        executionCoordinator: PresetExecutionCoordinator
    ) {
        self.repository = repository
        self.executionCoordinator = executionCoordinator
    }

    public func handle(
        _ event: AutomationEvent,
        context: AutomationEventContext,
        policy: PresetExecutionPolicy = PresetExecutionPolicy()
    ) async -> [PresetExecutionResult] {
        guard let presets = try? await repository.all() else { return [] }

        var results: [PresetExecutionResult] = []
        for preset in presets {
            let matches = preset.triggers.contains { trigger in
                trigger.matches(event: event, context: context)
            }
            guard matches else { continue }

            let result = await executionCoordinator.execute(preset, policy: policy)
            results.append(result)
        }
        return results
    }
}
