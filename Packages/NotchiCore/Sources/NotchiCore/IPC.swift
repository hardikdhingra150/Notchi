import Foundation

/// Messages from the `notchi` command-line tool to the running app.
/// Sent as JSON over a local distributed notification; nothing leaves the Mac.
public enum IPCCommand: Codable, Equatable, Sendable {
    case notify(message: String)
    case progress(value: Double, label: String)
    case apply(theme: String, replyTo: String?)
    case ping(replyTo: String)
    /// nil path turns the video wallpaper off
    case wallpaper(path: String?, replyTo: String)
}

public struct IPCReply: Codable, Equatable, Sendable {
    public var ok: Bool
    public var message: String
    public var themes: [String]?
    public var activeTheme: String?
    public var version: String?
    public var island: String?
    public var nowPlaying: String?
    public var hardwareNotch: Bool?
    public var wallpaper: String?
    public var accent: String?

    public init(ok: Bool, message: String, themes: [String]? = nil, activeTheme: String? = nil, version: String? = nil,
                island: String? = nil, nowPlaying: String? = nil, hardwareNotch: Bool? = nil, wallpaper: String? = nil, accent: String? = nil) {
        self.ok = ok; self.message = message; self.themes = themes; self.activeTheme = activeTheme; self.version = version
        self.island = island; self.nowPlaying = nowPlaying; self.hardwareNotch = hardwareNotch
        self.wallpaper = wallpaper
        self.accent = accent
    }
}

public enum IPC {
    public static let bundleID = "app.notchi.Notchi"
    public static let commandName = Notification.Name("app.notchi.command")
    public static let replyName = Notification.Name("app.notchi.reply")
    static let payloadKey = "payload"

    public static func encode<T: Encodable>(_ value: T) -> [AnyHashable: Any] {
        let data = (try? JSONEncoder().encode(value)) ?? Data()
        return [payloadKey: String(decoding: data, as: UTF8.self)]
    }

    public static func decode<T: Decodable>(_ type: T.Type, from userInfo: [AnyHashable: Any]?) -> T? {
        guard let s = userInfo?[payloadKey] as? String else { return nil }
        return try? JSONDecoder().decode(T.self, from: Data(s.utf8))
    }

    public static func send(_ command: IPCCommand) {
        DistributedNotificationCenter.default().postNotificationName(
            commandName, object: nil, userInfo: encode(command), deliverImmediately: true)
    }

    public static func reply(_ reply: IPCReply, to token: String) {
        DistributedNotificationCenter.default().postNotificationName(
            replyName, object: token, userInfo: encode(reply), deliverImmediately: true)
    }
}
