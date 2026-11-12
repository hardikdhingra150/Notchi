import Foundation

/// The wallpaper library on Notchi's website, and the videos you've downloaded from it.
/// Nothing is fetched until you open the Wallpapers window or run `notchi wallpaper list`.
public struct WallpaperLibrary: Sendable {
    public struct Catalog: Codable, Equatable, Sendable {
        public var schema: Int
        public var collections: [Collection]
        public var wallpapers: [Item]
    }

    public struct Collection: Codable, Equatable, Sendable, Identifiable {
        public var id: String
        public var name: String
        public var tagline: String?
        public var note: String?
    }

    public struct Item: Codable, Equatable, Sendable, Identifiable {
        public var id: String
        public var name: String
        public var collection: String
        public var kind: String?
        public var theme: String?
        public var line: String?
        public var credit: String?
        public var video: URL
        public var preview: URL?
        public var poster: URL?
        public var bytes: Int?
    }

    public enum LibraryError: Error, Equatable, CustomStringConvertible {
        case offline(String)
        case badCatalog
        case newerCatalog(Int)
        case unknown(String)
        case unsafeURL(String)
        public var description: String {
            switch self {
            case .offline(let why): "Couldn't reach the wallpaper library: \(why)"
            case .badCatalog: "The wallpaper library sent something Notchi doesn't understand."
            case .newerCatalog(let s): "The wallpaper library uses a newer format (\(s)). Update Notchi to browse it."
            case .unknown(let id): "No wallpaper called \"\(id)\". See: notchi wallpaper list"
            case .unsafeURL(let u): "Refusing to download from \(u): only https links are allowed."
            }
        }
    }

    public static let defaultCatalogURL = URL(string: "https://notchi-plum.vercel.app/wallpapers.json")!

    /// ~/Library/Application Support/Notchi/Wallpapers
    public static var defaultFolder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Notchi/Wallpapers", isDirectory: true)
    }

    public let catalogURL: URL
    public let folder: URL

    public init(catalogURL: URL = Self.defaultCatalogURL, folder: URL = Self.defaultFolder) {
        self.catalogURL = catalogURL
        self.folder = folder
    }

    public static func decode(_ data: Data) throws -> Catalog {
        guard let c = try? JSONDecoder().decode(Catalog.self, from: data) else { throw LibraryError.badCatalog }
        guard c.schema <= 1 else { throw LibraryError.newerCatalog(c.schema) }
        return c
    }

    public func fetchCatalog() async throws -> Catalog {
        do {
            let (data, response) = try await URLSession.shared.data(from: catalogURL)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 { throw LibraryError.offline("HTTP \(http.statusCode)") }
            return try Self.decode(data)
        } catch let e as LibraryError {
            throw e
        } catch {
            throw LibraryError.offline(error.localizedDescription)
        }
    }

    /// Where a wallpaper is saved. Ids are reduced to letters, numbers and dashes so a
    /// catalog entry can never point outside the folder.
    public func localURL(for id: String) -> URL {
        let safe = String(id.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }.prefix(64))
        return folder.appendingPathComponent((safe.isEmpty ? "wallpaper" : safe) + ".mp4")
    }

    public func isDownloaded(_ item: Item) -> Bool {
        FileManager.default.fileExists(atPath: localURL(for: item.id).path)
    }

    /// Download a wallpaper (or reuse the copy you already have) and return the file.
    /// `progress` gets 0...1 while it downloads.
    @discardableResult
    public func download(_ item: Item, progress: @escaping @Sendable (Double) -> Void = { _ in }) async throws -> URL {
        let dest = localURL(for: item.id)
        if FileManager.default.fileExists(atPath: dest.path) { progress(1); return dest }
        guard item.video.scheme == "https" else { throw LibraryError.unsafeURL(item.video.absoluteString) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let delegate = ProgressDelegate(progress)
        let tmp: URL, response: URLResponse
        do {
            (tmp, response) = try await URLSession.shared.download(from: item.video, delegate: delegate)
        } catch {
            throw LibraryError.offline(error.localizedDescription)
        }
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            try? FileManager.default.removeItem(at: tmp)
            throw LibraryError.offline("HTTP \(http.statusCode)")
        }
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tmp, to: dest)
        progress(1)
        return dest
    }

    /// Delete a downloaded wallpaper.
    public func remove(_ item: Item) {
        try? FileManager.default.removeItem(at: localURL(for: item.id))
    }

    /// Bytes used by downloaded wallpapers.
    public func usedBytes() -> Int {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return files.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
    }
}

private final class ProgressDelegate: NSObject, URLSessionDownloadDelegate, Sendable {
    let report: @Sendable (Double) -> Void
    init(_ report: @escaping @Sendable (Double) -> Void) { self.report = report }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 { report(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) }
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}
}
