import AppKit
import SwiftUI

@MainActor
final class VibeScreenApplicationDelegate: NSObject, NSApplicationDelegate {
    private var windowObservers: [NSObjectProtocol] = []
    private weak var container: AppContainer?
    private var menuBarController: MenuBarStatusItemController?
    private var openMainWindowAction: (() -> Void)?
    private var suppressMainWindowForStartup = false
    var terminationHandler: (() -> Void)?

    func configure(container: AppContainer) {
        self.container = container
        terminationHandler = { [weak container] in
            container?.prepareForTermination()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconURL = Bundle.main.url(forResource: "VibeScreenIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            // Set this at runtime as well as in Info.plist so Dock updates
            // immediately when a development bundle replaces its icon.
            NSApp.applicationIconImage = icon
        }
        suppressMainWindowForStartup = true

        let mainWindowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            Task { @MainActor [weak self] in
                guard let self,
                      self.suppressMainWindowForStartup,
                      window.title == "VibeScreen",
                      !(window is NSPanel) else { return }
                window.orderOut(nil)
                self.updateActivationPolicy(closedWindow: window)
            }
        }
        windowObservers.append(mainWindowObserver)

        if let container {
            menuBarController = MenuBarStatusItemController(container: container) { [weak self] in
                _ = self?.focusMainWindow()
            }
        }
        NSApp.setActivationPolicy(.accessory)
        hideMainWindowForStartup()
        Task { @MainActor [weak self] in
            // SwiftUI may finish creating the Window scene after the app
            // delegate callback. Hide it again on the next main-actor turn so
            // every launch starts in the menu bar without a window flash.
            await Task.yield()
            self?.hideMainWindowForStartup()
        }

        let closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let closedWindow = notification.object as? NSWindow
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Let AppKit finish removing the closed window before checking
                // visibility. The menu-bar scene remains alive while the Dock
                // icon is hidden.
                await Task.yield()
                self.updateActivationPolicy(closedWindow: closedWindow)
            }
        }
        windowObservers.append(closeObserver)
    }

    func applicationWillTerminate(_ notification: Notification) {
        terminationHandler?()
        menuBarController?.tearDown()
        menuBarController = nil
        windowObservers.forEach(NotificationCenter.default.removeObserver)
        windowObservers.removeAll()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // The menu-bar status item remains available while the main window is
        // hidden or closed, so the app must outlive its window scenes.
        false
    }

    func updateActivationPolicy(closedWindow: NSWindow? = nil) {
        let hasVisibleMainWindow = NSApp.windows.contains { window in
            window !== closedWindow
                && window.title == "VibeScreen"
                && window.isVisible
                && !window.isMiniaturized
                && !(window is NSPanel)
        }
        NSApp.setActivationPolicy(hasVisibleMainWindow ? .regular : .accessory)
    }

    func registerOpenMainWindowAction(_ action: @escaping () -> Void) {
        openMainWindowAction = action
    }

    @discardableResult
    func focusMainWindow() -> Bool {
        suppressMainWindowForStartup = false
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        guard let window = NSApp.windows.first(where: { window in
            window.title == "VibeScreen"
                && !(window is NSPanel)
        }) else {
            guard let openMainWindowAction else { return false }
            openMainWindowAction()
            return true
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
        return true
    }

    private func hideMainWindowForStartup() {
        guard suppressMainWindowForStartup else { return }
        for window in NSApp.windows where window.title == "VibeScreen" && !(window is NSPanel) {
            window.orderOut(nil)
        }
        updateActivationPolicy()
    }
}

@MainActor
private struct MainWindowSceneRoot: View {
    @ObservedObject var container: AppContainer
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MainWindowView(container: container)
            .onAppear {
                (NSApp.delegate as? VibeScreenApplicationDelegate)?
                    .registerOpenMainWindowAction {
                    openWindow(id: "main")
                }
            }
    }
}

@main
@MainActor
struct VibeScreenApp: App {
    @NSApplicationDelegateAdaptor(VibeScreenApplicationDelegate.self) private var applicationDelegate
    @StateObject private var container = AppContainer()

    init() {
        let container = AppContainer()
        _container = StateObject(wrappedValue: container)
        applicationDelegate.configure(container: container)
    }

    var body: some Scene {
        Window("VibeScreen", id: "main") {
            MainWindowSceneRoot(container: container)
        }
        .defaultSize(width: 1_080, height: 720)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit VibeScreen") {
                    container.prepareForTermination()
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }

        Settings {
            SettingsView(container: container)
        }
    }
}
