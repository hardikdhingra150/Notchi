import AppKit
import Combine
import NotchiCore
import NotchiIcons
import NotchiWallpaper
import Observation

/// Makes the rest of the desktop follow the theme: when a theme is applied, the
/// wallpaper fades to the theme's video and accent-tinted folders are recoloured.
/// The notch listens for the same event on its own.
@MainActor
@Observable
final class ThemeCoordinator {
    @ObservationIgnored private unowned let app: AppDelegate
    @ObservationIgnored private var sub: AnyCancellable?
    private static let wallpaperKey = "themeSetsWallpaper"
    private static let iconsKey = "themeTintsIcons"

    init(app: AppDelegate) {
        self.app = app
        setsWallpaper = UserDefaults.standard.object(forKey: Self.wallpaperKey) as? Bool ?? true
        tintsIcons = UserDefaults.standard.object(forKey: Self.iconsKey) as? Bool ?? true
    }

    /// Both are on unless the user turned them off in Settings.
    var setsWallpaper: Bool { didSet { UserDefaults.standard.set(setsWallpaper, forKey: Self.wallpaperKey) } }
    var tintsIcons: Bool { didSet { UserDefaults.standard.set(tintsIcons, forKey: Self.iconsKey) } }
    /// While a backup is being restored the saved wallpaper and icons win, not the theme's.
    @ObservationIgnored var quiet = false

    func reloadSettings() {
        setsWallpaper = UserDefaults.standard.object(forKey: Self.wallpaperKey) as? Bool ?? true
        tintsIcons = UserDefaults.standard.object(forKey: Self.iconsKey) as? Bool ?? true
    }

    func start() {
        sub = app.bus.events.sink { [weak self] e in
            if case .themeChanged(let t) = e { MainActor.assumeIsolated { self?.follow(t) } }
        }
    }

    /// Show the wallpaper the saved settings ask for (at launch and after a restore).
    /// A wallpaper that came from a theme is looked up again through the theme, because
    /// the video lives inside the app or the theme's folder and that path can move.
    func syncWallpaper(animated: Bool) {
        let d = UserDefaults.standard
        if d.string(forKey: "wallpaperSource") == WallpaperController.Source.theme.rawValue, d.string(forKey: "wallpaperVideo") != nil,
           let video = app.themes.wallpaperURL(for: app.themes.active) {
            try? app.wallpaper.set(video, source: .theme, animated: animated)
        } else {
            app.wallpaper.reloadFromSettings(animated: animated)
        }
    }

    func follow(_ theme: Theme) {
        guard !quiet else { return }
        if setsWallpaper {
            if let video = app.themes.wallpaperURL(for: theme) {
                try? app.wallpaper.set(video, source: .theme, animated: true)
            } else if app.wallpaper.source == .theme, app.wallpaper.url != nil {
                // the last theme brought its own wallpaper and this one has none
                app.wallpaper.turnOff(animated: true)
            }
        }
        if tintsIcons, theme.icons?.tintFolders ?? true {
            IconStudio().retint(to: theme.accent)
        }
    }
}
