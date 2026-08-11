import XCTest
@testable import ColorControlCore

final class NativeStoreTests: XCTestCase {
    func testRoundTripsSnapshotAndCreatesBackupOnSecondWrite() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ColorControlTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = NativeStore(directoryURL: directory)
        let first = NativeStoreSnapshot(
            presets: [Preset(name: "First")]
        )
        let second = NativeStoreSnapshot(
            presets: [Preset(name: "Second")]
        )

        try await store.save(first)
        try await store.save(second)

        let loaded = try await store.load()
        XCTAssertEqual(loaded, second)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: directory.appendingPathComponent("ColorControl.json.bak").path
        ))
    }
}
