import SwiftUI

@main
@MainActor
struct ColorControlMacApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup("ColorControl", id: "main") {
            MainWindowView(container: container)
        }
        .defaultSize(width: 1_080, height: 720)

        MenuBarExtra {
            MenuBarView(container: container)
        } label: {
            Label("ColorControl", systemImage: "display")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(container: container)
        }
    }
}
