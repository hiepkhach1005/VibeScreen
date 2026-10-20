import XCTest
@testable import VibeScreenCore

final class PresetTriggerTests: XCTestCase {
    func testMatchesProcessAndDisplayContext() {
        let trigger = PresetTrigger(
            kind: .processSwitch,
            includedProcesses: ["game"],
            connectedDisplayPattern: "LG"
        )
        let event = AutomationEvent(kind: .processSwitch)
        let context = AutomationEventContext(
            processes: ["MyGame.app"],
            connectedDisplays: ["LG UltraFine"]
        )

        XCTAssertTrue(trigger.matches(event: event, context: context))
    }

    func testRejectsGpuOnlyConditionBecauseItIsNotPartOfNativeTriggerContract() {
        let trigger = PresetTrigger(kind: .startup)
        let event = AutomationEvent(kind: .resume)

        XCTAssertFalse(trigger.matches(event: event, context: AutomationEventContext()))
    }
}
