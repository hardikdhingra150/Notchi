import Foundation

/// Themes on disk.
///
/// A theme is a folder with a `theme.json` and the files it uses:
///
///     midnight/
///       theme.json
///       wallpapers/starfield.mp4
///
/// A `.notchitheme` file is that folder zipped, for sharing. A single loose
/// `name.json` also works; its assets resolve against the folder it sits in.
public enum ThemePackage {
    public static let fileExtension = "notchitheme"
    public static let manifestName = "theme.json"

    public enum PackageError: Error, Equatable, CustomStringConvertible {
        case notFound(String)
        case notATheme(String)
        case missingManifest
        case missingAsset(String)

        public var description: String {
            switch self {
            case .notFound(let p): "No file at \(p)"
            case .notATheme(let p): "\(p) isn't a theme. Themes are .notchitheme or .json files."
            case .missingManifest: "The package has no theme.json."
            case .missingAsset(let a): "The theme uses \"\(a)\" but the file isn't in the package."
            }
        }
    }

    /// Read a theme folder or a loose JSON file. `base` is where its asset paths start.
    public static func read(_ url: URL) throws -> (theme: Theme, base: URL) {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { throw PackageError.notFound(url.path) }
        if isDir.boolValue {
            let manifest = url.appendingPathComponent(manifestName)
            guard FileManager.default.fileExists(atPath: manifest.path) else { throw PackageError.missingManifest }
            return (try Theme.decode(Data(contentsOf: manifest)), url)
        }
        return (try Theme.decode(Data(contentsOf: url)), url.deletingLastPathComponent())
    }

    /// The files a theme needs next to its JSON. Shaders and packs arrive in later versions.
    public static func assetPaths(of theme: Theme) -> [String] {
        guard let w = theme.wallpaper, w.type == .video || w.type == .image else { return [] }
        return [w.src]
    }

    /// Where an asset is on disk, or nil when the path is unsafe or the file is missing.
    public static func asset(_ src: String, base: URL) -> URL? {
        guard Theme.isSafeRelativePath(src) else { return nil }
        let u = base.appendingPathComponent(src).standardizedFileURL
        guard u.path.hasPrefix(base.standardizedFileURL.path + "/"), FileManager.default.fileExists(atPath: u.path) else { return nil }
        return u
    }

    /// Install a `.notchitheme` or `.json` into `themesDir/<id>/`, replacing an older copy of the same theme.
    @discardableResult
    public static func install(_ source: URL, into themesDir: URL) throws -> Theme {
        let fm = FileManager.default
        guard fm.fileExists(atPath: source.path) else { throw PackageError.notFound(source.path) }
        let stage = try Archive.scratch("theme")
        defer { try? fm.removeItem(at: stage) }

        let theme: Theme
        var from: URL
        switch source.pathExtension.lowercased() {
        case fileExtension, "zip":
            try Archive.extract(source, to: stage)
            from = stage
            // a package zipped as a folder ("midnight/theme.json") is fine too
            if !fm.fileExists(atPath: from.appendingPathComponent(manifestName).path) {
                let kids = try fm.contentsOfDirectory(at: stage, includingPropertiesForKeys: nil).filter { !$0.lastPathComponent.hasPrefix(".") && $0.lastPathComponent != "__MACOSX" }
                guard kids.count == 1, fm.fileExists(atPath: kids[0].appendingPathComponent(manifestName).path) else { throw PackageError.missingManifest }
                from = kids[0]
            }
            theme = try read(from).theme
            for a in assetPaths(of: theme) where asset(a, base: from) == nil { throw PackageError.missingAsset(a) }
        case "json":
            let loose = try read(source)
            theme = loose.theme
            from = stage
            try fm.copyItem(at: source, to: stage.appendingPathComponent(manifestName))
            // bring along the files it points at, when they're there
            for a in assetPaths(of: theme) {
                guard let file = asset(a, base: loose.base) else { continue }
                let to = stage.appendingPathComponent(a)
                try fm.createDirectory(at: to.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fm.copyItem(at: file, to: to)
            }
        default:
            throw PackageError.notATheme(source.lastPathComponent)
        }

        try fm.createDirectory(at: themesDir, withIntermediateDirectories: true)
        let dest = themesDir.appendingPathComponent(theme.id, isDirectory: true)
        try? fm.removeItem(at: dest)
        try? fm.removeItem(at: themesDir.appendingPathComponent("\(theme.id).json"))
        try fm.moveItem(at: from, to: dest)
        return theme
    }

    /// Write a theme and its assets to a `.notchitheme` file.
    public static func export(_ theme: Theme, base: URL?, to dest: URL) throws {
        let fm = FileManager.default
        let stage = try Archive.scratch("export")
        defer { try? fm.removeItem(at: stage) }
        try theme.encoded().write(to: stage.appendingPathComponent(manifestName))
        for a in assetPaths(of: theme) {
            guard let base, let file = asset(a, base: base) else { throw PackageError.missingAsset(a) }
            let to = stage.appendingPathComponent(a)
            try fm.createDirectory(at: to.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fm.copyItem(at: file, to: to)
        }
        try Archive.create(from: stage, to: dest)
    }
}
