import XCTest
@testable import ColorControlCore

final class PresetExecutionTests: XCTestCase {
    func testExecutesStepsInOrder() async {
        let recorder = RecordingActionExecutor()
        let coordinator = PresetExecutionCoordinator(
            actionExecutor: recorder,
            clock: ImmediatePresetClock()
        )
        let first = PresetStepAction.deviceCommand(target: "lg", command: "powerOn")
        let second = PresetStepAction.deviceCommand(target: "samsung", command: "volumeUp")
        let preset = Preset(name: "Order", steps: [makeStep(first), makeStep(second)])

        let result = await coordinator.execute(preset)
        let recordedActions = await recorder.actions()

        XCTAssertEqual(result.status, .succeeded)
        XCTAssertEqual(recordedActions, [first, second])
    }

    func testRetriesAnActionBeforeFailing() async {
        let recorder = RecordingActionExecutor(failuresRemaining: 1)
        let coordinator = PresetExecutionCoordinator(
            actionExecutor: recorder,
            clock: ImmediatePresetClock()
        )
        let action = PresetStepAction.legacy(name: "LegacyPower", value: "on")
        let preset = Preset(name: "Retry", steps: [makeStep(action)])

        let result = await coordinator.execute(
            preset,
            policy: PresetExecutionPolicy(retryCount: 1)
        )
        let attempts = await recorder.attemptCount()

        XCTAssertEqual(result.status, .succeeded)
        XCTAssertEqual(attempts, 2)
    }

    func testStopsAfterFirstFailureByDefault() async {
        let recorder = RecordingActionExecutor(failuresRemaining: 1)
        let coordinator = PresetExecutionCoordinator(
            actionExecutor: recorder,
            clock: ImmediatePresetClock()
        )
        let first = PresetStepAction.legacy(name: "LegacyPower", value: "on")
        let second = PresetStepAction.legacy(name: "NeverReached", value: nil)
        let preset = Preset(name: "Stop", steps: [makeStep(first), makeStep(second)])

        let result = await coordinator.execute(preset)

        XCTAssertEqual(result.status, .failed)
        XCTAssertEqual(result.steps.count, 1)
    }

    func testPresetLevelTargetIsAppliedToLegacyAction() async {
        let recorder = RecordingActionExecutor()
        let coordinator = PresetExecutionCoordinator(
            actionExecutor: recorder,
            clock: ImmediatePresetClock()
        )
        let step = PresetStep(
            rawValue: "PowerOff",
            step: "PowerOff",
            actionName: nil,
            actionValue: nil,
            parameters: nil,
            delayMilliseconds: 0,
            option: "",
            action: .legacy(name: "PowerOff", value: nil)
        )
        let preset = Preset(
            name: "Targeted power",
            steps: [step],
            targetDeviceAddress: "192.168.1.20"
        )

        let result = await coordinator.execute(preset)
        let recordedActions = await recorder.actions()

        XCTAssertEqual(result.status, .succeeded)
        XCTAssertEqual(
            recordedActions,
            [.deviceCommand(target: "192.168.1.20", command: "PowerOff")]
        )
    }

    private func makeStep(_ action: PresetStepAction) -> PresetStep {
        PresetStep(
            rawValue: "test",
            step: "test",
            actionName: nil,
            actionValue: nil,
            parameters: nil,
            delayMilliseconds: 0,
            option: "",
            action: action
        )
    }
}

private struct ImmediatePresetClock: PresetClock {
    func sleep(for milliseconds: Int) async throws {
        if milliseconds < 0 {
            throw RecordingError.failed
        }
    }
}

private actor RecordingActionExecutor: PresetActionExecutor {
    private var recordedActions: [PresetStepAction] = []
    private var remainingFailures: Int

    init(failuresRemaining: Int = 0) {
        self.remainingFailures = failuresRemaining
    }

    func execute(_ action: PresetStepAction) async throws {
        recordedActions.append(action)
        if remainingFailures > 0 {
            remainingFailures -= 1
            throw RecordingError.failed
        }
    }

    func actions() -> [PresetStepAction] {
        recordedActions
    }

    func attemptCount() -> Int {
        recordedActions.count
    }
}

private enum RecordingError: Error, Sendable {
    case failed
}
