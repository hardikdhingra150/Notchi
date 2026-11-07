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
                .shadow(color: model.activity != nil || mode == .expanded ? model.accent.opacity(0.45) : .clear, radius: 18, y: 4)
                .overlay(alignment: .bottom) { if mode == .closed { IdleGlow(model: model) } }

            content(mode)
                .frame(width: s.width, height: s.height, alignment: .top)
                .clipped()
        }
        .frame(width: s.width + 2 * ear, height: s.height)
        .modifier(ShelfDrop(model: model))
        .animation(model.spring, value: mode)
        .animation(model.spring, value: model.showsShelf)
        .animation(model.spring, value: model.activity)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Notchi island")
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
                Visualizer(accent: model.accent, playing: model.animate, bars: 4, height: top - 14)
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
                Group {
                    if let np = model.nowPlaying {
                        PlayerContent(model: model, np: np)
                    } else {
                        HomeContent(model: model)
                    }
                }
                .frame(height: 114)
                if model.showsShelf {
                    ShelfView(model: model)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 18)
            .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .top)))
        }
    }
}

// MARK: - Pieces

/// A soft accent line that breathes under the notch while it's idle. Off when the energy budget says so.
struct IdleGlow: View {
    @Bindable var model: IslandModel
    var body: some View {
        if model.animate && !model.reduceMotion && model.idleStyle == "breathing" {
            Capsule()
                .fill(model.accent)
                .frame(width: model.notchSize.width * 0.36, height: 2.5)
                .padding(.bottom, 4)
                .phaseAnimator([0.15, 0.7]) { v, p in v.opacity(p) } animation: { _ in .easeInOut(duration: 2.4) }
        }
    }
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
            HStack(spacing: 12) {
                Image(systemName: muted || v == 0 ? "speaker.slash.fill" : v < 0.34 ? "speaker.wave.1.fill" : v < 0.67 ? "speaker.wave.2.fill" : "speaker.wave.3.fill")
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(ink)
                    .frame(width: 24)
                    .contentTransition(.symbolEffect(.replace))
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.14))
                        Capsule().fill(muted ? dim : model.accent).frame(width: max(7, g.size.width * v))
                    }
                }
                .frame(height: 7)
                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: v)
            }
            .accessibilityLabel(muted ? "Muted" : "Volume \(Int(v * 100)) percent")
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
                Text("Nothing playing").font(.system(size: 12)).foregroundStyle(dim)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct PlayerContent: View {
    @Bindable var model: IslandModel
    let np: NowPlaying
    var body: some View {
        HStack(spacing: 16) {
            Artwork(image: model.artwork, accent: model.accent, size: 78, radius: 16)
            VStack(alignment: .leading, spacing: 3) {
                Text(np.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(ink).lineLimit(1)
                Text(np.artist).font(.system(size: 13)).foregroundStyle(dim).lineLimit(1)
                HStack(spacing: 22) {
                    ControlButton(symbol: "backward.fill", action: model.onPrevious)
                    ControlButton(symbol: np.isPlaying ? "pause.fill" : "play.fill", size: 22, action: model.onPlayPause)
                    ControlButton(symbol: "forward.fill", action: model.onNext)
                }
                .padding(.top, 8)
            }
            Spacer(minLength: 0)
            Visualizer(accent: model.accent, playing: np.isPlaying && model.animate, bars: 6, height: 40)
        }
        .frame(maxHeight: .infinity)
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
