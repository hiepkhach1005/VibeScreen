import AppKit
import SwiftUI

@MainActor
final class MenuBarStatusItemController: NSObject, NSPopoverDelegate {
    private let container: AppContainer
    private let openMainWindow: () -> Void
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var secondaryClickRecognizer: NSClickGestureRecognizer?
    private var applicationActivationObserver: NSObjectProtocol?

    init(container: AppContainer, openMainWindow: @escaping () -> Void) {
        self.container = container
        self.openMainWindow = openMainWindow
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
    }

    func tearDown() {
        stopObservingApplicationActivation()
        if let button = statusItem.button, let secondaryClickRecognizer {
            button.removeGestureRecognizer(secondaryClickRecognizer)
        }
        secondaryClickRecognizer = nil
        statusItem.button?.target = nil
        statusItem.button?.action = nil
        if popover.isShown {
            popover.performClose(nil)
        }
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    func popoverDidClose(_ notification: Notification) {
        statusItem.button?.state = .off
        stopObservingApplicationActivation()
    }

    private func configureStatusItem() {
        popover.behavior = .transient
        popover.delegate = self

        let hostingController = NSHostingController(
            rootView: MenuBarView(container: container, openMainWindow: openMainWindow)
        )
        hostingController.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hostingController

        guard let button = statusItem.button else { return }
        if let iconURL = Bundle.main.url(forResource: "ColorControlIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            icon.size = NSSize(width: 20, height: 20)
            button.image = icon
        } else {
            button.image = NSImage(systemSymbolName: "tv", accessibilityDescription: "ColorControl")
        }
        button.imagePosition = .imageOnly
        button.toolTip = "ColorControl"
        button.setAccessibilityLabel("ColorControl menu")
        button.target = self
        button.action = #selector(handlePrimaryClick)

        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(handleSecondaryClick))
        recognizer.buttonMask = 0x2
        button.addGestureRecognizer(recognizer)
        secondaryClickRecognizer = recognizer
    }

    @objc
    private func handlePrimaryClick() {
        togglePopover()
    }

    @objc
    private func handleSecondaryClick() {
        togglePopover()
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            button.state = .off
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            button.state = .on
            observeOtherApplicationActivation()
        }
    }

    private func observeOtherApplicationActivation() {
        guard applicationActivationObserver == nil else { return }

        let ownProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        applicationActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[
                NSWorkspace.applicationUserInfoKey
            ] as? NSRunningApplication,
                  application.processIdentifier != ownProcessIdentifier else { return }

            Task { @MainActor [weak self] in
                guard let self, self.popover.isShown else { return }
                self.popover.performClose(nil)
            }
        }
    }

    private func stopObservingApplicationActivation() {
        guard let applicationActivationObserver else { return }
        NSWorkspace.shared.notificationCenter.removeObserver(applicationActivationObserver)
        self.applicationActivationObserver = nil
    }
}
