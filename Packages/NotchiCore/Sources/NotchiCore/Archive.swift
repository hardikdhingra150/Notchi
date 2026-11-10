import Foundation

/// Zip files, read and written with the tools macOS ships (`zipinfo`, `ditto`).
/// Used for `.notchitheme` packages and `.notchibackup` files. Everything that
/// comes out of an archive is checked before Notchi touches it.
public enum Archive {
    public enum ArchiveError: Error, Equatable, CustomStringConvertible {
        case notFound(String)
        case notAnArchive(String)
        case unsafeEntry(String)
        case tooBig(Int64)
        case toolFailed(String)

        public var description: String {
            switch self {
            case .notFound(let p): "No file at \(p)"
            case .notAnArchive(let p): "\(p) isn't a Notchi package (it should be a zip file)."
            case .unsafeEntry(let e): "The package has an entry that points outside itself (\(e)). Not opening it."
            case .tooBig(let b): "The package unpacks to \(b / 1_048_576) MB, which is over the limit."
            case .toolFailed(let m): m
            }
        }
    }

    /// 500 MB unpacked is plenty for a theme with a video or two.
    public static let defaultLimit: Int64 = 500 * 1_048_576

    @discardableResult
    static func run(_ tool: String, _ args: [String]) throws -> (status: Int32, out: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: tool)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()
        do { try p.run() } catch { throw ArchiveError.toolFailed("Couldn't run \(tool): \(error.localizedDescription)") }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    /// The paths inside a zip, without unpacking it.
    public static func entries(of zip: URL) throws -> [String] {
        guard FileManager.default.fileExists(atPath: zip.path) else { throw ArchiveError.notFound(zip.path) }
        let r = try run("/usr/bin/zipinfo", ["-1", zip.path])
        guard r.status == 0 else { throw ArchiveError.notAnArchive(zip.lastPathComponent) }
        return r.out.split(separator: "\n").map(String.init)
    }

    /// Total size once unpacked, as the zip itself reports it.
    static func unpackedSize(of zip: URL) throws -> Int64 {
        let r = try run("/usr/bin/zipinfo", ["-t", zip.path])
        // "12 files, 3456789 bytes uncompressed, 2345678 bytes compressed:  32.1%"
        let words = r.out.split(whereSeparator: { $0 == " " || $0 == "," })
        guard let i = words.firstIndex(of: "bytes"), i > 0, let n = Int64(words[i - 1]) else { return 0 }
        return n
    }

    /// Unpack into `dir` (created if needed). Refuses entries that would land outside it,
    /// links, and anything bigger than `limit`.
    public static func extract(_ zip: URL, to dir: URL, limit: Int64 = defaultLimit) throws {
        for e in try entries(of: zip) {
            let parts = e.split(separator: "/", omittingEmptySubsequences: true)
            if e.hasPrefix("/") || e.hasPrefix("~") || parts.contains("..") { throw ArchiveError.unsafeEntry(e) }
        }
        let size = try unpackedSize(of: zip)
        guard size <= limit else { throw ArchiveError.tooBig(size) }
        let fm = FileManager.default
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let r = try run("/usr/bin/ditto", ["-x", "-k", zip.path, dir.path])
        guard r.status == 0 else { throw ArchiveError.notAnArchive(zip.lastPathComponent) }
        // second look at what actually landed: no links, and the real size
        var total: Int64 = 0
        let keys: [URLResourceKey] = [.isSymbolicLinkKey, .isRegularFileKey, .fileSizeKey]
        let walker = fm.enumerator(at: dir, includingPropertiesForKeys: keys, options: [])
        while let f = walker?.nextObject() as? URL {
            let v = try f.resourceValues(forKeys: Set(keys))
            if v.isSymbolicLink == true {
                try? fm.removeItem(at: dir)
                throw ArchiveError.unsafeEntry(f.lastPathComponent)
            }
            total += Int64(v.fileSize ?? 0)
        }
        if total > limit {
            try? fm.removeItem(at: dir)
            throw ArchiveError.tooBig(total)
        }
    }

    /// Zip the contents of `dir` (not the folder itself) into `zip`, replacing it.
    public static func create(from dir: URL, to zip: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: zip.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? fm.removeItem(at: zip)
        let r = try run("/usr/bin/ditto", ["-c", "-k", "--norsrc", "--noextattr", dir.path, zip.path])
        guard r.status == 0 else { throw ArchiveError.toolFailed("Couldn't write \(zip.path)") }
    }

    /// A fresh folder under the system temp directory.
    public static func scratch(_ label: String) throws -> URL {
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("notchi-\(label)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }
}
