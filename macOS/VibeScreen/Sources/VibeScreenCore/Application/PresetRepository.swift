import Foundation

public protocol PresetRepository: Sendable {
    func all() async throws -> [Preset]
    func replaceAll(_ presets: [Preset]) async throws
    func save(_ preset: Preset) async throws
    func delete(id: UUID) async throws
}

/// A deterministic repository used by the first native shell and by tests.
/// Disk persistence is intentionally a separate migration slice so legacy
/// JSON is never overwritten before its schema is fully mapped.
public actor InMemoryPresetRepository: PresetRepository {
    private var presets: [UUID: Preset]

    public init(presets: [Preset] = []) {
        self.presets = Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0) })
    }

    public func all() async throws -> [Preset] {
        presets.values.sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    public func replaceAll(_ presets: [Preset]) async throws {
        self.presets = Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0) })
    }

    public func save(_ preset: Preset) async throws {
        presets[preset.id] = preset
    }

    public func delete(id: UUID) async throws {
        presets.removeValue(forKey: id)
    }
}
