import AppKit
import ApplicationServices
import CoreGraphics

/// Catches the volume, mute and brightness keys before macOS does, so Notchi can
/// show its own indicator in the notch instead of the system HUD.
///
/// Uses a CGEventTap on system-defined events, which needs Accessibility access.
/// Keys Notchi doesn't handle (or can't, like brightness on an external screen)
/// are passed straight through to macOS.
@MainActor
public final class MediaKeyTap {
    public enum Key: Int32, Sendable {
        case soundUp = 0, soundDown = 1, brightnessUp = 2, brightnessDown = 3, mute = 7
    }

    /// Return true to swallow the key. Called for key down (`isDown`) and key up.
    public var handler: (Key, _ isDown: Bool, NSEvent.ModifierFlags) -> Bool = { _, _, _ in false }

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    public init() {}

    public var isRunning: Bool { tap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }

    /// Accessibility access. With `prompt`, macOS shows its "allow" dialog.
    public static func isTrusted(prompt: Bool) -> Bool {
        let opts = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    /// Starts the tap. Returns false when macOS refuses (no Accessibility access).
    @discardableResult
    public func start() -> Bool {
        if tap != nil { return true }
        // NX_SYSDEFINED (media keys) plus plain key down/up: some keyboards send the
        // brightness keys as key codes 144/145 instead of media-key events.
        let mask = CGEventMask(1 << 14) | CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.keyUp.rawValue)
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: mediaKeyCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return false }
        tap = port
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        return true
    }

    public func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
    }

    /// true = swallow the event.
    fileprivate func handle(type: CGEventType, event: CGEvent) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }  // macOS switched us off; switch back on
            return false
        }
        if type == .keyDown || type == .keyUp {
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            let key: Key? = code == 144 ? .brightnessUp : code == 145 ? .brightnessDown : nil
            guard let key else { return false }
            return handler(key, type == .keyDown, NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue)))
        }
        guard type.rawValue == 14, let ns = NSEvent(cgEvent: event), ns.subtype.rawValue == 8 else { return false }
        let data = ns.data1
        guard let key = Key(rawValue: Int32((data & 0xFFFF_0000) >> 16)) else { return false }
        let isDown = ((data & 0xFF00) >> 8) == 0xA
        return handler(key, isDown, ns.modifierFlags)
    }
}

/// The C callback the event tap calls; it runs on the main run loop.
private func mediaKeyCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    nonisolated(unsafe) let ev = event
    nonisolated(unsafe) let ref = refcon
    let swallow = MainActor.assumeIsolated {
        Unmanaged<MediaKeyTap>.fromOpaque(ref).takeUnretainedValue().handle(type: type, event: ev)
    }
    return swallow ? nil : Unmanaged.passUnretained(event)
}
