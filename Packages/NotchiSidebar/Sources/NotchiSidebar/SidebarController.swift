import AppKit
import Carbon.HIToolbox
import Combine
import NotchiCore
import SwiftUI

/// A borderless glass panel at the screen's edge. It can take typing (for notes)
/// without making Notchi the active app.
final class SidebarPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient]
        isMovable = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        title = "Notchi Sidebar"
    }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { onEscape() }
    var onEscape: () -> Void = {}
}

/// Opens the sidebar from the hot edge, the shortcut (⌃⌥N), the menu or `notchi sidebar`,
/// and keeps its widgets up to date while it's open.
@MainActor
public final class SidebarController {
    public let model = SidebarModel()
    private let bus: EventBus
    private let themes: ThemeEngine
    private let energy: EnergyGovernor
    private let calendar = CalendarSource()
    private var panel: SidebarPanel?
    private var subs = Set<AnyCancellable>()
    private var monitors: [Any] = []
    private var hotKey: HotKey?
    private var sampler: Task<Void, Never>?
    private var counters: SystemStats.Counters?
    private var edgeSince: Date?
    private var openedByEdge = false
    private var leftAt: Date?

    public static let width: CGFloat = 340
    public static let shortcut = "⌃⌥N"

    public init(bus: EventBus, themes: ThemeEngine, energy: EnergyGovernor) {
        self.bus = bus
        self.themes = themes
        self.energy = energy
    }

    public func start() {
        applyTheme(themes.active)
        model.reduceMotion = energy.budget.reduceMotion
        model.onConnectCalendar = { [weak self] in self?.connectCalendar() }
        calendar.onChange = { [weak self] in self?.refreshCalendar() }
        refreshCalendar()
        bus.events.receive(on: RunLoop.main).sink { [weak self] e in
            MainActor.assumeIsolated { self?.handle(e) }
        }.store(in: &subs)
        if let g = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved], handler: { _ in MainActor.assumeIsolated { self.pointerMoved() } }) { monitors.append(g) }
        if let l = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved], handler: { e in MainActor.assumeIsolated { self.pointerMoved() }; return e }) { monitors.append(l) }
        // clicking anywhere else closes it
        if let c = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { _ in
            MainActor.assumeIsolated { if self.model.isOpen { self.close() } }
        }) { monitors.append(c) }
        hotKey = HotKey(keyCode: kVK_ANSI_N, modifiers: controlKey | optionKey) { [weak self] in self?.toggle() }
    }

    public var shortcutWorks: Bool { hotKey != nil }

    // MARK: Open and close

    public func toggle() { model.isOpen ? close() : open() }

    public func open(byEdge: Bool = false) {
        guard !model.isOpen, let screen = screen() else { return }
        openedByEdge = byEdge
        leftAt = nil
        model.widgets = SidebarSettings.widgets(for: themes.active)
        model.reloadNotes()
        refreshCalendar()
        let p = panel ?? makePanel()
        let (shown, hidden) = frames(on: screen)
        p.setFrame(model.reduceMotion ? shown : hidden, display: false)
        p.alphaValue = model.reduceMotion ? 0 : 1
        p.makeKeyAndOrderFront(nil)
        model.isOpen = true
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = model.reduceMotion ? 0.15 : 0.32
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.25, 1)
            p.animator().setFrame(shown, display: true)
            p.animator().alphaValue = 1
        }
        startSampling()
    }

    public func close() {
        guard model.isOpen, let p = panel, let screen = p.screen ?? screen() else { return }
        model.isOpen = false
        sampler?.cancel()
        let hidden = frames(on: screen).hidden
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = model.reduceMotion ? 0.12 : 0.24
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            if model.reduceMotion { p.animator().alphaValue = 0 } else { p.animator().setFrame(hidden, display: true) }
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated { if self?.model.isOpen == false { p.orderOut(nil) } }
        })
    }

    private func makePanel() -> SidebarPanel {
        let p = SidebarPanel()
        let host = NSHostingView(rootView: SidebarView(model: model))
        host.autoresizingMask = [.width, .height]
        p.contentView = host
        p.onEscape = { [weak self] in self?.close() }
        panel = p
        return p
    }

    /// The screen the pointer is on: the sidebar opens where you're looking.
    private func screen() -> NSScreen? {
        let p = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(p, $0.frame, false) } ?? NSScreen.main
    }

    private func frames(on screen: NSScreen) -> (shown: NSRect, hidden: NSRect) {
        let v = screen.visibleFrame, gap: CGFloat = 10, w = Self.width
        let h = v.height - 2 * gap
        let right = SidebarSettings.edge == .right
        let shown = NSRect(x: right ? v.maxX - w - gap : v.minX + gap, y: v.minY + gap, width: w, height: h)
        let hidden = shown.offsetBy(dx: right ? w + gap + 30 : -(w + gap + 30), dy: 0)
        return (shown, hidden)
    }

    // MARK: Hot edge

    private func pointerMoved() {
        let p = NSEvent.mouseLocation
        if model.isOpen {
            // opened from the edge: close a moment after the pointer wanders well away
            guard openedByEdge, let f = panel?.frame else { return }
            if f.insetBy(dx: -40, dy: -40).contains(p) { leftAt = nil }
            else if let t = leftAt { if Date().timeIntervalSince(t) > 0.5 { close() } }
            else { leftAt = Date() }
            return
        }
        guard SidebarSettings.hotEdge, NSEvent.pressedMouseButtons == 0,
              let screen = NSScreen.screens.first(where: { NSMouseInRect(p, $0.frame, false) }) else { edgeSince = nil; return }
        let f = screen.frame, v = screen.visibleFrame
        let atEdge = SidebarSettings.edge == .right ? p.x >= f.maxX - 1 : p.x <= f.minX + 1
        // not in the menu bar, and not down by the Dock
        let inBand = p.y < v.maxY - 20 && p.y > v.minY + 60
        guard atEdge && inBand else { edgeSince = nil; return }
        if let t = edgeSince {
            if Date().timeIntervalSince(t) > 0.35 { edgeSince = nil; open(byEdge: true) }
        } else {
            edgeSince = Date()
        }
    }

    // MARK: Data

    private func startSampling() {
        sampler?.cancel()
        counters = nil   // rates start fresh each time it opens
        sampler = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let (s, c) = SystemStats.sample(since: self.counters)
                self.counters = c
                if self.model.stats == nil || self.model.stats != s { self.model.stats = s }
                // slower in Low Power Mode or when it's hot
                let every: Double = self.energy.budget.fps == 0 ? 5 : 2
                try? await Task.sleep(for: .seconds(every))
            }
        }
    }

    private func connectCalendar() {
        Task {
            _ = await calendar.requestAccess()
            refreshCalendar()
        }
    }

    private func refreshCalendar() {
        model.calendarAllowed = calendar.isAllowed
        model.calendarDenied = calendar.wasDenied
        model.events = calendar.upcoming()
    }

    private func handle(_ e: NotchiEvent) {
        switch e {
        case .themeChanged(let t):
            applyTheme(t)
            if model.isOpen { model.widgets = SidebarSettings.widgets(for: t) }
        case .nowPlaying(let np): model.nowPlaying = np
        case .battery(let b): model.battery = b
        case .energy(let b): model.reduceMotion = b.reduceMotion
        default: break
        }
    }

    private func applyTheme(_ t: Theme) {
        model.accent = Color(.sRGB, red: t.accent.red, green: t.accent.green, blue: t.accent.blue, opacity: 1)
        model.glassTint = t.glass.tint
        switch t.appearance {
        case .dark: model.dark = true
        case .light: model.dark = false
        case .auto: model.dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
    }

    /// Settings changed (widgets, edge): show the new list straight away.
    public func settingsChanged() {
        model.widgets = SidebarSettings.widgets(for: themes.active)
        if model.isOpen, let p = panel, let s = p.screen { p.setFrame(frames(on: s).shown, display: true) }
    }
}
