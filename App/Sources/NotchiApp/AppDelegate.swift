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
    lazy var systemHUD = SystemHUD(bus: bus, volume: volume)
    lazy var wallpaper = WallpaperController(bus: bus, energy: energy)
    lazy var coordinator = ThemeCoordinator(app: self)
    lazy var setup = SetupManager(app: self)
    /// Files double-clicked before the app finished starting.
    private var pendingFiles: [URL] = []
    private var launched = false

    private var statusMenu: StatusMenu?
    private var settings: SettingsWindowController?
    private var wallpapers: WallpaperBrowserController?
    private(set) var island: NotchIslandController?
    private var ipc: IPCServer?
    private var onboarding: OnboardingWindowController?
    let updater = Updater()

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
        systemHUD.start()
        wallpaper.start(restore: false)
        coordinator.syncWallpaper(animated: false)
        coordinator.start()
        ipc = IPCServer(app: self)
        ipc?.start()
        if !OnboardingWindowController.isDone { showOnboarding() }
        launched = true
        pendingFiles.forEach(open)
        pendingFiles = []
    }

    /// Double-clicking a .notchitheme installs and applies it; a .notchibackup asks before restoring.
    func application(_ application: NSApplication, open urls: [URL]) {
        if launched { urls.forEach(open) } else { pendingFiles += urls }
    }

    private func open(_ url: URL) {
        switch url.pathExtension.lowercased() {
        case SetupBackup.fileExtension:
            setup.confirmRestore(url)
        default:
            do { try setup.installTheme(url, apply: true) } catch {
                let a = NSAlert()
                a.messageText = "Couldn't install that theme"
                a.informativeText = "\(error)"
                NSApp.activate(ignoringOtherApps: true)
                a.runModal()
            }
        }
    }

    func showOnboarding() {
        if onboarding == nil { onboarding = OnboardingWindowController(app: self) }
        onboarding?.show(bus: bus)
    }

    func showWallpapers() {
        if wallpapers == nil { wallpapers = WallpaperBrowserController(app: self) }
        wallpapers?.show()
    }

    func showSettings() {
        if settings == nil { settings = SettingsWindowController(app: self) }
        settings?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
