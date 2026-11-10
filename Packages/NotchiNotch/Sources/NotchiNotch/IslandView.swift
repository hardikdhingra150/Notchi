import NotchiCore
import SwiftUI

private let ink = Color(red: 0.95, green: 0.93, blue: 0.89)
private let dim = Color(red: 0.66, green: 0.64, blue: 0.58)
private let ear: CGFloat = 7

/// The island itself. It hangs from the top of its window, centred on the notch.
public struct IslandView: View {
    @Bindable var model: IslandModel

    public init(model: IslandModel) { self.model = model }

    public var body: some View {
        let s = model.size
        let mode = model.mode
        ZStack(alignment: .top) {
            NotchShape(topRadius: ear, bottomRadius: mode == .expanded ? 30 : mode == .banner ? 22 : 12)
                .fill(Color.black)
                .shadow(color: model.activity != nil || mode == .expanded ? model.glow.opacity(0.45) : .clear, radius: 18, y: 4)
                .overlay(alignment: .bottom) { if mode == .closed { IdleGlow(model: model) } }

            content(mode)
                .frame(width: s.width, height: s.height, alignment: .top)
                .clipped()
        }
        .frame(width: s.width + 2 * ear, height: s.height)
        .modifier(ShelfDrop(model: model))
        .animation(model.spring, value: mode)
        .animation(model.spring, value: model.pages)
        .animation(model.spring, value: model.activity)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Notchi island")
    }

    /// Pages slide in from the side you're heading to.
    private var pageSlide: AnyTransition {
        .push(from: model.pageForward ? .trailing : .leading)
    }

    @ViewBuilder private func content(_ mode: IslandModel.Mode) -> some View {
        let top = model.notchSize.height
        switch mode {
        case .closed:
            EmptyView()
        case .compact:
            HStack {
                Artwork(image: model.artwork, accent: model.accent, size: top - 10, radius: 6)
                Spacer()
                if model.showsVisualizer {
                    Visualizer(accent: model.accent, playing: model.animate, bars: 4, height: top - 14)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: top)
            .transition(.opacity)
        case .banner:
            VStack(spacing: 0) {
                Color.clear.frame(height: top)
                BannerContent(model: model)
                    .padding(.horizontal, 22)
                    .frame(maxHeight: .infinity)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .top)))
        case .expanded:
            VStack(spacing: 0) {
                Color.clear.frame(height: top)
                ZStack {
                    switch model.currentPage {
                    case .home:
                        HomeContent(model: model).transition(pageSlide)
                    case .player:
                        if let np = model.nowPlaying { PlayerContent(model: model, np: np).transition(pageSlide) }
                    case .shelf:
                        ShelfView(model: model).frame(maxHeight: .infinity).transition(pageSlide)
                    }
                }
                .frame(height: 114)
                .clipped()
                if model.pages.count > 1 {
                    PageDots(model: model)
                        .frame(height: 14)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 16)
            .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .top)))
        }
    }
}

// MARK: - Pieces

/// What the closed notch does while nothing is happening. The theme picks the style
/// (notch.idle); it's off when the energy budget or Reduce Motion says so.
struct IdleGlow: View {
    @Bindable var model: IslandModel
    var body: some View {
        if model.animate && !model.reduceMotion && model.idleStyle != "none" {
            let w = model.notchSize.width * 0.36
            switch model.idleStyle {
            case "sparks", "rain", "pet":
                IdleCanvas(style: model.idleStyle, color: model.accent)
                    .frame(width: w, height: 8)
                    .padding(.bottom, 2)
            default:
                Capsule()
                    .fill(model.accent)
                    .frame(width: w, height: 2.5)
                    .padding(.bottom, 4)
                    .phaseAnimator([0.15, 0.7]) { v, p in v.opacity(p) } animation: { _ in .easeInOut(duration: 2.4) }
            }
        }
    }
}

/// The small drawn idle styles: twinkling sparks, falling rain, and a pet's blinking eyes.
struct IdleCanvas: View {
    let style: String
    let color: Color
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            Canvas { g, size in
                switch style {
                case "sparks":
                    for i in 0..<7 {
                        let seed = Double(i) * 1.7
                        let x = size.width * (0.06 + 0.88 * frac(seed * 0.618))
                        let y = size.height * (0.25 + 0.5 * frac(seed * 0.377))
                        let a = 0.5 + 0.5 * sin(t * (1.1 + frac(seed) * 1.4) + seed * 3)
                        let r = 0.7 + 0.9 * a
                        g.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)), with: .color(color.opacity(0.15 + 0.8 * a)))
                    }
                case "rain":
                    for i in 0..<9 {
                        let seed = Double(i) * 2.3
                        let x = size.width * (0.04 + 0.92 * frac(seed * 0.618))
                        let fall = frac(t * (0.7 + 0.5 * frac(seed * 0.41)) + seed)
                        let y = size.height * (fall * 1.3 - 0.3)
                        g.fill(Path(roundedRect: CGRect(x: x, y: y, width: 1.2, height: 3.2), cornerRadius: 0.6), with: .color(color.opacity(0.85 * (1 - fall))))
                    }
                default: // pet: two eyes that look around and blink
                    let look = sin(t * 0.6) * size.width * 0.05
                    let blink = frac(t / 3.4) > 0.94 ? 0.2 : 1.0
                    for dx in [-5.0, 5.0] {
                        let r = CGRect(x: size.width / 2 + dx + look - 1.8, y: size.height / 2 - 1.8 * blink, width: 3.6, height: 3.6 * blink)
                        g.fill(Path(ellipseIn: r), with: .color(color))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func frac(_ v: Double) -> Double { v - v.rounded(.down) }
}

struct BannerContent: View {
    @Bindable var model: IslandModel
    var body: some View {
        switch model.activity {
        case .notify(let msg):
            HStack(spacing: 12) {
                Badge(symbol: "terminal.fill", accent: model.accent)
                Text(msg).font(.system(size: 15, weight: .semibold)).foregroundStyle(ink).lineLimit(1)
                Spacer(minLength: 0)
            }
        case .progress(let v, let label):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(label).font(.system(size: 14, weight: .semibold)).foregroundStyle(ink)
                    Spacer()
                    Text("\(Int((v * 100).rounded()))%").font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundStyle(model.accent)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.14))
                        Capsule().fill(model.accent).frame(width: max(8, g.size.width * v))
                    }
                }
                .frame(height: 7)
            }
        case .theme(let name):
            HStack(spacing: 12) {
                Badge(symbol: "paintpalette.fill", accent: model.accent)
                Text("\(name) applied").font(.system(size: 15, weight: .semibold)).foregroundStyle(ink)
                Spacer(minLength: 0)
            }
        case .battery(let b):
            HStack(spacing: 12) {
                Image(systemName: b.isCharging ? "bolt.fill" : "battery.25percent")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(b.isCharging ? model.accent : .red)
                    .symbolEffect(.pulse, isActive: b.isCharging && model.animate)
                Text(b.isCharging ? "Charging" : b.isPluggedIn ? "Plugged in" : "Battery low")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(ink)
                Spacer()
                BatteryBar(level: b.level, accent: b.level < 0.2 && !b.isCharging ? .red : model.accent)
                Text("\(Int(b.level * 100))%").font(.system(size: 14, weight: .semibold)).foregroundStyle(ink)
            }
        case .volume(let v, let muted):
            LevelHUD(symbol: muted || v == 0 ? "speaker.slash.fill" : v < 0.34 ? "speaker.wave.1.fill" : v < 0.67 ? "speaker.wave.2.fill" : "speaker.wave.3.fill",
                     value: v, dimmed: muted, accent: model.accent)
                .accessibilityLabel(muted ? "Muted" : "Volume \(Int((v * 100).rounded())) percent")
        case .brightness(let b):
            LevelHUD(symbol: b < 0.5 ? "sun.min.fill" : "sun.max.fill", value: b, dimmed: false, accent: model.accent)
                .accessibilityLabel("Brightness \(Int((b * 100).rounded())) percent")
        case nil:
            EmptyView()
        }
    }
}

struct HomeContent: View {
    @Bindable var model: IslandModel
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now, format: .dateTime.hour().minute())
                    .font(.system(size: 34, weight: .semibold, design: .rounded)).foregroundStyle(ink)
                Text(Date.now, format: .dateTime.weekday(.wide).day().month())
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(dim)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                if let b = model.battery {
                    HStack(spacing: 8) {
                        if b.isCharging { Image(systemName: "bolt.fill").foregroundStyle(model.accent) }
                        BatteryBar(level: b.level, accent: model.accent)
                        Text("\(Int(b.level * 100))%").font(.system(size: 13, weight: .semibold)).foregroundStyle(ink)
                    }
                }
                HStack(spacing: 6) {
                    Circle().fill(model.accent).frame(width: 9, height: 9)
                    Text(model.themeName).font(.system(size: 13, weight: .semibold)).foregroundStyle(ink)
                }
                if let np = model.nowPlaying {
                    NowPlayingPill(model: model, np: np)
                } else {
                    Text("Nothing playing").font(.system(size: 12)).foregroundStyle(dim)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

/// On Home: what's playing, a play/pause button, and a tap opens the full player.
struct NowPlayingPill: View {
    @Bindable var model: IslandModel
    let np: NowPlaying
    var body: some View {
        HStack(spacing: 6) {
            Button { model.go(to: .player) } label: {
                HStack(spacing: 8) {
                    Artwork(image: model.artwork, accent: model.accent, size: 26, radius: 6)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(np.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(ink).lineLimit(1)
                        Text("\(np.isPlaying ? "Playing" : "Paused") · \(np.appName)").font(.system(size: 10.5)).foregroundStyle(dim).lineLimit(1)
                    }
                    .frame(maxWidth: 140, alignment: .leading)
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(dim)
                }
                .padding(.vertical, 5).padding(.leading, 5).padding(.trailing, 8)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.08)))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Now playing: \(np.title). Open the player")
            ControlButton(symbol: np.isPlaying ? "pause.fill" : "play.fill", size: 14, action: model.onPlayPause)
        }
    }
}

/// One dot per page. The current one is a wider accent capsule; tap a dot to go there.
struct PageDots: View {
    @Bindable var model: IslandModel
    var body: some View {
        HStack(spacing: 6) {
            ForEach(model.pages, id: \.self) { p in
                let on = p == model.currentPage
                Button { model.go(to: p) } label: {
                    Capsule()
                        .fill(on ? model.accent : Color.white.opacity(0.28))
                        .frame(width: on ? 18 : 6, height: 6)
                        .padding(.vertical, 4).padding(.horizontal, 2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Self.name(p))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .animation(model.spring, value: model.currentPage)
        .frame(maxWidth: .infinity)
    }

    static func name(_ p: IslandModel.Page) -> String {
        switch p {
        case .home: "Home"
        case .player: "Now playing"
        case .shelf: "File shelf"
        }
    }
}

struct PlayerContent: View {
    @Bindable var model: IslandModel
    let np: NowPlaying
    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Artwork(image: model.artwork, accent: model.accent, size: 78, radius: 16)
                if let icon = AppIcons.icon(np.bundleID), np.source != .music || model.artwork == nil {
                    Image(nsImage: icon).resizable().frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.5), radius: 3)
                        .offset(x: 6, y: 6)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(np.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(ink).lineLimit(1)
                Text(subtitle).font(.system(size: 13)).foregroundStyle(dim).lineLimit(1)
                if let d = np.duration, d > 0 {
                    TrackProgress(np: np, duration: d, accent: model.accent, live: model.animate)
                        .padding(.top, 5)
                }
                HStack(spacing: 22) {
                    ControlButton(symbol: "backward.fill", action: model.onPrevious)
                    ControlButton(symbol: np.isPlaying ? "pause.fill" : "play.fill", size: 22, action: model.onPlayPause)
                    ControlButton(symbol: "forward.fill", action: model.onNext)
                }
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
            if model.showsVisualizer {
                Visualizer(accent: model.accent, playing: np.isPlaying && model.animate, bars: 6, height: 40)
            }
        }
        .frame(maxHeight: .infinity)
    }

    /// "Artist · Safari" for browsers and other apps, just the artist for Music and Spotify.
    private var subtitle: String {
        let showApp = np.source == .system
        switch (np.artist.isEmpty, showApp) {
        case (true, _): return np.appName
        case (false, true): return "\(np.artist) · \(np.appName)"
        case (false, false): return np.artist
        }
    }
}

/// Elapsed / remaining with a thin bar. Ticks once a second, only while the island is open.
struct TrackProgress: View {
    let np: NowPlaying
    let duration: Double
    let accent: Color
    let live: Bool
    var body: some View {
        TimelineView(.periodic(from: .now, by: live && np.isPlaying ? 1 : 3600)) { ctx in
            let t = np.elapsed(at: ctx.date) ?? 0
            HStack(spacing: 8) {
                Text(Self.clock(t)).font(.system(size: 10.5, weight: .medium).monospacedDigit()).foregroundStyle(dim)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.14))
                        Capsule().fill(accent).frame(width: max(4, g.size.width * min(t / duration, 1)))
                    }
                }
                .frame(height: 4)
                Text("-" + Self.clock(max(duration - t, 0))).font(.system(size: 10.5, weight: .medium).monospacedDigit()).foregroundStyle(dim)
            }
            .frame(maxWidth: 230)
        }
        .accessibilityLabel("\(Self.clock(np.elapsed() ?? 0)) of \(Self.clock(duration))")
    }

    static func clock(_ s: Double) -> String {
        let s = Int(s.rounded(.down))
        return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60) : String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// Icons of the apps that play things (Safari, Chrome, Spotify…), cached.
@MainActor
enum AppIcons {
    private static var cache: [String: NSImage] = [:]
    static func icon(_ bundleID: String?) -> NSImage? {
        guard let id = bundleID else { return nil }
        if let hit = cache[id] { return hit }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else { return nil }
        let img = NSWorkspace.shared.icon(forFile: url.path)
        cache[id] = img
        return img
    }
}

struct ControlButton: View {
    let symbol: String
    var size: CGFloat = 16
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: size, weight: .bold)).foregroundStyle(ink).frame(width: 28, height: 28).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol.contains("pause") ? "Pause" : symbol.contains("play") ? "Play" : symbol.contains("forward") ? "Next track" : "Previous track")
    }
}

struct Artwork: View {
    let image: NSImage?
    let accent: Color
    let size: CGFloat
    let radius: CGFloat
    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    accent
                    Image(systemName: "music.note").font(.system(size: size * 0.42, weight: .bold)).foregroundStyle(.black.opacity(0.75))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Audio-style bars. Decorative (there's no public API for the real audio level).
struct Visualizer: View {
    let accent: Color
    let playing: Bool
    let bars: Int
    let height: CGFloat
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !playing)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<bars, id: \.self) { i in
                    Capsule().fill(accent).frame(width: 3.5, height: height * level(i, t))
                }
            }
            .frame(height: height)
        }
    }

    private func level(_ i: Int, _ t: Double) -> CGFloat {
        guard playing else { return 0.25 }
        let speed: Double = 2.2 + Double(i % 3) * 0.6
        let wave: Double = abs(sin(t * speed + Double(i) * 1.3))
        return CGFloat(0.3 + 0.7 * wave)
    }
}

struct Badge: View {
    let symbol: String
    let accent: Color
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.black)
            .frame(width: 30, height: 30)
            .background(Circle().fill(accent))
    }
}

struct BatteryBar: View {
    let level: Double
    let accent: Color
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4).stroke(ink.opacity(0.8), lineWidth: 1.5)
            RoundedRectangle(cornerRadius: 2.5).fill(accent).padding(2.5).frame(width: max(8, 40 * level))
        }
        .frame(width: 40, height: 18)
    }
}

/// Accept dropped files on the whole island (skipped when rendering snapshots).
struct ShelfDrop: ViewModifier {
    @Bindable var model: IslandModel
    func body(content: Content) -> some View {
        if model.isSnapshot {
            content
        } else {
            content.onDrop(of: [.fileURL], isTargeted: Binding(get: { model.dropTargeted }, set: { v in withAnimation(model.spring) { model.dropTargeted = v } })) { providers in
                Shelf.load(providers, into: model)
            }
        }
    }
}

/// Volume and brightness: an icon and a bar in the theme accent.
struct LevelHUD: View {
    let symbol: String
    let value: Double
    let dimmed: Bool
    let accent: Color
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold)).foregroundStyle(ink)
                .frame(width: 24)
                .contentTransition(.symbolEffect(.replace))
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.14))
                    Capsule().fill(dimmed ? dim : accent).frame(width: max(7, g.size.width * value))
                }
            }
            .frame(height: 7)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: value)
        }
    }
}
