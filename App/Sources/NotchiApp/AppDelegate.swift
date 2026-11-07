import AppKit
import NotchiCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let bus = EventBus()
    lazy var themes = ThemeEngine(bus: bus)
    lazy var energy = EnergyGovernor(bus: bus)

    private var statusMenu: StatusMenu?
    private var settings: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        themes.reload()
        _ = energy
        statusMenu = StatusMenu(app: self)
    }

    func showSettings() {
        if settings == nil { settings = SettingsWindowController(app: self) }
        settings?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
