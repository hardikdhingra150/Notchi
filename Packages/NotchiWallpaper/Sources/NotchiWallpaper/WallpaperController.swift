import AppKit
import AVFoundation
import Combine
import NotchiCore
import UniformTypeIdentifiers

/// A looping, muted video behind your desktop icons, one window per screen.
/// It pauses whenever it isn't seen: covered by windows or a full-screen app,
/// display asleep, Low Power Mode, or on battery if you chose that.
@MainActor
public final class WallpaperController {
    public enum WallpaperError: Error, CustomStringConvertible {
        case notFound(String), notAVideo(String)
        public var description: String {
            switch self {
            case .notFound(let p): "No file at \(p)"
            case .notAVideo(let p): "\(p) isn't a video (MP4 or MOV)"
            }
        }
    }

    public private(set) var url: URL?
    public var isPlaying: Bool { players.contains { $0.rate > 0 } }
    /// Why the video is paused, in plain words (nil while playing).
    public private(set) var pauseReason: String?

    private let bus: EventBus
    private let energy: EnergyGovernor
    private var windows: [NSWindow] = []
    private var players: [AVQueuePlayer] = []
    private var loopers: [AVPlayerLooper] = []
    private var subs = Set<AnyCancellable>()
    private var observers: [NSObjectProtocol] = []
    private var screensAsleep = false
    private static let defaultsKey = "wallpaperVideo"

    public init(bus: EventBus, energy: EnergyGovernor) {
        self.bus = bus
        self.energy = energy
    }

    public func start() {
        let ws = NSWorkspace.shared.notificationCenter
        for (name, asleep) in [(NSWorkspace.screensDidSleepNotification, true), (NSWorkspace.screensDidWakeNotification, false),
                               (NSWorkspace.sessionDidResignActiveNotification, true), (NSWorkspace.sessionDidBecomeActiveNotification, false)] {
            observers.append(ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.screensAsleep = asleep; self?.updatePlayback() }
            })
        }
        observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { if let u = self?.url { self?.build(u) } }
        })
        bus.events.receive(on: RunLoop.main).sink { [weak self] e in
            if case .energy = e { MainActor.assumeIsolated { self?.updatePlayback() } }
        }.store(in: &subs)

        if let path = UserDefaults.standard.string(forKey: Self.defaultsKey) {
            try? set(URL(fileURLWithPath: path))
        }
    }

    public func set(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { throw WallpaperError.notFound(url.path) }
        let type = UTType(filenameExtension: url.pathExtension)
        guard type?.conforms(to: .movie) == true || type?.conforms(to: .video) == true else { throw WallpaperError.notAVideo(url.lastPathComponent) }
        self.url = url
        UserDefaults.standard.set(url.path, forKey: Self.defaultsKey)
        build(url)
    }

    public func turnOff() {
        url = nil
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
        teardown()
    }

    private func teardown() {
        players.forEach { $0.pause() }
        windows.forEach { $0.orderOut(nil) }
        windows = []; players = []; loopers = []
    }

    private func build(_ url: URL) {
        teardown()
        let item = AVPlayerItem(url: url)
        for screen in NSScreen.screens {
            let player = AVQueuePlayer()
            player.isMuted = true
            player.preventsDisplaySleepDuringVideoPlayback = false
            player.actionAtItemEnd = .advance
            loopers.append(AVPlayerLooper(player: player, templateItem: item.copy() as! AVPlayerItem))

            let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
            w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
            w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            w.ignoresMouseEvents = true
            w.isReleasedWhenClosed = false
            w.backgroundColor = .black
            w.hasShadow = false
            let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.wantsLayer = true
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            layer.frame = view.bounds
            layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            view.layer?.addSublayer(layer)
            w.contentView = view
            w.setFrame(screen.frame, display: false)
            w.orderBack(nil)

            observers.append(NotificationCenter.default.addObserver(forName: NSWindow.didChangeOcclusionStateNotification, object: w, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.updatePlayback() }
            })
            windows.append(w)
            players.append(player)
        }
        updatePlayback()
    }

    /// Battery first: only play what someone can actually see.
    private func updatePlayback() {
        let budget = energy.budget
        let allowed = !screensAsleep && budget.fps > 0
        pauseReason = screensAsleep ? "display asleep" : budget.fps == 0 ? (budget.reason ?? "paused") : nil
        if allowed, !windows.isEmpty, !windows.contains(where: { $0.occlusionState.contains(.visible) }) {
            pauseReason = "covered by windows"
        }
        for (w, p) in zip(windows, players) {
            let visible = w.occlusionState.contains(.visible)
            if allowed && visible {
                if p.rate == 0 { p.play() }
            } else if p.rate > 0 {
                p.pause()
            }
        }
    }
}
