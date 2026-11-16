import Foundation
import ServiceManagement

/// Registers the app as a login item via `SMAppService` (macOS 13+).
@MainActor
enum LaunchAtLogin {
    /// `SMAppService` only works for a real `.app` bundle, not `swift run`.
    static var isAvailable: Bool {
        Bundle.main.bundleIdentifier != nil && Bundle.main.bundleURL.pathExtension == "app"
    }

    static var isEnabled: Bool {
        isAvailable && SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
