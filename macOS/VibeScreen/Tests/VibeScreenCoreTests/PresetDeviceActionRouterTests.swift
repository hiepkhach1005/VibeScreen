import XCTest
@testable import VibeScreenCore

final class PresetDeviceActionRouterTests: XCTestCase {
    func testRoutesTypedCommandToMatchingDevice() async throws {
        let descriptor = TVDeviceDescriptor(
            name: "Office TV",
            kind: .lgWebOS,
            host: "192.168.1.70"
        )
        let controller = RouterRecordingController(descriptor: descriptor)
        let router = PresetDeviceActionRouter()
        await router.register(controller)

        try await router.execute(.deviceCommand(target: descriptor.host, command: "Volume(30)"))

        let commands = await controller.commands()
        XCTAssertEqual(commands, [.setVolume(30)])
    }

    func testRoutesLegacyWakeActionThroughInjectedSender() async throws {
        let descriptor = TVDeviceDescriptor(
            name: "Bedroom TV",
            kind: .samsungTizen,
            host: "192.168.1.71",
            macAddress: "AA:BB:CC:DD:EE:11"
        )
        let wake = RouterRecordingWakeOnLAN()
        let router = PresetDeviceActionRouter(wakeOnLAN: wake)
        await router.register(RouterRecordingController(descriptor: descriptor))

        try await router.execute(.legacy(name: "WOL", value: nil))

        let addresses = await wake.sentAddresses()
        XCTAssertEqual(addresses, ["AA:BB:CC:DD:EE:11"])
    }

    func testManualPowerOffBlocksAutomaticScreenWakeUntilExplicitPowerOn() async throws {
        let descriptor = TVDeviceDescriptor(
            name: "Office TV",
            kind: .lgWebOS,
            host: "192.168.1.72"
        )
        let controller = RouterRecordingController(descriptor: descriptor)
        let router = PresetDeviceActionRouter()
        await router.register(controller)
        await router.recordManualPowerAction(.screenOff, for: descriptor.id)

        try await router.execute(.deviceCommand(target: descriptor.host, command: "ScreenOn"))
        let suppressedCommands = await controller.commands()
        XCTAssertEqual(suppressedCommands, [])

        await router.recordManualPowerAction(.screenOn, for: descriptor.id)
        try await router.execute(.deviceCommand(target: descriptor.host, command: "ScreenOn"))
        let commands = await controller.commands()
        XCTAssertEqual(commands, [.screenOn])
    }
}

private actor RouterRecordingWakeOnLAN: WakeOnLANSender {
    private var values: [String] = []

    func send(macAddress: String, broadcastAddress: String, port: UInt16) async throws {
        values.append(macAddress)
    }

    func sentAddresses() -> [String] {
        values
    }
}

private actor RouterRecordingController: TVDeviceController {
    private let descriptor: TVDeviceDescriptor
    private var values: [TVCommand] = []

    init(descriptor: TVDeviceDescriptor) {
        self.descriptor = descriptor
    }

    func deviceDescriptor() async -> TVDeviceDescriptor { descriptor }
    func connect() async throws {}
    func execute(_ command: TVCommand) async throws { values.append(command) }
    func disconnect() async {}

    func commands() -> [TVCommand] { values }
}
