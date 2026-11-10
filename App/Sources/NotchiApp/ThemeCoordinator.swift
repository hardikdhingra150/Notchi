import AppKit
import Combine
import NotchiCore
import NotchiIcons

/// Makes the rest of the desktop follow the theme: when a theme is applied, the
/// wallpaper fades to the theme's video and accent-tinted folders are recoloured.
/// The notch listens for the same event on its own.
@MainActor
final class ThemeCoordinator {
    private unowned let app: AppDelegate
    private var sub: AnyCancellable?
    private static let wallpaperKey = "themeSetsWallpaper"
    private static let iconsKey = "themeTintsIcons"

    init(app: AppDelegate) { self.app = app }

    /// Both are on unless the user turned them off in Settings.
    var setsWallpaper: Bool {
        get { UserDefaults.standard.object(forKey: Self.wallpaperKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Self.wallpaperKey) }
    }
    var tintsIcons: Bool {
        get { UserDefaults.standard.object(forKey: Self.iconsKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Self.iconsKey) }
    }

    func start() {
        sub = app.bus.events.sink { [weak self] e in
            if case .themeChanged(let t) = e { MainActor.assumeIsolated { self?.follow(t) } }
        }
    }

    func follow(_ theme: Theme) {
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
