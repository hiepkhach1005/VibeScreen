import XCTest
@testable import VibeScreenCore

final class TVPowerPolicyTests: XCTestCase {
    func testMapsMacSleepToConfiguredTVPowerOff() {
        let device = TVDeviceDescriptor(
            name: "Living room",
            kind: .lgWebOS,
            host: "192.168.1.10",
            powerPolicy: TVPowerPolicy(powerOffOnStandby: true)
        )

        XCTAssertEqual(
            TVPowerPolicyEngine.actions(for: .willSleep, device: device),
            [TVPowerAction(command: .powerOff)]
        )
    }

    func testPreservesDelayedScreenSaverBehavior() {
        let device = TVDeviceDescriptor(
            name: "Desk",
            kind: .samsungTizen,
            host: "192.168.1.11",
            powerPolicy: TVPowerPolicy(
                powerOffOnScreenSaver: true,
                turnScreenOffOnScreenSaver: true,
                screenSaverMinimumDuration: 30
            )
        )

        XCTAssertEqual(
            TVPowerPolicyEngine.actions(for: .screensDidSleep, device: device),
            [TVPowerAction(command: .screenOff, delaySeconds: 30)]
        )
    }

    func testManualPowerOffSuppressesAutomaticWakeUntilManualPowerOnIsAllowed() {
        let device = TVDeviceDescriptor(
            name: "Desk",
            kind: .lgWebOS,
            host: "192.168.1.11",
            powerPolicy: TVPowerPolicy(
                powerOnAfterStartup: true,
                powerOnAfterResume: true,
                powerOnAfterScreenSaver: true,
                powerOnAfterSessionUnlock: true,
                powerOnAfterManualPowerOff: false
            )
        )

        for signal in [
            PlatformSignalKind.startup,
            .didWake,
            .screensDidWake,
            .sessionDidBecomeActive
        ] {
            XCTAssertTrue(
                TVPowerPolicyEngine.actions(
                    for: signal,
                    device: device,
                    manualPowerOff: true
                ).isEmpty
            )
        }
    }

    func testAutomaticScreenSleepCanWakeTheTVWhenNoManualOverrideExists() {
        let device = TVDeviceDescriptor(
            name: "Desk",
            kind: .lgWebOS,
            host: "192.168.1.11",
            powerPolicy: TVPowerPolicy(
                powerOffOnScreenSaver: true,
                powerOnAfterScreenSaver: true
            )
        )

        XCTAssertEqual(
            TVPowerPolicyEngine.actions(for: .screensDidSleep, device: device),
            [TVPowerAction(command: .powerOff)]
        )
        XCTAssertEqual(
            TVPowerPolicyEngine.actions(for: .screensDidWake, device: device),
            [TVPowerAction(command: .powerOn)]
        )
    }

    func testShutdownAndStartupCanUseScreenOnlyActions() {
        let device = TVDeviceDescriptor(
            name: "Desk",
            kind: .lgWebOS,
            host: "192.168.1.11",
            powerPolicy: TVPowerPolicy(
                powerOnAfterStartup: true,
                powerOffOnShutdown: true,
                turnScreenOnAfterStartup: true,
                turnScreenOffOnShutdown: true
            )
        )

        XCTAssertEqual(
            TVPowerPolicyEngine.actions(for: .startup, device: device),
            [TVPowerAction(command: .screenOn)]
        )
        XCTAssertEqual(
            TVPowerPolicyEngine.actions(for: .willPowerOff, device: device),
            [TVPowerAction(command: .screenOff)]
        )
    }

    func testDisabledTriggersProduceNoActions() {
        let device = TVDeviceDescriptor(
            name: "Disabled",
            kind: .lgWebOS,
            host: "192.168.1.12",
            powerPolicy: TVPowerPolicy(powerOffOnShutdown: true, triggersEnabled: false)
        )

        XCTAssertTrue(TVPowerPolicyEngine.actions(for: .willPowerOff, device: device).isEmpty)
    }
}
