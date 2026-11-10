import Foundation

/// Your whole Notchi setup in one `.notchibackup` file: the settings, the themes
/// you installed, the icon ledger and (when it's small enough) your wallpaper video.
///
///     manifest.json      settings and where the backup came from
///     Themes/            ~/Library/Application Support/Notchi/Themes
///     icons.json         which icons Notchi changed
///     wallpaper/<file>   the video you chose, if it's under 200 MB
public enum SetupBackup {
    public static let fileExtension = "notchibackup"
    public static let schema = 1
    /// Videos above this stay where they are; the backup only remembers the path.
    public static let wallpaperLimit: Int64 = 200 * 1_048_576
    /// How many automatic backups to keep.
    public static let keep = 5

    public enum Value: Codable, Equatable, Sendable {
        case bool(Bool), int(Int), string(String)

        public init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let b = try? c.decode(Bool.self) { self = .bool(b) }
            else if let i = try? c.decode(Int.self) { self = .int(i) }
            else { self = .string(try c.decode(String.self)) }
        }

        public func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self {
            case .bool(let b): try c.encode(b)
            case .int(let i): try c.encode(i)
            case .string(let s): try c.encode(s)
            }
        }
    }

    enum Kind { case bool, int, string }
    /// Every setting Notchi stores, and its type.
    static let settings: [(key: String, kind: Kind)] = [
        ("activeTheme", .string), ("wallpaperVideo", .string), ("wallpaperSource", .string),
        ("replaceSystemHUD", .bool), ("batteryFPS", .int), ("pauseWhenBatteryLow", .bool),
        ("themeSetsWallpaper", .bool), ("themeTintsIcons", .bool),
    ]

    public struct Manifest: Codable, Equatable, Sendable {
        public var schema: Int
        public var created: Date
        public var appVersion: String
        public var settings: [String: Value]
        /// File name of the wallpaper video inside the backup, when it was small enough to include.
        public var wallpaperFile: String?
        public var themeCount: Int
        public var iconCount: Int
    }

    public enum BackupError: Error, Equatable, CustomStringConvertible {
        case notABackup(String)
        case unsupportedSchema(Int)
        public var description: String {
            switch self {
            case .notABackup(let p): "\(p) isn't a Notchi backup."
            case .unsupportedSchema(let s): "This backup was made by a newer Notchi (format \(s)). Update Notchi to restore it."
            }
        }
    }

    /// ~/Library/Application Support/Notchi
    public static var supportURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Notchi", isDirectory: true)
    }

    private static func coder() -> (JSONEncoder, JSONDecoder) {
        let e = JSONEncoder(), d = JSONDecoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        d.dateDecodingStrategy = .iso8601
        return (e, d)
    }

    /// Write a backup of everything under `support` plus the settings in `defaults`.
    @discardableResult
    public static func create(to file: URL, defaults: UserDefaults = .standard, support: URL = supportURL,
                              appVersion: String = "dev", now: Date = Date()) throws -> Manifest {
        let fm = FileManager.default
        let stage = try Archive.scratch("backup")
        defer { try? fm.removeItem(at: stage) }

        var values: [String: Value] = [:]
        for (key, kind) in settings {
            guard let raw = defaults.object(forKey: key) else { continue }
            switch kind {
            case .bool: if let b = raw as? Bool { values[key] = .bool(b) }
            case .int: if let i = raw as? Int { values[key] = .int(i) }
            case .string: if let s = raw as? String { values[key] = .string(s) }
            }
        }

        var themeCount = 0
        let themes = support.appendingPathComponent("Themes", isDirectory: true)
        if fm.fileExists(atPath: themes.path) {
            try fm.copyItem(at: themes, to: stage.appendingPathComponent("Themes"))
            themeCount = ((try? fm.contentsOfDirectory(atPath: themes.path)) ?? []).filter { !$0.hasPrefix(".") }.count
        }

        var iconCount = 0
        let icons = support.appendingPathComponent("icons.json")
        if let data = try? Data(contentsOf: icons) {
            try data.write(to: stage.appendingPathComponent("icons.json"))
            iconCount = ((try? JSONSerialization.jsonObject(with: data)) as? [Any])?.count ?? 0
        }

        // a wallpaper the user picked by hand travels with the backup when it's small enough
        var wallpaperFile: String?
        if case .string(let path)? = values["wallpaperVideo"], values["wallpaperSource"] != .string("theme") {
            let size = ((try? fm.attributesOfItem(atPath: path))?[.size] as? NSNumber)?.int64Value ?? 0
            if size > 0, size <= wallpaperLimit {
                let name = (path as NSString).lastPathComponent
                let dir = stage.appendingPathComponent("wallpaper", isDirectory: true)
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                try fm.copyItem(atPath: path, toPath: dir.appendingPathComponent(name).path)
                wallpaperFile = name
            }
        }

        // whole seconds, the way the file stores it
        let manifest = Manifest(schema: schema, created: Date(timeIntervalSince1970: now.timeIntervalSince1970.rounded(.down)), appVersion: appVersion, settings: values,
                                wallpaperFile: wallpaperFile, themeCount: themeCount, iconCount: iconCount)
        try coder().0.encode(manifest).write(to: stage.appendingPathComponent("manifest.json"))
        try Archive.create(from: stage, to: file)
        return manifest
    }

    /// What's in a backup, without restoring it.
    public static func inspect(_ file: URL) throws -> Manifest {
        let stage = try Archive.scratch("inspect")
        defer { try? FileManager.default.removeItem(at: stage) }
        return try unpack(file, to: stage)
    }

    private static func unpack(_ file: URL, to stage: URL) throws -> Manifest {
        guard try Archive.entries(of: file).contains("manifest.json") else { throw BackupError.notABackup(file.lastPathComponent) }
        try Archive.extract(file, to: stage, limit: 4 * Archive.defaultLimit)
        guard let data = try? Data(contentsOf: stage.appendingPathComponent("manifest.json")),
              let m = try? coder().1.decode(Manifest.self, from: data) else { throw BackupError.notABackup(file.lastPathComponent) }
        guard m.schema <= schema else { throw BackupError.unsupportedSchema(m.schema) }
        return m
    }

    /// Put a backup back: settings, installed themes, the icon ledger and the wallpaper video.
    /// Settings that aren't in the backup go back to their defaults.
    @discardableResult
    public static func restore(from file: URL, defaults: UserDefaults = .standard, support: URL = supportURL) throws -> Manifest {
        let fm = FileManager.default
        let stage = try Archive.scratch("restore")
        defer { try? fm.removeItem(at: stage) }
        let m = try unpack(file, to: stage)

        try fm.createDirectory(at: support, withIntermediateDirectories: true)
        let themes = support.appendingPathComponent("Themes", isDirectory: true)
        try? fm.removeItem(at: themes)
        let savedThemes = stage.appendingPathComponent("Themes")
        if fm.fileExists(atPath: savedThemes.path) { try fm.moveItem(at: savedThemes, to: themes) }

        let icons = support.appendingPathComponent("icons.json")
        try? fm.removeItem(at: icons)
        let savedIcons = stage.appendingPathComponent("icons.json")
        if fm.fileExists(atPath: savedIcons.path) { try fm.moveItem(at: savedIcons, to: icons) }

        var values = m.settings
        // the video comes back to where it was, or into Notchi's own folder when that place is gone
        if let name = m.wallpaperFile, Theme.isSafeRelativePath(name), !name.contains("/"), case .string(let path)? = values["wallpaperVideo"] {
            let saved = stage.appendingPathComponent("wallpaper").appendingPathComponent(name)
            if fm.fileExists(atPath: saved.path), !fm.fileExists(atPath: path) {
                let dir = support.appendingPathComponent("Wallpapers", isDirectory: true)
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                let to = dir.appendingPathComponent(name)
                try? fm.removeItem(at: to)
                try fm.moveItem(at: saved, to: to)
                values["wallpaperVideo"] = .string(to.path)
            }
        }
        for (key, _) in settings {
            switch values[key] {
            case .bool(let b): defaults.set(b, forKey: key)
            case .int(let i): defaults.set(i, forKey: key)
            case .string(let s): defaults.set(s, forKey: key)
            case nil: defaults.removeObject(forKey: key)
            }
        }
        return m
    }

    /// A backup Notchi takes by itself before it changes a lot (restore, reset).
    /// Kept in Application Support/Notchi/Backups; only the newest few stay.
    @discardableResult
    public static func automatic(_ label: String, defaults: UserDefaults = .standard, support: URL = supportURL,
                                 appVersion: String = "dev", now: Date = Date()) throws -> URL {
        let fm = FileManager.default
        let dir = support.appendingPathComponent("Backups", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        let file = dir.appendingPathComponent("\(f.string(from: now))-\(label).\(fileExtension)")
        try create(to: file, defaults: defaults, support: support, appVersion: appVersion, now: now)
        let all = ((try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == fileExtension }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        for old in all.dropFirst(keep) { try? fm.removeItem(at: old) }
        return file
    }
}
