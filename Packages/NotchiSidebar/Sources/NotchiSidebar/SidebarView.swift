import AppKit
import NotchiCore
import SwiftUI

/// Frosted glass that blurs whatever is behind the sidebar window.
struct Glass: NSViewRepresentable {
    let dark: Bool
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = dark ? .hudWindow : .popover
        v.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    }
}

public struct SidebarView: View {
    @Bindable var model: SidebarModel
    public init(model: SidebarModel) { self.model = model }

    private var ink: Color { model.dark ? .white : Color(red: 0.09, green: 0.08, blue: 0.06) }

    private var cards: some View {
        VStack(spacing: 12) {
            ForEach(model.widgets) { w in
                switch w {
                case .clock: ClockWidget(model: model)
                case .nowPlaying: NowPlayingWidget(model: model)
                case .calendar: CalendarWidget(model: model)
                case .stats: StatsWidget(model: model)
                case .notes: NotesWidget(model: model)
                }
            }
            if model.widgets.isEmpty {
                Text("No widgets. Pick some in Settings → Sidebar.").font(.callout).foregroundStyle(ink.opacity(0.6)).padding(.top, 40)
            }
            Button { model.onOpenSettings() } label: {
                Label("Customize", systemImage: "slider.horizontal.3").font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(ink.opacity(0.55))
            .padding(.vertical, 6)
        }
        .padding(14)
    }

    public var body: some View {
        ZStack {
            if model.isSnapshot {
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(model.dark ? Color(white: 0.13) : Color(white: 0.95))
            } else {
                Glass(dark: model.dark).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            // a wash of the theme colour, as strong as the theme's glass tint
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(model.accent.opacity(model.glassTint * 0.28))
            RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(model.dark ? 0.14 : 0.5), lineWidth: 1)

            // ImageRenderer can't draw scroll views, so snapshots lay the cards out directly
            if model.isSnapshot {
                VStack { cards; Spacer(minLength: 0) }
            } else {
                ScrollView(showsIndicators: false) { cards }
            }
        }
        .foregroundStyle(ink)
        .environment(\.colorScheme, model.dark ? .dark : .light)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Notchi sidebar")
    }
}

/// The rounded card every widget sits on.
struct Card<Content: View>: View {
    let title: String
    let symbol: String
    @Bindable var model: SidebarModel
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title.uppercased(), systemImage: symbol)
                .font(.system(size: 10.5, weight: .bold)).tracking(0.8)
                .foregroundStyle(model.accent)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(model.dark ? Color.white.opacity(0.07) : Color.black.opacity(0.045)))
    }
}

struct ClockWidget: View {
    @Bindable var model: SidebarModel
    var body: some View {
        TimelineView(.everyMinute) { ctx in
            VStack(alignment: .leading, spacing: 2) {
                Text(ctx.date, format: .dateTime.hour().minute())
                    .font(.system(size: 46, weight: .semibold, design: .rounded)).monospacedDigit()
                Text(ctx.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.system(size: 14, weight: .medium)).opacity(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6).padding(.top, 6)
        }
    }
}

struct NowPlayingWidget: View {
    @Bindable var model: SidebarModel
    var body: some View {
        Card(title: "Now playing", symbol: "music.note", model: model) {
            if let np = model.nowPlaying {
                HStack(spacing: 12) {
                    Group {
                        if let a = model.artwork { Image(nsImage: a).resizable().aspectRatio(contentMode: .fill) }
                        else { ZStack { model.accent.opacity(0.25); Image(systemName: "music.note").font(.title2) } }
                    }
                    .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(np.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                        Text(np.artist.isEmpty ? np.appName : np.artist).font(.system(size: 12)).opacity(0.65).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                HStack(spacing: 26) {
                    Spacer()
                    control("backward.fill", model.onPrevious, "Previous")
                    control(np.isPlaying ? "pause.fill" : "play.fill", model.onPlayPause, np.isPlaying ? "Pause" : "Play", size: 20)
                    control("forward.fill", model.onNext, "Next")
                    Spacer()
                }
            } else {
                Text("Nothing is playing.").font(.callout).opacity(0.6)
            }
        }
    }

    private func control(_ symbol: String, _ action: @escaping () -> Void, _ label: String, size: CGFloat = 15) -> some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: size, weight: .semibold)).frame(width: 30, height: 26) }
            .buttonStyle(.plain).accessibilityLabel(label)
    }
}

struct CalendarWidget: View {
    @Bindable var model: SidebarModel
    var body: some View {
        Card(title: "Calendar", symbol: "calendar", model: model) {
            MonthGrid(accent: model.accent, date: Date())
            if model.calendarAllowed {
                if model.events.isEmpty {
                    Text("Nothing else today or tomorrow.").font(.caption).opacity(0.6)
                } else {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(model.events) { e in
                            HStack(alignment: .top, spacing: 8) {
                                Capsule().fill(e.colorHex.flatMap(HexColor.init).map { Color(.sRGB, red: $0.red, green: $0.green, blue: $0.blue) } ?? model.accent)
                                    .frame(width: 3, height: 28)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(e.title).font(.system(size: 12.5, weight: .semibold)).lineLimit(1)
                                    Text(when(e)).font(.system(size: 11)).opacity(0.6)
                                }
                            }
                        }
                    }
                }
            } else if model.calendarDenied {
                Text("Calendar access is off. Turn it on in System Settings → Privacy & Security → Calendars.").font(.caption).opacity(0.6)
            } else {
                Button("Show my events") { model.onConnectCalendar() }.controlSize(.small)
            }
        }
    }

    private func when(_ e: CalendarSource.Event) -> String {
        let cal = Calendar.current
        let day = cal.isDateInToday(e.start) ? "Today" : cal.isDateInTomorrow(e.start) ? "Tomorrow" : e.start.formatted(.dateTime.weekday(.abbreviated))
        if e.allDay { return "\(day) · all day" }
        return "\(day) · \(e.start.formatted(date: .omitted, time: .shortened))–\(e.end.formatted(date: .omitted, time: .shortened))"
    }
}

/// This month, with today marked.
struct MonthGrid: View {
    let accent: Color
    let date: Date
    var body: some View {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let days = cal.range(of: .day, in: .month, for: date)!.count
        let lead = (cal.component(.weekday, from: start) - cal.firstWeekday + 7) % 7
        let today = cal.component(.day, from: date)
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let names = Array(symbols[(cal.firstWeekday - 1)...] + symbols[..<(cal.firstWeekday - 1)])
        VStack(alignment: .leading, spacing: 6) {
            Text(date, format: .dateTime.month(.wide).year()).font(.system(size: 13, weight: .semibold))
            Grid(horizontalSpacing: 0, verticalSpacing: 3) {
                GridRow { ForEach(Array(names.enumerated()), id: \.offset) { Text($0.element).font(.system(size: 10, weight: .semibold)).opacity(0.5).frame(maxWidth: .infinity) } }
                ForEach(0..<((lead + days + 6) / 7), id: \.self) { row in
                    GridRow {
                        ForEach(0..<7, id: \.self) { col in
                            let d = row * 7 + col - lead + 1
                            Text(d >= 1 && d <= days ? "\(d)" : "")
                                .font(.system(size: 11.5, weight: d == today ? .bold : .regular)).monospacedDigit()
                                .frame(maxWidth: .infinity, minHeight: 20)
                                .background { if d == today { Circle().fill(accent).frame(width: 22, height: 22) } }
                                .foregroundStyle(d == today ? Color.white : Color.primary)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today is \(date.formatted(date: .complete, time: .omitted))")
    }
}

struct StatsWidget: View {
    @Bindable var model: SidebarModel
    var body: some View {
        Card(title: "System", symbol: "gauge.with.dots.needle.33percent", model: model) {
            if let s = model.stats {
                VStack(spacing: 9) {
                    bar("CPU", s.cpu, "\(Int((s.cpu * 100).rounded()))%")
                    bar("Memory", s.memoryFraction, "\(gb(Int64(s.memoryUsed))) of \(gb(Int64(s.memoryTotal)))")
                    bar("Disk", s.diskUsedFraction, "\(gb(s.diskFree)) free")
                    if let b = model.battery {
                        bar("Battery", b.level, "\(Int((b.level * 100).rounded()))%\(b.isCharging ? " · charging" : b.isPluggedIn ? " · plugged in" : "")",
                            tint: b.isLow ? .red : nil)
                    }
                    HStack {
                        Label(rate(s.downloadRate), systemImage: "arrow.down").font(.system(size: 11.5, weight: .medium)).monospacedDigit()
                        Spacer()
                        Label(rate(s.uploadRate), systemImage: "arrow.up").font(.system(size: 11.5, weight: .medium)).monospacedDigit()
                    }
                    .opacity(0.75)
                }
            } else {
                ProgressView().controlSize(.small)
            }
        }
    }

    private func bar(_ name: String, _ value: Double, _ detail: String, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(detail).font(.system(size: 11.5)).monospacedDigit().opacity(0.65)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(.primary.opacity(0.12))
                    Capsule().fill(tint ?? model.accent).frame(width: max(4, g.size.width * min(max(value, 0), 1)))
                }
            }
            .frame(height: 5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name): \(detail)")
    }

    private func gb(_ bytes: Int64) -> String { ByteCountFormatter.string(fromByteCount: bytes, countStyle: .memory) }
    private func rate(_ bps: Double) -> String { ByteCountFormatter.string(fromByteCount: Int64(bps), countStyle: .file) + "/s" }
}

struct NotesWidget: View {
    @Bindable var model: SidebarModel
    var body: some View {
        Card(title: "Notes", symbol: "note.text", model: model) {
            ZStack(alignment: .topLeading) {
                if model.notes.isEmpty {
                    Text("Jot something down. It stays on this Mac.").font(.system(size: 13)).opacity(0.45).padding(.top, 1).padding(.leading, 5)
                }
                if model.isSnapshot {
                    Text(model.notes).font(.system(size: 13)).padding(.leading, 5).frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                } else {
                    TextEditor(text: $model.notes)
                        .font(.system(size: 13))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 90, maxHeight: 180)
                }
            }
        }
    }
}
