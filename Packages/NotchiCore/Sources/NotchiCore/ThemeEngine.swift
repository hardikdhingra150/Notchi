import Foundation
import Observation

/// Loads, validates and applies themes. Every module reads the active theme from here.
@MainActor
@Observable
public final class ThemeEngine {
    public private(set) var themes: [Theme] = [.paper]
    public private(set) var active: Theme = .paper
    public private(set) var loadErrors: [String] = []

    public enum EngineError: Error, Equatable, CustomStringConvertible {
        case unknown(String)
        case builtIn(String)
        public var description: String {
            switch self {
            case .unknown(let id): "No theme named \"\(id)\""
            case .builtIn(let id): "\"\(id)\" comes with Notchi and can't be removed."
            }
        }
    }

    private let defaultsKey = "activeTheme"
    private let bus: EventBus
    private let builtInDir: URL?
    private let userDir: URL
    private let defaults: UserDefaults
    /// Where each theme's files are, and which themes the user added.
    private var bases: [String: URL] = [:]
    private var userIDs: Set<String> = []

    public init(bus: EventBus, builtInDir: URL? = ThemeEngine.builtInThemesURL, userDir: URL = ThemeEngine.userThemesURL, defaults: UserDefaults = .standard) {
        self.bus = bus
        self.builtInDir = builtInDir
        self.userDir = userDir
        self.defaults = defaults
    }

    /// Where user and community themes live: ~/Library/Application Support/Notchi/Themes
    public static var userThemesURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Notchi/Themes", isDirectory: true)
    }

    /// Built-in themes ship in Notchi.app/Contents/Resources/Themes.
    public static var builtInThemesURL: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("Themes", isDirectory: true)
    }

    public var userThemesFolder: URL { userDir }

    /// Reads every theme: loose `name.json` files and `name/theme.json` folders.
    /// A user theme with the same id as a built-in one replaces it.
    public func reload() {
        var found: [String: Theme] = [Theme.paper.id: .paper]
        var bases: [String: URL] = [:]
        var userIDs: Set<String> = []
        var errors: [String] = []
        let fm = FileManager.default
        for (dir, isUser) in [(builtInDir, false), (userDir, true)] {
            guard let dir else { continue }
            let items = ((try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey])) ?? [])
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            for item in items {
                let isFolder = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
                if isFolder && !fm.fileExists(atPath: item.appendingPathComponent(ThemePackage.manifestName).path) { continue }
                guard isFolder || item.pathExtension == "json" else { continue }
                do {
                    let (t, base) = try ThemePackage.read(item)
                    found[t.id] = t
                    bases[t.id] = base
                    if isUser { userIDs.insert(t.id) } else { userIDs.remove(t.id) }
                } catch {
                    errors.append("\(item.lastPathComponent): \(error)")
                }
            }
        }
        themes = found.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        self.bases = bases
        self.userIDs = userIDs
        loadErrors = errors
        let saved = defaults.string(forKey: defaultsKey)
        active = themes.first(where: { $0.id == saved }) ?? themes.first(where: { $0.id == active.id }) ?? .paper
    }

    public func theme(id: String) -> Theme? { themes.first { $0.id == id } }

    /// True for themes the user installed (they can be removed); false for the ones Notchi ships.
    public func isUserTheme(_ id: String) -> Bool { userIDs.contains(id) }

    /// The video a theme wants as wallpaper, when it has one and the file is there.
    public func wallpaperURL(for theme: Theme) -> URL? {
        guard let w = theme.wallpaper, w.type == .video, let base = bases[theme.id] else { return nil }
        return ThemePackage.asset(w.src, base: base)
    }

    @discardableResult
    public func apply(id: String) -> Bool {
        guard let t = theme(id: id) else { return false }
        apply(t)
        return true
    }

    public func apply(_ theme: Theme) {
        active = theme
        defaults.set(theme.id, forKey: defaultsKey)
        bus.post(.themeChanged(theme))
    }

    // MARK: Adding, sharing, removing

    /// Install a `.notchitheme` or `.json` file. It shows up in `themes` straight away.
    @discardableResult
    public func install(_ file: URL) throws -> Theme {
        let t = try ThemePackage.install(file, into: userDir)
        reload()
        return theme(id: t.id) ?? t
    }

    /// Write a theme and its files to a `.notchitheme` that anyone can install.
    public func export(id: String, to file: URL) throws {
        guard let t = theme(id: id) else { throw EngineError.unknown(id) }
        try ThemePackage.export(t, base: bases[id], to: file)
    }

    /// Remove a theme the user installed. If it was active, Notchi goes back to Paper.
    public func remove(id: String) throws {
        guard theme(id: id) != nil else { throw EngineError.unknown(id) }
        guard userIDs.contains(id) else { throw EngineError.builtIn(id) }
        let fm = FileManager.default
        try? fm.removeItem(at: userDir.appendingPathComponent(id, isDirectory: true))
        try? fm.removeItem(at: userDir.appendingPathComponent("\(id).json"))
        let wasActive = active.id == id
        reload()
        // a built-in theme with the same id may have come back; otherwise fall back to Paper
        if wasActive { apply(theme(id: id) ?? .paper) }
    }
}
