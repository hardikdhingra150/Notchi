import AppKit
import Foundation
import IOKit.ps

/// Has the final say over every module's frame rate (blueprint section 8 and 14).
@MainActor
public final class EnergyGovernor {
    public struct Budget: Equatable, Sendable {
        /// Frames per second animations may use. 0 means "don't animate".
        public var fps: Int
        public var onBattery: Bool
        public var lowPower: Bool
        public var reduceMotion: Bool
    }

    public private(set) var budget: Budget
    /// What the user picked for wallpaper on battery: paused (0) or 15 fps.
    public var batteryFPS = 15 { didSet { update() } }

    private let bus: EventBus
    private var observers: [NSObjectProtocol] = []
    private var runLoopSource: CFRunLoopSource?

    public init(bus: EventBus) {
        self.bus = bus
        budget = Budget(fps: 30, onBattery: false, lowPower: false, reduceMotion: false)
        let nc = NotificationCenter.default
        let wnc = NSWorkspace.shared.notificationCenter
        observers.append(nc.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        })
        observers.append(wnc.addObserver(forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        })
        // power source changes (plugged in / unplugged)
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        if let src = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            let me = Unmanaged<EnergyGovernor>.fromOpaque(ctx).takeUnretainedValue()
            MainActor.assumeIsolated { me.update() }
        }, ctx)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), src, .defaultMode)
            runLoopSource = src
        }
        update()
    }

    public func update() {
        let onBattery = Self.isOnBattery()
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let fps = lowPower ? 0 : onBattery ? batteryFPS : 30
        let next = Budget(fps: fps, onBattery: onBattery, lowPower: lowPower, reduceMotion: reduceMotion)
        guard next != budget else { return }
        budget = next
        bus.post(.energy(next))
    }

    public static func isOnBattery() -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let type = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String? else { return false }
        return type == kIOPSBatteryPowerValue
    }
}
