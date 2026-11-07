import AppKit
import NotchiCore
import UniformTypeIdentifiers

/// Custom icons for folders, files and apps, with a ledger so every change can be undone.
/// Uses the public NSWorkspace.setIcon API. Apple's own apps protected by
/// System Integrity Protection can't be changed, and that's on purpose.
@MainActor
public struct IconStudio {
    public enum Badge: Equatable, Sendable {
        case emoji(String)
        case image(URL)
        case none
    }

    public struct Change: Codable, Equatable, Sendable {
        public var path: String
        public var badge: String
        public var tint: String?
        public var date: Date
    }

    public enum IconError: Error, CustomStringConvertible {
        case notFound(String), protected(String), badImage(String)
        public var description: String {
            switch self {
            case .notFound(let p): "No file or folder at \(p)"
            case .protected(let p): "macOS didn't allow changing \(p). Apple's built-in apps are protected (SIP)."
            case .badImage(let p): "Couldn't read an image from \(p)"
            }
        }
    }

    public let ledgerURL: URL

    public init(ledgerURL: URL = IconStudio.defaultLedger) { self.ledgerURL = ledgerURL }

    public static var defaultLedger: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Notchi/icons.json")
    }

    // MARK: Rendering

    /// A folder icon with an optional accent tint and an emoji or image badge.
    public static func folderIcon(badge: Badge, tint: HexColor?, size: CGFloat = 512) -> NSImage {
        let base = NSWorkspace.shared.icon(for: .folder)
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            base.draw(in: rect)
            if let t = tint {
                // recolour while keeping the folder's shading
                ctx.saveGState()
                if let cg = base.cgImage(forProposedRect: nil, context: nil, hints: nil) { ctx.clip(to: rect, mask: cg) }
                ctx.setBlendMode(.color)
                ctx.setFillColor(CGColor(srgbRed: t.red, green: t.green, blue: t.blue, alpha: 1))
                ctx.fill(rect)
                ctx.restoreGState()
            }
            // the badge sits on the front of the folder
            let b = NSRect(x: rect.midX - size * 0.21, y: size * 0.2, width: size * 0.42, height: size * 0.42)
            switch badge {
            case .emoji(let e):
                let font = NSFont.systemFont(ofSize: size * 0.34)
                let s = NSAttributedString(string: e, attributes: [.font: font])
                let sz = s.size()
                s.draw(at: NSPoint(x: b.midX - sz.width / 2, y: b.midY - sz.height / 2))
            case .image(let url):
                NSImage(contentsOf: url)?.draw(in: b)
            case .none:
                break
            }
            return true
        }
    }

    /// Parse what the user typed: an image file path, else treat it as an emoji/text badge.
    public static func badge(from arg: String) -> Badge {
        let path = (arg as NSString).expandingTildeInPath
        if FileManager.default.fileExists(atPath: path),
           let t = UTType(filenameExtension: (path as NSString).pathExtension), t.conforms(to: .image) {
            return .image(URL(fileURLWithPath: path))
        }
        return .emoji(String(arg.prefix(4)))
    }

    // MARK: Changing icons

    @discardableResult
    public func set(_ path: String, badge: Badge, tint: HexColor?) throws -> NSImage {
        let path = (path as NSString).expandingTildeInPath
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else { throw IconError.notFound(path) }
        let image: NSImage
        if isDir.boolValue && !path.hasSuffix(".app") {
            image = Self.folderIcon(badge: badge, tint: tint)
        } else if case .image(let u) = badge, let img = NSImage(contentsOf: u) {
            image = img  // files and apps take the picture as-is
        } else if case .image(let u) = badge {
            throw IconError.badImage(u.path)
        } else {
            image = Self.folderIcon(badge: badge, tint: tint)
        }
        guard NSWorkspace.shared.setIcon(image, forFile: path, options: []) else { throw IconError.protected(path) }
        var all = load().filter { $0.path != path }
        let label: String = switch badge {
        case .emoji(let e): e
        case .image(let u): u.lastPathComponent
        case .none: ""
        }
        all.append(Change(path: path, badge: label, tint: tint?.description, date: Date()))
        save(all)
        return image
    }

    /// Put back the original icon.
    public func restore(_ path: String) -> Bool {
        let path = (path as NSString).expandingTildeInPath
        let ok = NSWorkspace.shared.setIcon(nil, forFile: path, options: [])
        save(load().filter { $0.path != path })
        return ok
    }

    /// Put back every icon Notchi changed. Returns how many were restored.
    public func restoreAll() -> Int {
        let all = load()
        var n = 0
        for c in all where FileManager.default.fileExists(atPath: c.path) {
            if NSWorkspace.shared.setIcon(nil, forFile: c.path, options: []) { n += 1 }
        }
        save([])
        return n
    }

    public func load() -> [Change] {
        guard let d = try? Data(contentsOf: ledgerURL) else { return [] }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return (try? dec.decode([Change].self, from: d)) ?? []
    }

    private func save(_ changes: [Change]) {
        try? FileManager.default.createDirectory(at: ledgerURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? enc.encode(changes).write(to: ledgerURL)
    }
}

extension NSImage {
    public func pngData() -> Data? {
        guard let tiff = tiffRepresentation else { return nil }
        return NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    }
}
