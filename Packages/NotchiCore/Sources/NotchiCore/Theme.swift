import Foundation

/// A Notchi theme. One file controls every module (blueprint section 10).
public struct Theme: Codable, Equatable, Sendable, Identifiable {
    public var schema: Int
    public var id: String
    public var name: String
    public var author: String
    public var version: String
    public var appearance: Appearance
    public var accent: HexColor
    public var glass: Glass
    public var wallpaper: Wallpaper?
    public var icons: Icons?
    public var notch: Notch
    public var sidebar: Sidebar?
    public var dock: Dock?
    public var menuBar: MenuBar?
    public var sounds: Sounds?
    public var cursor: Cursor?

    public enum Appearance: String, Codable, Sendable { case light, dark, auto }

    public struct Glass: Codable, Equatable, Sendable {
        public var blur: Double
        public var tint: Double
    }
    public struct Wallpaper: Codable, Equatable, Sendable {
        public var type: Kind
        public var src: String
        public var fps: Int?
        public enum Kind: String, Codable, Sendable { case video, shader, particles, image }
    }
    public struct Icons: Codable, Equatable, Sendable {
        public var pack: String
        public var tintFolders: Bool?
    }
    public struct Notch: Codable, Equatable, Sendable {
        /// "accent", "none" or a hex colour
        public var glow: String
        /// what the closed notch does when nothing is happening (see `idleStyles`)
        public var idle: String
        public var visualizer: Bool?

        public static let idleStyles = ["breathing", "sparks", "rain", "pet", "none"]
    }
    public struct Sidebar: Codable, Equatable, Sendable { public var widgets: [String] }
    public struct Dock: Codable, Equatable, Sendable {
        public var style: String
        public var magnify: Double?
    }
    public struct MenuBar: Codable, Equatable, Sendable {
        public var tint: String
        public var opacity: Double
    }
    public struct Sounds: Codable, Equatable, Sendable { public var pack: String }
    public struct Cursor: Codable, Equatable, Sendable { public var trail: String }

    public static let currentSchema = 1

    /// The fallback theme, always available even when no theme files load.
    public static let paper = Theme(
        schema: 1, id: "paper", name: "Paper", author: "notchi", version: "1.0.0",
        appearance: .light, accent: HexColor("#FF6A3D")!,
        glass: .init(blur: 0.6, tint: 0.2),
        wallpaper: .init(type: .video, src: "wallpapers/ink-tide.mp4", fps: 30),
        icons: .init(pack: "default", tintFolders: true),
        notch: .init(glow: "accent", idle: "breathing", visualizer: true),
        sidebar: .init(widgets: ["nowPlaying", "calendar", "stats"]),
        dock: .init(style: "floating-glass", magnify: 1.4),
        menuBar: .init(tint: "accent", opacity: 0.4),
        sounds: .init(pack: "soft-pencil"),
        cursor: .init(trail: "ring")
    )
}

public enum ThemeError: Error, Equatable, CustomStringConvertible {
    case unsupportedSchema(Int)
    case invalidID(String)
    case outOfRange(String)
    case empty(String)
    case badPath(String)
    case badValue(String)

    public var description: String {
        switch self {
        case .empty(let field): "\(field) can't be empty."
        case .badPath(let p): "\"\(p)\" must be a path inside the theme's own folder (no \"..\" and no leading \"/\")."
        case .badValue(let what): what
        case .unsupportedSchema(let s): "Unsupported theme schema \(s). This version of Notchi reads schema \(Theme.currentSchema)."
        case .invalidID(let id): "Theme id \"\(id)\" must be lowercase letters, numbers and dashes."
        case .outOfRange(let field): "\(field) must be between 0 and 1."
        }
    }
}

extension Theme {
    /// Decode and validate a theme file.
    public static func decode(_ data: Data) throws -> Theme {
        let theme = try JSONDecoder().decode(Theme.self, from: data)
        try theme.validate()
        return theme
    }

    public func validate() throws {
        guard schema == Theme.currentSchema else { throw ThemeError.unsupportedSchema(schema) }
        guard !id.isEmpty, id.allSatisfy({ $0.isLowercase || $0.isNumber || $0 == "-" }) else { throw ThemeError.invalidID(id) }
        guard (0...1).contains(glass.blur) else { throw ThemeError.outOfRange("glass.blur") }
        guard (0...1).contains(glass.tint) else { throw ThemeError.outOfRange("glass.tint") }
        if let m = menuBar, !(0...1).contains(m.opacity) { throw ThemeError.outOfRange("menuBar.opacity") }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw ThemeError.empty("name") }
        guard id.count <= 64 else { throw ThemeError.invalidID(id) }
        if let w = wallpaper {
            guard Theme.isSafeRelativePath(w.src) else { throw ThemeError.badPath(w.src) }
            if let fps = w.fps, !(1...60).contains(fps) { throw ThemeError.badValue("wallpaper.fps must be between 1 and 60.") }
        }
        guard notch.glow == "accent" || notch.glow == "none" || HexColor(notch.glow) != nil else {
            throw ThemeError.badValue("notch.glow must be \"accent\", \"none\" or a colour like #FF6A3D.")
        }
    }

    /// Things that still load but won't do anything in this version, for `notchi theme validate`.
    public func warnings() -> [String] {
        var out: [String] = []
        if !Notch.idleStyles.contains(notch.idle) {
            out.append("notch.idle \"\(notch.idle)\" isn't known; the notch will breathe. Known: \(Notch.idleStyles.joined(separator: ", ")).")
        }
        if let w = wallpaper, w.type != .video {
            out.append("wallpaper.type \"\(w.type.rawValue)\" arrives in a later version; only \"video\" changes the wallpaper today.")
        }
        return out
    }

    /// The colour the notch glows in, or nil for no glow.
    public var glowColor: HexColor? {
        switch notch.glow {
        case "accent": accent
        case "none": nil
        default: HexColor(notch.glow)
        }
    }

    /// Asset paths are relative to the theme's folder and may not leave it.
    public static func isSafeRelativePath(_ path: String) -> Bool {
        guard !path.isEmpty, !path.hasPrefix("/"), !path.hasPrefix("~"), !path.contains("\\") else { return false }
        return !path.split(separator: "/", omittingEmptySubsequences: false).contains { $0 == ".." || $0.isEmpty }
    }

    /// The theme as pretty JSON, the way theme files are written.
    public func encoded() throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try enc.encode(self)
    }
}

/// A colour written as "#RRGGBB" or "#RRGGBBAA".
public struct HexColor: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    public let red: Double, green: Double, blue: Double, alpha: Double

    public init?(_ string: String) {
        var s = string.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8, let v = UInt64(s, radix: 16) else { return nil }
        let full = s.count == 6 ? (v << 8) | 0xFF : v
        red = Double((full >> 24) & 0xFF) / 255
        green = Double((full >> 16) & 0xFF) / 255
        blue = Double((full >> 8) & 0xFF) / 255
        alpha = Double(full & 0xFF) / 255
    }

    public init(from decoder: Decoder) throws {
        let s = try decoder.singleValueContainer().decode(String.self)
        guard let c = HexColor(s) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not a hex colour: \(s)"))
        }
        self = c
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(description)
    }

    public var description: String {
        let h = { (v: Double) in String(format: "%02X", Int((v * 255).rounded())) }
        return "#" + h(red) + h(green) + h(blue) + (alpha < 1 ? h(alpha) : "")
    }
}
