import ColorControlCore

actor MacPresetDisplayController: PresetDisplayController {
    func refresh() async throws {
        await MainActor.run {
            _ = MacDisplayService().snapshots()
        }
    }
}
