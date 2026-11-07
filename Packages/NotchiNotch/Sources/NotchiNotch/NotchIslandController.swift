import AppKit
import Combine
import NotchiCore
import SwiftUI

/// A borderless panel that never takes focus and floats above the menu bar.
final class IslandPanel: NSPanel {
    init(frame: NSRect) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isMovable = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Owns the island window, keeps it on the notch, and turns bus events into activities.
@MainActor
public final class NotchIslandController {
    public let model = IslandModel()
    private let bus: EventBus
    private let themes: ThemeEngine
    private let energy: EnergyGovernor
    private var panel: IslandPanel?
    private var subs = Set<AnyCancellable>()
    private var monitors: [Any] = []
    private var screenObserver: NSObjectProtocol?
    private var geometry: DisplayManager.NotchGeometry?
    private var leaveTask: Task<Void, Never>?

    /// The window is a fixed canvas big enough for the expanded island; the island draws inside it.
    static let canvas = CGSize(width: 760, height: 260)

    public init(bus: EventBus, themes: ThemeEngine, energy: EnergyGovernor) {
        self.bus = bus
        self.themes = themes
        self.energy = energy
    }

    public func start() {
        applyTheme(themes.active)
        applyEnergy(energy.budget)
        let p = IslandPanel(frame: .zero)
        let host = NSHostingView(rootView: IslandView(model: model))
        host.frame = NSRect(origin: .zero, size: Self.canvas)
        host.autoresizingMask = [.width, .height]
        p.contentView = host
        panel = p
        layout()
        p.orderFrontRegardless()

        screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.layout() }
        }

        // Hover: watch the pointer without taking clicks away from the menu bar.
        let handler: (NSEvent) -> Void = { [weak self] _ in self?.pointerMoved() }
        if let g = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged], handler: { e in MainActor.assumeIsolated { handler(e) } }) { monitors.append(g) }
        if let l = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged], handler: { e in MainActor.assumeIsolated { handler(e) }; return e }) { monitors.append(l) }

        bus.events.receive(on: RunLoop.main).sink { [weak self] e in
            MainActor.assumeIsolated { self?.handle(e) }
        }.store(in: &subs)
    }

    private func layout() {
        guard let screen = DisplayManager.preferredScreen, let panel else { return }
        let g = DisplayManager.notch(on: screen)
        geometry = g
        model.notchSize = g.rect.size
        model.isHardwareNotch = g.isHardware
        let c = Self.canvas
        panel.setFrame(NSRect(x: g.rect.midX - c.width / 2, y: g.screenFrame.maxY - c.height, width: c.width, height: c.height), display: true)
    }

    /// The island's current rect in screen coordinates.
    private var islandRect: NSRect {
        guard let g = geometry else { return .zero }
        let s = model.size
        return NSRect(x: g.rect.midX - s.width / 2, y: g.screenFrame.maxY - s.height, width: s.width, height: s.height)
    }

    /// True while the user is dragging files (from Finder or anywhere).
    private var isDraggingFiles: Bool {
        NSEvent.pressedMouseButtons & 1 == 1 &&
            (NSPasteboard(name: .drag).types?.contains(.fileURL) ?? false)
    }

    private func pointerMoved() {
        let p = NSEvent.mouseLocation
        // dragging files: open a bit earlier so the shelf is there to catch them
        let margin: CGFloat = isDraggingFiles ? 60 : 10
        let inside = islandRect.insetBy(dx: -margin, dy: -margin).contains(p)
        if inside {
            leaveTask?.cancel()
            if !model.hovering {
                withAnimation(model.spring) { model.hovering = true }
                panel?.ignoresMouseEvents = false
            }
        } else if model.hovering, leaveTask == nil {
            // small grace period so the island doesn't flicker at its edge
            leaveTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(220))
                guard let self, !Task.isCancelled else { return }
                self.leaveTask = nil
                if !self.islandRect.insetBy(dx: -10, dy: -6).contains(NSEvent.mouseLocation), !self.model.dropTargeted {
                    withAnimation(self.model.spring) { self.model.hovering = false }
                    self.panel?.ignoresMouseEvents = true
                }
            }
        }
    }

    private func handle(_ e: NotchiEvent) {
        switch e {
        case .themeChanged(let t):
            applyTheme(t)
            model.show(.theme(t.name), for: 2.2)
        case .notify(let msg):
            model.show(.notify(msg), for: 4)
        case .progress(let v, let label):
            let v = min(max(v, 0), 1)
            model.show(.progress(v, label), for: v >= 1 ? 2 : 30)
        case .energy(let b):
            applyEnergy(b)
        case .nowPlaying(let np):
            withAnimation(model.spring) { model.nowPlaying = np }
        case .volume(let v, let muted):
            model.show(.volume(v, muted), for: 1.6)
        case .brightness(let b):
            model.show(.brightness(b), for: 1.6)
        case .battery(let b):
            let old = model.battery
            model.battery = b
            if let old, old.isPluggedIn != b.isPluggedIn { model.show(.battery(b), for: 3) }
            else if b.level <= 0.2, !b.isCharging, (old?.level ?? 1) > 0.2 { model.show(.battery(b), for: 5) }
        }
    }

    private func applyTheme(_ t: Theme) {
        model.accent = Color(.sRGB, red: t.accent.red, green: t.accent.green, blue: t.accent.blue, opacity: 1)
        model.themeName = t.name
        model.idleStyle = t.notch.idle
    }

    private func applyEnergy(_ b: EnergyGovernor.Budget) {
        model.animate = b.fps > 0
        model.reduceMotion = b.reduceMotion
    }
}
