import AppKit
import Foundation

/// System-wide Now Playing: whatever macOS shows in Control Center, from any app
/// (a YouTube tab in Safari or Chrome, Music, Spotify, Podcasts, VLC, IINA…).
///
/// macOS 15.4+ only lets Apple-signed processes read this, so Notchi runs
/// `/usr/bin/perl` with a tiny helper library (Helpers/MediaRemoteBridge) that
/// streams JSON lines back. Nothing leaves the Mac. If the helper is missing or
/// stops working on a future macOS, `start()` returns false and Notchi falls back
/// to the Music and Spotify notifications.
@MainActor
final class MediaRemoteBridge {
    struct Paths { let script: URL; let library: URL }

    var onUpdate: (NowPlaying?, NSImage??) -> Void = { _, _ in }
    /// The helper never worked on this Mac; the caller should fall back.
    var onFailure: () -> Void = {}

    private let paths: Paths
    private var process: Process?
    private var buffer = Data()
    private var restarts = 0
    private var gotData = false

    init?(bundle: Bundle = .main) {
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/perl"),
              let script = bundle.url(forResource: "notchi-nowplaying", withExtension: "pl"),
              let lib = bundle.url(forResource: "MediaRemoteBridge", withExtension: "dylib") else { return nil }
        paths = Paths(script: script, library: lib)
    }

    func start() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        p.arguments = [paths.script.path, paths.library.path, "stream"]
        let out = Pipe()
        p.standardOutput = out
        p.standardInput = Pipe()  // the helper quits when this closes (Notchi quits)
        p.standardError = FileHandle.nullDevice
        out.fileHandleForReading.readabilityHandler = { [weak self] h in
            let chunk = h.availableData
            Task { @MainActor in self?.received(chunk) }
        }
        p.terminationHandler = { [weak self] _ in
            Task { @MainActor in self?.exited() }
        }
        do { try p.run(); process = p } catch { process = nil }
    }

    func stop() {
        process?.terminationHandler = nil
        process?.terminate()
        process = nil
    }

    /// play, pause, toggle, next, previous
    func send(_ command: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        p.arguments = [paths.script.path, paths.library.path, "command"]
        p.environment = ["NOTCHI_MR_COMMAND": command]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
    }

    func seek(to seconds: Double) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        p.arguments = [paths.script.path, paths.library.path, "command"]
        p.environment = ["NOTCHI_MR_COMMAND": "seek", "NOTCHI_MR_ARG": String(seconds)]
        try? p.run()
    }

    private func exited() {
        process = nil
        // restart a few times if it crashes; give up after that
        guard restarts < (gotData ? 5 : 2) else {
            if !gotData { onFailure() }
            return
        }
        restarts += 1
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Double(restarts) * 2))
            self.start()
        }
    }

    private func received(_ chunk: Data) {
        guard !chunk.isEmpty else { return }
        buffer.append(chunk)
        while let nl = buffer.firstIndex(of: 0x0A) {
            let line = buffer[buffer.startIndex..<nl]
            buffer.removeSubrange(buffer.startIndex...nl)
            if let obj = try? JSONSerialization.jsonObject(with: line) as? [String: Any] { handle(obj) }
        }
    }

    private func handle(_ o: [String: Any]) {
        if o["error"] != nil { stop(); onFailure(); return }
        gotData = true
        restarts = 0
        guard o["empty"] == nil, let title = o["title"] as? String else { return onUpdate(nil, .some(nil)) }
        let pid = (o["pid"] as? NSNumber)?.int32Value ?? 0
        let app = pid > 0 ? NSRunningApplication(processIdentifier: pid) : nil
        var date: Date?
        if let ts = (o["timestamp"] as? NSNumber)?.doubleValue { date = Date(timeIntervalSince1970: ts) }
        let np = NowPlaying(
            title: title,
            artist: o["artist"] as? String ?? "",
            album: o["album"] as? String ?? "",
            isPlaying: (o["playing"] as? Bool) ?? false,
            duration: (o["duration"] as? NSNumber)?.doubleValue,
            position: (o["elapsed"] as? NSNumber)?.doubleValue,
            positionDate: date,
            source: Self.source(for: app?.bundleIdentifier),
            appName: app?.localizedName ?? "Now Playing",
            bundleID: app?.bundleIdentifier)
        // artwork: new image, "same as before" (.none = leave it), or nothing (use the app icon)
        let artwork: NSImage??
        if let b64 = o["artwork"] as? String, let d = Data(base64Encoded: b64) {
            artwork = .some(NSImage(data: d))
        } else if o["artworkSame"] != nil {
            artwork = .none
        } else {
            artwork = .some(nil)
        }
        onUpdate(np, artwork)
    }

    private static func source(for bundleID: String?) -> NowPlaying.Source {
        switch bundleID {
        case "com.apple.Music": .music
        case "com.spotify.client": .spotify
        default: .system
        }
    }
}
