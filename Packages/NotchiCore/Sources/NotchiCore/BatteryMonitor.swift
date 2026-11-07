import Foundation
import IOKit.ps

/// Posts battery level and charging state whenever the power source changes.
@MainActor
public final class BatteryMonitor {
    private let bus: EventBus
    private var source: CFRunLoopSource?
    public private(set) var state: BatteryState?

    public init(bus: EventBus) { self.bus = bus }

    public func start() {
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        if let src = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            let me = Unmanaged<BatteryMonitor>.fromOpaque(ctx).takeUnretainedValue()
            MainActor.assumeIsolated { me.read() }
        }, ctx)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), src, .defaultMode)
            source = src
        }
        read()
    }

    public func read() {
        guard let s = Self.current(), s != state else { return }
        state = s
        bus.post(.battery(s))
    }

    /// nil on Macs without a battery.
    public nonisolated static func current() -> BatteryState? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for ps in list {
            guard let d = IOPSGetPowerSourceDescription(info, ps)?.takeUnretainedValue() as? [String: Any],
                  (d[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType,
                  let cur = d[kIOPSCurrentCapacityKey] as? Int, let max = d[kIOPSMaxCapacityKey] as? Int, max > 0 else { continue }
            return BatteryState(
                level: Double(cur) / Double(max),
                isCharging: d[kIOPSIsChargingKey] as? Bool ?? false,
                isPluggedIn: (d[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue)
        }
        return nil
    }
}
