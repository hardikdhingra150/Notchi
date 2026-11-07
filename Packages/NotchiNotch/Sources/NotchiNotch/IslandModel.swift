import Foundation
import NotchiCore
import Observation
import SwiftUI

/// What the island is showing right now.
public enum IslandActivity: Equatable, Sendable {
    case notify(String)
    case progress(Double, String)
    case theme(String)
    case battery(BatteryState)
}

/// All island state lives here (no @State, so it builds without Xcode's SwiftUI macros).
@MainActor
@Observable
public final class IslandModel {
    /// Hardware notch size in points (or the virtual island's size).
    public var notchSize = CGSize(width: 190, height: 32)
    public var isHardwareNotch = true

    public var hovering = false
    public var activity: IslandActivity?
    public var nowPlaying: NowPlaying?
    public var artwork: NSImage?
    public var battery: BatteryState?

    public var accent: Color = .orange
    public var themeName = "Paper"
    public var idleStyle = "breathing"
    public var animate = true
    public var reduceMotion = false

    // controls, wired up by the controller
    public var onPlayPause: () -> Void = {}
    public var onNext: () -> Void = {}
    public var onPrevious: () -> Void = {}

    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    public init() {}

    public enum Mode: Equatable { case closed, compact, banner, expanded }

    public var mode: Mode {
        if hovering { return .expanded }
        if activity != nil { return .banner }
        if nowPlaying?.isPlaying == true { return .compact }
        return .closed
    }

    /// Size of the black island for the current mode.
    public var size: CGSize {
        let w = notchSize.width, h = notchSize.height
        switch mode {
        case .closed: return CGSize(width: w, height: h)
        case .compact: return CGSize(width: w + 2 * (h + 14), height: h)
        case .banner: return CGSize(width: max(w + 150, 380), height: h + 50)
        case .expanded: return CGSize(width: max(w + 300, 520), height: h + 132)
        }
    }

    public var spring: Animation {
        reduceMotion ? .easeInOut(duration: 0.18) : .spring(response: 0.42, dampingFraction: 0.78)
    }

    /// Show an activity, then tuck it back in after `seconds` (nil = stay until replaced).
    public func show(_ a: IslandActivity, for seconds: Double? = 3.5) {
        dismissTask?.cancel()
        withAnimation(spring) { activity = a }
        guard let seconds else { return }
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let self else { return }
            withAnimation(self.spring) { self.activity = nil }
        }
    }

    public func clearActivity() {
        dismissTask?.cancel()
        withAnimation(spring) { activity = nil }
    }
}
