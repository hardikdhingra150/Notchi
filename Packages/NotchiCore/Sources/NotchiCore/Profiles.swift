import Foundation

/// Named setups you switch between in one go: "Work", "Night", "Presenting".
/// A profile remembers the same settings a backup does (theme, wallpaper, energy, the
/// volume indicator, where the island sits), but not installed themes or icons.
/// Saved in ~/Library/Application Support/Notchi/profiles.json.
public struct ProfileStore: Sendable {
    public struct Profile: Codable, Equatable, Sendable, Identifiable {
        public var name: String
        public var settings: [String: SetupBackup.Value]
        public var created: Date
        public var id: String { ProfileStore.key(name) }
    }

    public enum ProfileError: Error, Equatable, CustomStringConvertible {
        case badName
        case unknown(String)
        public var description: String {
            switch self {
            case .badName: "A profile name needs 1 to 40 characters."
            case .unknown(let n): "No profile called \"\(n)\". See: notchi profile list"
            }
        }
    }

    public let file: URL
    public init(file: URL = SetupBackup.supportURL.appendingPathComponent("profiles.json")) { self.file = file }

    /// Names match without caring about case or spaces at the ends.
    public static func key(_ name: String) -> String { name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    public func load() -> [Profile] {
        guard let data = try? Data(contentsOf: file) else { return [] }
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return (try? d.decode([Profile].self, from: data)) ?? []
    }

    private func save(_ all: [Profile]) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try e.encode(all).write(to: file, options: .atomic)
    }

    public func profile(named name: String) -> Profile? { load().first { $0.id == Self.key(name) } }

    /// Save what's in `defaults` right now under `name`, replacing a profile with the same name.
    @discardableResult
    public func save(name: String, from defaults: UserDefaults = .standard, now: Date = Date()) throws -> Profile {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...40).contains(clean.count) else { throw ProfileError.badName }
        let p = Profile(name: clean, settings: SetupBackup.currentSettings(defaults), created: now)
        var all = load().filter { $0.id != p.id }
        all.append(p)
        try save(all)
        return p
    }

    /// Write a profile's settings into `defaults`. The caller then tells the app to reload.
    @discardableResult
    public func apply(_ name: String, to defaults: UserDefaults = .standard) throws -> Profile {
        guard let p = profile(named: name) else { throw ProfileError.unknown(name) }
        SetupBackup.write(p.settings, to: defaults)
        return p
    }

    public func remove(_ name: String) throws {
        let all = load()
        guard all.contains(where: { $0.id == Self.key(name) }) else { throw ProfileError.unknown(name) }
        try save(all.filter { $0.id != Self.key(name) })
    }
}
