import AppKit
import Foundation

/// What's playing in Music or Spotify, using only public, documented routes:
/// - both apps broadcast track changes as distributed notifications (no permission needed)
/// - artwork and controls go through AppleScript (macOS asks for Automation permission once)
@MainActor
public final class NowPlayingService {
    private let bus: EventBus
    private var observers: [NSObjectProtocol] = []
    public private(set) var current: NowPlaying?
    private var lastArtworkKey: String?
    /// Fired when artwork for the current track is ready.
    public var onArtwork: (NSImage?) -> Void = { _ in }

    public init(bus: EventBus) { self.bus = bus }

    public func start() {
        let dnc = DistributedNotificationCenter.default()
        observers.append(dnc.addObserver(forName: .init("com.apple.Music.playerInfo"), object: nil, queue: .main) { [weak self] n in
            let info = Self.sendable(n.userInfo)
            MainActor.assumeIsolated { self?.update(info, source: .music) }
        })
        observers.append(dnc.addObserver(forName: .init("com.spotify.client.PlaybackStateChanged"), object: nil, queue: .main) { [weak self] n in
            let info = Self.sendable(n.userInfo)
            MainActor.assumeIsolated { self?.update(info, source: .spotify) }
        })
        // if the player quits, clear the island
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { [weak self] n in
            let id = (n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
            MainActor.assumeIsolated {
                guard let self, let cur = self.current, id == Self.bundleID(cur.source) else { return }
                self.current = nil
                self.bus.post(.nowPlaying(nil))
            }
        })
    }

    private nonisolated static func sendable(_ info: [AnyHashable: Any]?) -> [String: String] {
        var out: [String: String] = [:]
        info?.forEach { k, v in out["\(k)"] = "\(v)" }
        return out
    }

    private func update(_ info: [String: String], source: NowPlaying.Source) {
        let state = info["Player State"] ?? "Stopped"
        guard state != "Stopped", let title = info["Name"], !title.isEmpty else {
            current = nil
            bus.post(.nowPlaying(nil))
            return
        }
        // Music reports milliseconds in "Total Time"; Spotify reports ms in "Duration"
        let ms = Double(info["Total Time"] ?? info["Duration"] ?? "")
        let np = NowPlaying(
            title: title, artist: info["Artist"] ?? "", album: info["Album"] ?? "",
            isPlaying: state == "Playing", duration: ms.map { $0 / 1000 },
            position: Double(info["Playback Position"] ?? ""), source: source)
        current = np
        bus.post(.nowPlaying(np))

        let key = "\(source.rawValue)|\(np.title)|\(np.album)"
        if key != lastArtworkKey {
            lastArtworkKey = key
            onArtwork(source == .music ? Self.musicArtwork() : nil)
        }
    }

    // MARK: Controls

    public func playPause() { send("playpause") }
    public func next() { send("next track") }
    public func previous() { send("previous track") }

    private func send(_ command: String) {
        guard let src = current?.source, Self.isRunning(src) else { return }
        let app = src == .music ? "Music" : "Spotify"
        Self.run("tell application \"\(app)\" to \(command)")
    }

    private static func bundleID(_ s: NowPlaying.Source) -> String {
        s == .music ? "com.apple.Music" : "com.spotify.client"
    }

    @discardableResult
    private static func run(_ source: String) -> NSAppleEventDescriptor? {
        var err: NSDictionary?
        let out = NSAppleScript(source: source)?.executeAndReturnError(&err)
        return err == nil ? out : nil
    }

    /// Never launch a player just to talk to it.
    static func isRunning(_ s: NowPlaying.Source) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID(s)).isEmpty
    }

    private static func musicArtwork() -> NSImage? {
        guard isRunning(.music), let d = run("tell application \"Music\" to if (count of artworks of current track) > 0 then get raw data of artwork 1 of current track")?.data,
              !d.isEmpty else { return nil }
        return NSImage(data: d)
    }
}
