import AppKit
import NotchiCore
import NotchiNotch

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let bus = EventBus()
    lazy var themes = ThemeEngine(bus: bus)
    lazy var energy = EnergyGovernor(bus: bus)
    lazy var nowPlaying = NowPlayingService(bus: bus)
    lazy var battery = BatteryMonitor(bus: bus)

    private var statusMenu: StatusMenu?
    private var settings: SettingsWindowController?
    private(set) var island: NotchIslandController?
    private var ipc: IPCServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        themes.reload()
        _ = energy
        statusMenu = StatusMenu(app: self)
        island = NotchIslandController(bus: bus, themes: themes, energy: energy)
        island?.start()
        if let model = island?.model {
            model.onPlayPause = { [weak self] in self?.nowPlaying.playPause() }
            model.onNext = { [weak self] in self?.nowPlaying.next() }
            model.onPrevious = { [weak self] in self?.nowPlaying.previous() }
            nowPlaying.onArtwork = { img in model.artwork = img }
        }
        nowPlaying.start()
        battery.start()
        ipc = IPCServer(app: self)
        ipc?.start()
    }

    func showSettings() {
        if settings == nil { settings = SettingsWindowController(app: self) }
        settings?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
