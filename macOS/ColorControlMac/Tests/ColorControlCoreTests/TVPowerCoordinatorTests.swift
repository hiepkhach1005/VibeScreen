import XCTest
@testable import ColorControlCore

final class TVPowerCoordinatorTests: XCTestCase {
    func testStandbyPolicyConnectsAndPowersOffTheDevice() async {
        let descriptor = TVDeviceDescriptor(
            name: "Living room",
            kind: .lgWebOS,
            host: "192.168.1.20",
            powerPolicy: TVPowerPolicy(powerOffOnStandby: true)
        )
        let controller = RecordingTVController(descriptor: descriptor)
        let coordinator = TVPowerPolicyCoordinator(clock: ImmediatePowerClock())
        await coordinator.register(controller)

        let results = await coordinator.handle(signal: .willSleep)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].status, .succeeded)
        let commands = await controller.commands()
        let connectCount = await controller.connectCount()
        let disconnectCount = await controller.disconnectCount()
        XCTAssertEqual(commands, [.powerOff])
        XCTAssertEqual(connectCount, 1)
        XCTAssertEqual(disconnectCount, 1)
    }

    func testStartupPolicyUsesWakeOnLAN() async {
        let descriptor = TVDeviceDescriptor(
            name: "Bedroom",
            kind: .samsungTizen,
            host: "192.168.1.30",
            macAddress: "AA:BB:CC:DD:EE:FF",
            powerPolicy: TVPowerPolicy(powerOnAfterStartup: true)
        )
        let controller = RecordingTVController(descriptor: descriptor)
        let wakeOnLAN = RecordingWakeOnLAN()
        let coordinator = TVPowerPolicyCoordinator(
            wakeOnLAN: wakeOnLAN,
            clock: ImmediatePowerClock()
        )
        await coordinator.register(controller)

        let results = await coordinator.handle(signal: .startup)

        XCTAssertEqual(results[0].status, .succeeded)
        let addresses = await wakeOnLAN.addresses()
        let commands = await controller.commands()
        XCTAssertEqual(addresses, ["AA:BB:CC:DD:EE:FF"])
        XCTAssertEqual(commands, [])
    }

    func testPowerOnWithoutMacAddressFailsClearly() async {
        let descriptor = TVDeviceDescriptor(
            name: "No MAC",
            kind: .lgWebOS,
            host: "192.168.1.40",
            powerPolicy: TVPowerPolicy(powerOnAfterStartup: true)
        )
        let coordinator = TVPowerPolicyCoordinator(clock: ImmediatePowerClock())
        await coordinator.register(RecordingTVController(descriptor: descriptor))

        let results = await coordinator.handle(signal: .startup)

        XCTAssertEqual(results[0].status, .failed)
        XCTAssertEqual(results[0].actions[0].message, TVPowerCoordinatorError.missingMacAddress.localizedDescription)
    }

    func testManualPowerOffSuppressesResumeUntilExplicitPowerOn() async {
        let descriptor = TVDeviceDescriptor(
            name: "Living room",
            kind: .lgWebOS,
            host: "192.168.1.20",
            macAddress: "AA:BB:CC:DD:EE:FF",
            powerPolicy: TVPowerPolicy(
                powerOnAfterResume: true,
                powerOnAfterScreenSaver: true
            )
        )
        let controller = RecordingTVController(descriptor: descriptor)
        let wakeOnLAN = RecordingWakeOnLAN()
        let coordinator = TVPowerPolicyCoordinator(
            wakeOnLAN: wakeOnLAN,
            clock: ImmediatePowerClock()
        )
        await coordinator.register(controller)
        await coordinator.recordManualPowerAction(.powerOff, for: descriptor.id)
        let isManuallyPoweredOff = await coordinator.isManuallyPoweredOff(deviceID: descriptor.id)
        XCTAssertTrue(isManuallyPoweredOff)

        let resumeResults = await coordinator.handle(signal: .didWake)
        let screenWakeResults = await coordinator.handle(signal: .screensDidWake)
        let suppressedAddresses = await wakeOnLAN.addresses()
        XCTAssertTrue(resumeResults.isEmpty)
        XCTAssertTrue(screenWakeResults.isEmpty)
        XCTAssertTrue(suppressedAddresses.isEmpty)

        await coordinator.recordManualPowerAction(.powerOn, for: descriptor.id)
        let isManuallyPoweredOn = await coordinator.isManuallyPoweredOff(deviceID: descriptor.id)
        XCTAssertFalse(isManuallyPoweredOn)
        let results = await coordinator.handle(signal: .didWake)

        XCTAssertEqual(results.count, 1)
        let addresses = await wakeOnLAN.addresses()
        XCTAssertEqual(addresses, ["AA:BB:CC:DD:EE:FF"])
    }
}

private struct ImmediatePowerClock: TVPowerActionClock {
    func sleep(for seconds: Int) async throws {
        XCTAssertGreaterThanOrEqual(seconds, 0)
    }
}

private actor RecordingWakeOnLAN: WakeOnLANSender {
    private var sentAddresses: [String] = []

    func send(macAddress: String, broadcastAddress: String, port: UInt16) async throws {
        sentAddresses.append(macAddress)
    }

    func addresses() -> [String] {
        sentAddresses
    }
}

private actor RecordingTVController: TVDeviceController {
    private let descriptor: TVDeviceDescriptor
    private var executedCommands: [TVCommand] = []
    private var connections = 0
    private var disconnections = 0

    init(descriptor: TVDeviceDescriptor) {
        self.descriptor = descriptor
    }

    func deviceDescriptor() async -> TVDeviceDescriptor {
        descriptor
    }

    func connect() async throws {
        connections += 1
    }

    func execute(_ command: TVCommand) async throws {
        executedCommands.append(command)
    }

    func disconnect() async {
        disconnections += 1
    }

    func commands() -> [TVCommand] {
        executedCommands
    }

    func connectCount() -> Int {
        connections
    }

    func disconnectCount() -> Int {
        disconnections
    }
}
