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
}

public struct NowPlaying: Equatable, Sendable {
    public var title: String
    public var artist: String
    public var album: String
    public var isPlaying: Bool
    public var duration: Double?
    public var position: Double?
    public var source: Source
    public var artworkPNG: Data?

    public enum Source: String, Sendable { case music = "Music", spotify = "Spotify" }

    public init(title: String, artist: String, album: String, isPlaying: Bool, duration: Double? = nil, position: Double? = nil, source: Source, artworkPNG: Data? = nil) {
        self.title = title; self.artist = artist; self.album = album; self.isPlaying = isPlaying
        self.duration = duration; self.position = position; self.source = source; self.artworkPNG = artworkPNG
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
