import AppKit
import SwiftUI

@main
struct EspressoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu-bar-only app: no windows. The status item is managed by AppDelegate.
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement in Info.plist hides the Dock icon for the bundled app;
        // this also covers running the bare executable via `swift run`.
        NSApp.setActivationPolicy(.accessory)
        statusItemController = StatusItemController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusItemController?.shutdown()
    }
}
