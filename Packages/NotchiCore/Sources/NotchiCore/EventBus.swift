import Combine
import Foundation

/// Shared events. Modules never talk to each other directly; they post and listen here.
public enum NotchiEvent: Sendable {
    case themeChanged(Theme)
    case nowPlaying(NowPlaying?)
    case battery(BatteryState)
    case notify(message: String)
    case progress(value: Double, label: String)
    case energy(EnergyGovernor.Budget)
    case volume(level: Double, muted: Bool)
    case brightness(level: Double)
}

public struct NowPlaying: Equatable, Sendable {
    public var title: String
    public var artist: String
    public var album: String
    public var isPlaying: Bool
    public var duration: Double?
    /// Seconds into the track at `positionDate` (it keeps moving while playing).
    public var position: Double?
    public var positionDate: Date?
    public var source: Source
    /// The app that's playing, e.g. "Safari" for a YouTube tab.
    public var appName: String
    public var bundleID: String?
    public var artworkPNG: Data?

    public enum Source: String, Sendable { case music = "Music", spotify = "Spotify", system = "System" }

    public init(title: String, artist: String, album: String, isPlaying: Bool, duration: Double? = nil, position: Double? = nil,
                positionDate: Date? = nil, source: Source, appName: String? = nil, bundleID: String? = nil, artworkPNG: Data? = nil) {
        self.title = title; self.artist = artist; self.album = album; self.isPlaying = isPlaying
        self.duration = duration; self.position = position; self.positionDate = positionDate; self.source = source
        self.appName = appName ?? source.rawValue; self.bundleID = bundleID; self.artworkPNG = artworkPNG
    }

    /// Where playback is right now, moving forward while it plays.
    public func elapsed(at now: Date = .now) -> Double? {
        guard let position else { return nil }
        let moved = isPlaying ? now.timeIntervalSince(positionDate ?? now) : 0
        return min(max(position + moved, 0), duration ?? .infinity)
    }
}

public struct BatteryState: Equatable, Sendable {
    public var level: Double        // 0...1
    public var isCharging: Bool
    public var isPluggedIn: Bool
    public init(level: Double, isCharging: Bool, isPluggedIn: Bool) {
        self.level = level; self.isCharging = isCharging; self.isPluggedIn = isPluggedIn
    }
}

@MainActor
public final class EventBus {
    private let subject = PassthroughSubject<NotchiEvent, Never>()
    public init() {}

    public func post(_ event: NotchiEvent) { subject.send(event) }

    public var events: AnyPublisher<NotchiEvent, Never> { subject.eraseToAnyPublisher() }
}
