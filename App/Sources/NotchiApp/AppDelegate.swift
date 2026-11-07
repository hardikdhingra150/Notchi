import AppKit
import NotchiCore
import NotchiNotch
import NotchiWallpaper

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let bus = EventBus()
    lazy var themes = ThemeEngine(bus: bus)
    lazy var energy = EnergyGovernor(bus: bus)
    lazy var nowPlaying = NowPlayingService(bus: bus)
    lazy var battery = BatteryMonitor(bus: bus)
    lazy var volume = VolumeMonitor(bus: bus)
    lazy var wallpaper = WallpaperController(bus: bus, energy: energy)

    private var statusMenu: StatusMenu?
    private var settings: SettingsWindowController?
    private(set) var island: NotchIslandController?
    private var ipc: IPCServer?
    private var onboarding: OnboardingWindowController?

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
        volume.start()
        wallpaper.start()
        ipc = IPCServer(app: self)
        ipc?.start()
        if !OnboardingWindowController.isDone { showOnboarding() }
    }

    func showOnboarding() {
        if onboarding == nil { onboarding = OnboardingWindowController(app: self) }
        onboarding?.show(bus: bus)
    }

    func showSettings() {
        if settings == nil { settings = SettingsWindowController(app: self) }
        settings?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
