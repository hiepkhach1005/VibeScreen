import XCTest
@testable import VibeScreenCore

final class GameWorkflowTests: XCTestCase {
    func testRunsPreLaunchLaunchPostAndFinalize() async {
        let launcher = RecordingGameLauncher()
        let actions = RecordingActionExecutor()
        let coordinator = GameWorkflowCoordinator(
            processLauncher: launcher,
            actionExecutor: actions,
            clock: ImmediatePresetClock()
        )
        let preset = GamePreset(
            name: "Game",
            launch: GameLaunchSpecification(pathOrBundleIdentifier: "com.example.game"),
            preLaunchSteps: [makeStep("pre")],
            postLaunchSteps: [makeStep("post")],
            finalizeSteps: [makeStep("final")]
        )

        let result = await coordinator.execute(preset)
        let phases = await actions.actions()
        let launchCount = await launcher.launches()

        XCTAssertEqual(result.status, .succeeded)
        XCTAssertEqual(result.phaseResults.count, 3)
        XCTAssertEqual(phases, [
            .legacy(name: "pre", value: nil),
            .legacy(name: "post", value: nil),
            .legacy(name: "final", value: nil)
        ])
        XCTAssertEqual(launchCount, 1)
    }

    private func makeStep(_ name: String) -> PresetStep {
        PresetStep(
            rawValue: name,
            step: name,
            actionName: nil,
            actionValue: nil,
            parameters: nil,
            delayMilliseconds: 0,
            option: "",
            action: .legacy(name: name, value: nil)
        )
    }
}

private actor RecordingGameLauncher: GameProcessLauncher {
    private var count = 0

    func launch(_ specification: GameLaunchSpecification) async throws -> LaunchedProcess {
        count += 1
        return LaunchedProcess(identifier: 100)
    }

    func launches() -> Int { count }
}

private actor RecordingActionExecutor: PresetActionExecutor {
    private var recorded: [PresetStepAction] = []

    func execute(_ action: PresetStepAction) async throws {
        recorded.append(action)
    }

    func actions() -> [PresetStepAction] { recorded }
}

private struct ImmediatePresetClock: PresetClock {
    func sleep(for milliseconds: Int) async throws {}
}
