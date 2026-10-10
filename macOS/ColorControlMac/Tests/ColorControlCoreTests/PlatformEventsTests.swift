import XCTest
@testable import ColorControlCore

final class PlatformEventsTests: XCTestCase {
    func testScreenSleepMapsToLegacyScreensaverStart() {
        XCTAssertEqual(
            PlatformSignal(kind: .screensDidSleep).automationEvent,
            AutomationEvent(kind: .screensaverStart)
        )
    }

    func testScreenWakeMapsToLegacyScreensaverStop() {
        XCTAssertEqual(
            PlatformSignal(kind: .screensDidWake).automationEvent,
            AutomationEvent(kind: .screensaverStop)
        )
    }

    func testSessionSignalsRemainPowerPolicyOnly() {
        XCTAssertNil(PlatformSignal(kind: .sessionDidResignActive).automationEvent)
        XCTAssertNil(PlatformSignal(kind: .sessionDidBecomeActive).automationEvent)
    }

    func testScreenWakeRequiresRecentUserInput() {
        XCTAssertTrue(
            ScreenWakeUserIntentPolicy.shouldForwardScreenWake(
                secondsSinceLastUserInput: 1.5
            )
        )
        XCTAssertTrue(
            ScreenWakeUserIntentPolicy.shouldForwardScreenWake(
                secondsSinceLastUserInput: 5
            )
        )
        XCTAssertFalse(
            ScreenWakeUserIntentPolicy.shouldForwardScreenWake(
                secondsSinceLastUserInput: 5.001
            )
        )
        XCTAssertFalse(
            ScreenWakeUserIntentPolicy.shouldForwardScreenWake(
                secondsSinceLastUserInput: .infinity
            )
        )
    }
}
