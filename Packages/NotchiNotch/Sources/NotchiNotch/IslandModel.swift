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
    case volume(Double, Bool)
    case brightness(Double)

    /// Volume and brightness use the smaller level indicator.
    var isLevel: Bool {
        switch self {
        case .volume, .brightness: return true
        default: return false
        }
    }
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

    // file shelf
    public var shelf: [URL] = []
    public var dropTargeted = false
    /// Rendering to an image (snapshots): skip AppKit-backed modifiers ImageRenderer can't draw.
    public var isSnapshot = false
    var showsShelf: Bool { !shelf.isEmpty || dropTargeted }

    // pages of the open island: Home, what's playing, the shelf
    public enum Page: Hashable, Sendable { case home, player, shelf }
    public var page: Page = .home
    /// Direction of the last page change, for the slide animation.
    var pageForward = true
    @ObservationIgnored private var pageReturn: Task<Void, Never>?
    /// How long a non-Home page stays without interaction before sliding back Home.
    public var pageReturnDelay: Double = 10

    public var pages: [Page] {
        var p: [Page] = [.home]
        if nowPlaying != nil { p.append(.player) }
        if showsShelf { p.append(.shelf) }
        return p
    }

    public var currentPage: Page { pages.contains(page) ? page : .home }

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
        case .banner:
            if activity?.isLevel == true { return CGSize(width: max(w + 110, 320), height: h + 40) }
            return CGSize(width: max(w + 150, 380), height: h + 50)
        case .expanded: return CGSize(width: max(w + 300, 520), height: h + 132 + (pages.count > 1 ? 14 : 0))
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

    // MARK: Pages

    public func go(to p: Page) {
        let ps = pages
        let from = ps.firstIndex(of: currentPage) ?? 0
        let to = ps.firstIndex(of: p) ?? 0
        guard p != currentPage else { return scheduleReturn() }
        pageForward = to > from
        withAnimation(spring) { page = p }
        scheduleReturn()
    }

    /// Next (+1) or previous (-1) page, e.g. from a trackpad swipe.
    public func step(_ delta: Int) {
        let ps = pages
        guard let i = ps.firstIndex(of: currentPage), ps.indices.contains(i + delta) else { return }
        go(to: ps[i + delta])
    }

    /// The pointer moved or something was clicked: keep the current page a while longer.
    public func interacted() {
        if currentPage != .home { scheduleReturn() }
    }

    /// Back to Home without animation (the island is closing anyway).
    public func resetPage() {
        pageReturn?.cancel()
        page = .home
        pageForward = true
    }

    private func scheduleReturn() {
        pageReturn?.cancel()
        guard currentPage != .home else { return }
        let delay = pageReturnDelay
        pageReturn = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, !Task.isCancelled, !self.dropTargeted else { return }
            self.pageForward = false
            withAnimation(self.spring) { self.page = .home }
        }
    }

    public func addToShelf(_ urls: [URL]) {
        withAnimation(spring) {
            for u in urls where !shelf.contains(u) { shelf.append(u) }
            if shelf.count > 12 { shelf.removeFirst(shelf.count - 12) }
        }
    }

    public func removeFromShelf(_ url: URL) {
        withAnimation(spring) { shelf.removeAll { $0 == url } }
    }

    public func clearActivity() {
        dismissTask?.cancel()
        withAnimation(spring) { activity = nil }
    }
}
