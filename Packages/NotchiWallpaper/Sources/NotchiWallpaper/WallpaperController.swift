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

    /// Who picked the wallpaper: you, or the theme you applied.
    public enum Source: String, Sendable { case user, theme }

    public private(set) var url: URL?
    public private(set) var source: Source = .user
    public var isPlaying: Bool { surfaces.contains { $0.player.rate > 0 } }
    /// Why the video is paused, in plain words (nil while playing).
    public private(set) var pauseReason: String?

    private let bus: EventBus
    private let energy: EnergyGovernor
    /// One per screen: the window, its looping player, and the watcher that tells us when it's covered.
    private struct Surface {
        let window: NSWindow
        let player: AVQueuePlayer
        let looper: AVPlayerLooper
        let watcher: NSObjectProtocol
    }
    private var surfaces: [Surface] = []
    /// The previous wallpaper, kept for a moment while the new one fades in.
    private var leaving: [Surface] = []
    /// Counts fades, so a finished fade only clears what it started.
    private var fadeID = 0
    public static let fade: TimeInterval = 0.5
    private static let sourceKey = "wallpaperSource"
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
            let saved = UserDefaults.standard.string(forKey: Self.sourceKey).flatMap(Source.init) ?? .user
            try? set(URL(fileURLWithPath: path), source: saved)
        }
    }

    /// Show a video as the wallpaper. `animated` fades it in over the old one.
    public func set(_ url: URL, source: Source = .user, animated: Bool = false) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { throw WallpaperError.notFound(url.path) }
        let type = UTType(filenameExtension: url.pathExtension)
        guard type?.conforms(to: .movie) == true || type?.conforms(to: .video) == true else { throw WallpaperError.notAVideo(url.lastPathComponent) }
        let same = url == self.url && !surfaces.isEmpty
        self.url = url
        self.source = source
        UserDefaults.standard.set(url.path, forKey: Self.defaultsKey)
        UserDefaults.standard.set(source.rawValue, forKey: Self.sourceKey)
        if !same { build(url, animated: animated) }
    }

    public func turnOff(animated: Bool = false) {
        url = nil
        source = .user
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
        UserDefaults.standard.removeObject(forKey: Self.sourceKey)
        let old = surfaces
        surfaces = []
        guard animated, !energy.budget.reduceMotion, !old.isEmpty else { return remove(old) }
        fadeOut(old)
    }

    private func remove(_ old: [Surface]) {
        for s in old {
            s.player.pause()
            s.window.orderOut(nil)
            NotificationCenter.default.removeObserver(s.watcher)
        }
    }

    private func fadeOut(_ old: [Surface]) {
        remove(leaving)
        leaving = old
        fadeID += 1
        let id = fadeID
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = Self.fade
            leaving.forEach { $0.window.animator().alphaValue = 0 }
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated { self?.fadeEnded(id) }
        })
    }

    private func fadeEnded(_ id: Int) {
        guard id == fadeID else { return }
        remove(leaving)
        leaving = []
    }

    private func build(_ url: URL, animated: Bool = false) {
        let fade = animated && !energy.budget.reduceMotion && !surfaces.isEmpty
        // a fade that's still running is cut short
        remove(leaving)
        fadeID += 1
        leaving = fade ? surfaces : []
        if !fade { remove(surfaces) }
        surfaces = []

        let item = AVPlayerItem(url: url)
        for screen in NSScreen.screens {
            let player = AVQueuePlayer()
            player.isMuted = true
            player.preventsDisplaySleepDuringVideoPlayback = false
            player.actionAtItemEnd = .advance
            let looper = AVPlayerLooper(player: player, templateItem: item.copy() as! AVPlayerItem)

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
            if fade {
                // sit on top of the old wallpaper and fade in
                w.alphaValue = 0
                w.orderFront(nil)
            } else {
                w.orderBack(nil)
            }

            let watcher = NotificationCenter.default.addObserver(forName: NSWindow.didChangeOcclusionStateNotification, object: w, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.updatePlayback() }
            }
            surfaces.append(Surface(window: w, player: player, looper: looper, watcher: watcher))
        }
        updatePlayback()
        guard fade else { return }
        fadeID += 1
        let id = fadeID
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = Self.fade
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            surfaces.forEach { $0.window.animator().alphaValue = 1 }
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated { self?.fadeEnded(id) }
        })
    }

    /// Battery first: only play what someone can actually see.
    private func updatePlayback() {
        let budget = energy.budget
        let allowed = !screensAsleep && budget.fps > 0
        pauseReason = screensAsleep ? "display asleep" : budget.fps == 0 ? (budget.reason ?? "paused") : nil
        if allowed, !surfaces.isEmpty, !surfaces.contains(where: { $0.window.occlusionState.contains(.visible) }) {
            pauseReason = "covered by windows"
        }
        for s in surfaces + leaving {
            let visible = s.window.occlusionState.contains(.visible)
            if allowed && visible {
                if s.player.rate == 0 { s.player.play() }
            } else if s.player.rate > 0 {
                s.player.pause()
            }
        }
    }
}
