import AppKit
import NotchiCore
import NotchiNotch

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let bus = EventBus()
    lazy var themes = ThemeEngine(bus: bus)
    lazy var energy = EnergyGovernor(bus: bus)

    private var statusMenu: StatusMenu?
    private var settings: SettingsWindowController?
    private(set) var island: NotchIslandController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        themes.reload()
        _ = energy
        statusMenu = StatusMenu(app: self)
        island = NotchIslandController(bus: bus, themes: themes, energy: energy)
        island?.start()
    }

    func showSettings() {
        if settings == nil { settings = SettingsWindowController(app: self) }
        settings?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
