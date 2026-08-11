import ColorControlCore
import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var container: AppContainer
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "display")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ColorControl")
                        .font(.headline)
                    Text("Native shell ready")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Text("Quick presets")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            let quickPresets = container.presets.filter(\.showInQuickAccess)
            if quickPresets.isEmpty {
                Text("No quick presets")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(quickPresets) { preset in
                    Button {
                        container.apply(preset)
                    } label: {
                        Label(preset.name, systemImage: "slider.horizontal.3")
                    }
                }
            }

            Divider()

            Button {
                openWindow(id: "main")
            } label: {
                Label("Open ColorControl", systemImage: "arrow.up.forward.app")
            }

            Button("Quit ColorControl") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
        .frame(width: 250)
    }
}
