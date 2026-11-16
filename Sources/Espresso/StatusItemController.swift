import AppKit
import Combine
import EspressoCore

/// Owns the menu bar icon. Left-click toggles keep-awake; right-click
/// (or Control/Option-click) opens the menu.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private static let defaultDurationKey = "defaultDuration"

    private let controller: AwakeController
    private let defaults: UserDefaults
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private var cancellables = Set<AnyCancellable>()

    init(controller: AwakeController = AwakeController(), defaults: UserDefaults = .standard) {
        self.controller = controller
        self.defaults = defaults
        super.init()

        menu.delegate = self
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        controller.$isActive
            .combineLatest(controller.$endDate)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in self?.updateButton() }
            .store(in: &cancellables)
    }

    func shutdown() {
        controller.deactivate()
    }

    private var defaultDuration: ActivationDuration {
        get {
            defaults.string(forKey: Self.defaultDurationKey)
                .flatMap(ActivationDuration.init(storageKey:)) ?? .indefinitely
        }
        set { defaults.set(newValue.storageKey, forKey: Self.defaultDurationKey) }
    }

    // MARK: - Status item

    private func updateButton() {
        guard let button = statusItem.button else { return }
        let symbol = controller.isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
        let description = controller.isActive ? "Espresso: Active" : "Espresso: Inactive"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: description)
        image?.isTemplate = true
        button.image = image
        button.toolTip = statusDescription
    }

    private var statusDescription: String {
        guard controller.isActive else { return "Espresso is inactive" }
        guard let endDate = controller.endDate else { return "Espresso is active indefinitely" }
        let time = endDate.formatted(date: .omitted, time: .shortened)
        return "Espresso is active until \(time)"
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
            || event?.modifierFlags.contains(.option) == true

        if wantsMenu {
            // Attach the menu only for this click so left-click keeps toggling.
            statusItem.menu = menu
            sender.performClick(nil)
            statusItem.menu = nil
        } else {
            controller.toggle(defaultDuration: defaultDuration)
        }
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        var status = statusDescription
        if let remaining = controller.remaining {
            status += " (\(remaining.espressoRemainingString) left)"
        }
        let statusItem = NSMenuItem(title: status, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        menu.addItem(.separator())

        let toggleTitle = controller.isActive ? "Turn Off" : "Turn On (\(defaultDuration.title))"
        menu.addItem(item(toggleTitle, #selector(toggleFromMenu)))

        menu.addItem(submenuItem("Activate For", selected: nil, action: #selector(activateFor(_:))))
        menu.addItem(submenuItem("Default Duration", selected: defaultDuration, action: #selector(setDefaultDuration(_:))))
        menu.addItem(.separator())

        let login = item("Launch at Login", #selector(toggleLaunchAtLogin))
        login.state = LaunchAtLogin.isEnabled ? .on : .off
        if !LaunchAtLogin.isAvailable {
            login.action = nil
            login.toolTip = "Available when running the bundled Espresso.app"
        }
        menu.addItem(login)
        menu.addItem(.separator())

        menu.addItem(item("About Espresso", #selector(showAbout)))
        menu.addItem(item("Quit Espresso", #selector(quit), key: "q"))
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func submenuItem(_ title: String, selected: ActivationDuration?, action: Selector) -> NSMenuItem {
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: title)
        for duration in ActivationDuration.allCases {
            let child = item(duration.title, action)
            child.representedObject = duration.storageKey
            child.state = duration == selected ? .on : .off
            submenu.addItem(child)
        }
        parent.submenu = submenu
        return parent
    }

    private func duration(from sender: NSMenuItem) -> ActivationDuration? {
        (sender.representedObject as? String).flatMap(ActivationDuration.init(storageKey:))
    }

    @objc private func toggleFromMenu() {
        controller.toggle(defaultDuration: defaultDuration)
    }

    @objc private func activateFor(_ sender: NSMenuItem) {
        guard let duration = duration(from: sender) else { return }
        if !controller.activate(for: duration) {
            showError("Espresso couldn't prevent sleep", detail: "macOS refused the power assertion.")
        }
    }

    @objc private func setDefaultDuration(_ sender: NSMenuItem) {
        guard let duration = duration(from: sender) else { return }
        defaultDuration = duration
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
        } catch {
            showError("Couldn't change Launch at Login", detail: error.localizedDescription)
        }
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func showError(_ message: String, detail: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.alertStyle = .warning
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
