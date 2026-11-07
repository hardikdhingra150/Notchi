import Foundation
import Observation

/// Loads, validates and applies themes. Every module reads the active theme from here.
@MainActor
@Observable
public final class ThemeEngine {
    public private(set) var themes: [Theme] = [.paper]
    public private(set) var active: Theme = .paper
    public private(set) var loadErrors: [String] = []

    private let defaultsKey = "activeTheme"
    private let bus: EventBus

    public init(bus: EventBus) {
        self.bus = bus
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

    public func reload() {
        var found: [String: Theme] = [Theme.paper.id: .paper]
        var errors: [String] = []
        for dir in [Self.builtInThemesURL, Self.userThemesURL].compactMap({ $0 }) {
            let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
            for file in files where file.pathExtension == "json" {
                do {
                    let t = try Theme.decode(Data(contentsOf: file))
                    found[t.id] = t
                } catch {
                    errors.append("\(file.lastPathComponent): \(error)")
                }
            }
        }
        themes = found.values.sorted { $0.name < $1.name }
        loadErrors = errors
        let saved = UserDefaults.standard.string(forKey: defaultsKey)
        if let t = themes.first(where: { $0.id == saved }) { active = t }
    }

    @discardableResult
    public func apply(id: String) -> Bool {
        guard let t = themes.first(where: { $0.id == id }) else { return false }
        apply(t)
        return true
    }

    public func apply(_ theme: Theme) {
        active = theme
        UserDefaults.standard.set(theme.id, forKey: defaultsKey)
        bus.post(.themeChanged(theme))
    }
}
