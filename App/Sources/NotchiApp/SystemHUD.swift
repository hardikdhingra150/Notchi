import AppKit
import NotchiCore
import Observation

/// Replaces the macOS volume and brightness HUD with the notch.
///
/// macOS has no setting to hide its own HUD, so Notchi catches the keys first
/// (MediaKeyTap), changes the volume or brightness itself, and shows the level in
/// the notch. The system HUD never appears because macOS never sees the key.
/// Needs Accessibility access, asked for only when the user turns this on.
@MainActor
@Observable
final class SystemHUD {
    enum State: String {
        case off = "off"
        case needsPermission = "needs Accessibility access"
        case active = "on"
        case failed = "couldn't start"
    }

    static let defaultsKey = "replaceSystemHUD"
    private(set) var state: State = .off

    @ObservationIgnored private let tap = MediaKeyTap()
    @ObservationIgnored private let bus: EventBus
    @ObservationIgnored private let volume: VolumeMonitor
    @ObservationIgnored private var permissionTimer: Timer?
    @ObservationIgnored private var permissionChecks = 0

    init(bus: EventBus, volume: VolumeMonitor) {
        self.bus = bus
        self.volume = volume
        tap.handler = { [weak self] key, isDown, mods in self?.handle(key, isDown: isDown, mods: mods) ?? false }
    }

    /// On by default; it only takes effect once Accessibility access is granted.
    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.defaultsKey) as? Bool ?? true
    }

    /// At launch: start quietly if allowed, never pop up a permission dialog.
    func start() {
        guard isEnabled else { return }
        activate(prompt: false)
    }

    func setEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: Self.defaultsKey)
        if on { activate(prompt: true) } else { deactivate() }
    }

    /// Ask macOS for Accessibility access again (from the menu or Settings).
    func requestPermission() {
        UserDefaults.standard.set(true, forKey: Self.defaultsKey)
        activate(prompt: true)
        if state == .needsPermission,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func activate(prompt: Bool) {
        guard MediaKeyTap.isTrusted(prompt: prompt) else {
            state = .needsPermission
            waitForPermission()
            return
        }
        permissionTimer?.invalidate()
        state = tap.start() ? .active : .failed
    }

    private func deactivate() {
        permissionTimer?.invalidate()
        tap.stop()
        state = .off
    }

    /// macOS doesn't announce when access is granted, so check every few seconds for a while.
    private func waitForPermission() {
        permissionTimer?.invalidate()
        permissionChecks = 0
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkPermission() }
        }
    }

    private func checkPermission() {
        permissionChecks += 1
        guard isEnabled, permissionChecks < 150 else { permissionTimer?.invalidate(); return }
        if MediaKeyTap.isTrusted(prompt: false) { activate(prompt: false) }
    }

    /// true = Notchi handled the key, so macOS (and its HUD) never sees it.
    private func handle(_ key: MediaKeyTap.Key, isDown: Bool, mods: NSEvent.ModifierFlags) -> Bool {
        // Option + key opens the matching System Settings pane; leave that to macOS.
        if mods.contains(.option) && !mods.contains(.shift) { return false }
        let fine = mods.contains(.option) && mods.contains(.shift)
        switch key {
        case .soundUp, .soundDown, .mute:
            guard volume.canSetVolume else { return false }
            guard isDown else { return true }
            if key == .mute { volume.toggleMute() } else { volume.step(key == .soundUp ? 1 : -1, fine: fine) }
            return true
        case .brightnessUp, .brightnessDown:
            guard Brightness.isAvailable else { return false }
            guard isDown else { return true }
            if let level = Brightness.step(key == .brightnessUp ? 1 : -1, fine: fine) {
                bus.post(.brightness(level: level))
            }
            return true
        }
    }
}
