import Foundation
import ServiceManagement

@MainActor
final class LoginItemManager {
    enum State: Equatable {
        case disabled
        case enabled
        case requiresApproval
        case unavailable
    }

    private let service = SMAppService.mainApp

    var state: State {
        switch service.status {
        case .notRegistered:
            return .disabled
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    var isRegistered: Bool {
        state == .enabled || state == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled, !isRegistered {
            try service.register()
        } else if !enabled, isRegistered {
            try service.unregister()
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
