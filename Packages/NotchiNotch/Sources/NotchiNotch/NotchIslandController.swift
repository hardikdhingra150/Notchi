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

/// The panel never becomes key, so without this the first click on a button would
/// only "activate" the window and the button would never fire.
final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
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
        model.hideIdleVirtual = UserDefaults.standard.bool(forKey: Self.hideIdleKey)
        let ws = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.didActivateApplicationNotification] {
            spaceObservers.append(ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                // the space animation finishes a moment after the notification
                MainActor.assumeIsolated {
                    self?.updateStepAside()
                    Task { @MainActor [weak self] in try? await Task.sleep(for: .milliseconds(700)); self?.updateStepAside() }
                }
            })
        }
        let p = IslandPanel(frame: .zero)
        let host = FirstClickHostingView(rootView: IslandView(model: model))
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

        // Two-finger swipe left/right over the open island changes page.
        if let sw = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel], handler: { e in
            let dx = e.scrollingDeltaX, dy = e.scrollingDeltaY, phase = e.phase, momentum = e.momentumPhase
            MainActor.assumeIsolated { self.swiped(dx: dx, dy: dy, phase: phase, momentum: momentum) }
            return e
        }) { monitors.append(sw) }

        bus.events.receive(on: RunLoop.main).sink { [weak self] e in
            MainActor.assumeIsolated { self?.handle(e) }
        }.store(in: &subs)
    }

    public static let hideIdleKey = "hideIdleVirtualIsland"
    /// What the island does in full-screen apps on a screen without a notch (IslandModel.Aside).
    public static let fullScreenKey = "islandFullScreen"
    /// beta 8 kept a yes/no under this name; "no" meant behave as usual
    static let oldStepAsideKey = "islandStepsAsideInFullScreen"
    public static var fullScreenStyle: IslandModel.Aside {
        let d = UserDefaults.standard
        if let s = d.string(forKey: fullScreenKey).flatMap(IslandModel.Aside.init) { return s }
        if d.object(forKey: oldStepAsideKey) as? Bool == false { return .normal }
        return .passThrough
    }

    /// How long the pointer rests on a virtual island before it opens. A hardware notch
    /// has nothing under it, so it opens at once; a virtual one covers tabs and toolbars.
    static let virtualOpenDelay: TimeInterval = 0.35
    private var hoverSince: Date?
    private var openTask: Task<Void, Never>?
    private var spaceObservers: [NSObjectProtocol] = []

    /// True when the frontmost app has a window covering the whole of this screen.
    static func fullScreenApp(on screen: NSScreen) -> Bool {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return false }
        // window bounds use top-left origin on the main display
        let main = NSScreen.screens.first?.frame ?? screen.frame
        let f = screen.frame
        let target = CGRect(x: f.minX, y: main.maxY - f.maxY, width: f.width, height: f.height)
        return list.contains { w in
            guard (w[kCGWindowOwnerPID as String] as? pid_t) == pid, (w[kCGWindowLayer as String] as? Int) == 0,
                  let b = w[kCGWindowBounds as String] as? [String: CGFloat] else { return false }
            let r = CGRect(x: b["X"] ?? 0, y: b["Y"] ?? 0, width: b["Width"] ?? 0, height: b["Height"] ?? 0)
            return abs(r.minX - target.minX) < 2 && abs(r.minY - target.minY) < 2 && r.width >= target.width - 2 && r.height >= target.height - 2
        }
    }

    /// Work out again whether a full-screen app is in front (app switched, space changed, settings changed).
    func updateStepAside() {
        guard let screen = DisplayManager.preferredScreen else { return }
        let full = !model.isHardwareNotch && Self.fullScreenApp(on: screen)
        let aside: IslandModel.Aside = full ? Self.fullScreenStyle : .normal
        if aside != model.aside {
            withAnimation(model.spring) { model.aside = aside }
            if aside != .normal, model.hovering { closeNow() }
        }
    }

    // MARK: Full-screen apps on screens without a notch

    /// The pointer is pushed against the top edge of the screen, above the island: that's the
    /// only thing that opens it over a full-screen app, so tabs just below stay clickable.
    private func atTopEdge(_ p: CGPoint) -> Bool {
        guard let g = geometry else { return false }
        let r = islandRect
        return p.y >= g.screenFrame.maxY - 3 && p.x >= r.minX - 20 && p.x <= r.maxX + 20
    }

    private func closeNow() {
        withAnimation(model.spring) { model.hovering = false }
        model.resetPage()
        panel?.ignoresMouseEvents = true
    }

    /// Read the island settings again and move it if needed (Settings calls this).
    public func settingsChanged() {
        model.hideIdleVirtual = UserDefaults.standard.bool(forKey: Self.hideIdleKey)
        layout()
        updateStepAside()
    }

    private var screenID: CGDirectDisplayID?

    private func layout() {
        guard let screen = DisplayManager.preferredScreen, let panel else { return }
        screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
        let g = DisplayManager.notch(on: screen)
        geometry = g
        model.notchSize = g.rect.size
        model.isHardwareNotch = g.isHardware
        let c = Self.canvas
        panel.setFrame(NSRect(x: g.rect.midX - c.width / 2, y: g.screenFrame.maxY - c.height, width: c.width, height: c.height), display: true)
        updateStepAside()
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

    private var swipeX: CGFloat = 0
    private var swipeUsed = false

    private func swiped(dx: CGFloat, dy: CGFloat, phase: NSEvent.Phase, momentum: NSEvent.Phase) {
        guard model.hovering, momentum.isEmpty else { return }
        if phase.contains(.began) { swipeX = 0; swipeUsed = false }
        if phase.contains(.ended) || phase.contains(.cancelled) { swipeX = 0; swipeUsed = false; return }
        guard !swipeUsed, abs(dx) > abs(dy) else { return }
        swipeX += dx
        if abs(swipeX) > 36 {
            swipeUsed = true  // one page per swipe
            model.step(swipeX < 0 ? 1 : -1)
        }
    }

    /// "The screen with the pointer": follow it, but never while the island is open.
    private func followPointer() {
        guard DisplayManager.placement == .pointer, model.mode == .closed || model.mode == .compact,
              let screen = DisplayManager.preferredScreen,
              (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) != screenID else { return }
        layout()
    }

    private func pointerMoved() {
        followPointer()
        let p = NSEvent.mouseLocation
        // dragging files: open a bit earlier so the shelf is there to catch them
        let margin: CGFloat = isDraggingFiles ? 60 : 10
        let inside = islandRect.insetBy(dx: -margin, dy: -margin).contains(p)
        if inside {
            // a cancelled task must be cleared too, or the island can never close again
            leaveTask?.cancel()
            leaveTask = nil
            if model.hovering {
                if isDraggingFiles { model.go(to: .shelf) } else { model.interacted() }
                return
            }
            // files dragged over the notch always open it: that's how the shelf works
            if isDraggingFiles { openTask?.cancel(); openNow(); model.go(to: .shelf); return }
            // in a full-screen app the island stays out of the way
            switch model.aside {
            case .hidden: return
            case .passThrough:
                // tabs sit just below: only the very top edge opens it, and never mid-click
                if atTopEdge(p), NSEvent.pressedMouseButtons == 0 { openNow() }
                return
            case .normal: break
            }
            // a hardware notch opens at once; a virtual island waits, and never opens mid-click
            if model.isHardwareNotch { openNow(); return }
            if NSEvent.pressedMouseButtons != 0 { hoverSince = nil; openTask?.cancel(); return }
            if hoverSince == nil {
                hoverSince = Date()
                openTask?.cancel()
                openTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(Self.virtualOpenDelay))
                    guard let self, !Task.isCancelled, self.hoverSince != nil,
                          NSEvent.pressedMouseButtons == 0,
                          self.islandRect.insetBy(dx: -10, dy: -10).contains(NSEvent.mouseLocation) else { return }
                    self.openNow()
                }
            }
        } else if !model.hovering {
            hoverSince = nil
            openTask?.cancel()
        } else if model.hovering, leaveTask == nil {
            // small grace period so the island doesn't flicker at its edge
            leaveTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(220))
                guard let self, !Task.isCancelled else { return }
                self.leaveTask = nil
                if !self.islandRect.insetBy(dx: -10, dy: -6).contains(NSEvent.mouseLocation), !self.model.dropTargeted {
                    withAnimation(self.model.spring) { self.model.hovering = false }
                    self.model.resetPage()
                    self.panel?.ignoresMouseEvents = true
                }
            }
        }
    }

    private func openNow() {
        hoverSince = nil
        guard !model.hovering else { return }
        model.interacted()
        withAnimation(model.spring) { model.hovering = true }
        panel?.ignoresMouseEvents = false
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
            else if b.isLow, old?.isLow != true { model.show(.battery(b), for: 5) }
        }
    }

    private func applyTheme(_ t: Theme) {
        // the colours ease from the old theme to the new one
        withAnimation(.easeInOut(duration: model.reduceMotion ? 0 : 0.45)) {
            model.accent = Color(.sRGB, red: t.accent.red, green: t.accent.green, blue: t.accent.blue, opacity: 1)
            model.glowColor = t.glowColor.map { Color(.sRGB, red: $0.red, green: $0.green, blue: $0.blue, opacity: 1) }
            model.glowOn = t.glowColor != nil
        }
        model.themeName = t.name
        model.idleStyle = Theme.Notch.idleStyles.contains(t.notch.idle) ? t.notch.idle : "breathing"
        model.showsVisualizer = t.notch.visualizer ?? true
    }

    private func applyEnergy(_ b: EnergyGovernor.Budget) {
        model.animate = b.fps > 0
        model.reduceMotion = b.reduceMotion
    }
}
