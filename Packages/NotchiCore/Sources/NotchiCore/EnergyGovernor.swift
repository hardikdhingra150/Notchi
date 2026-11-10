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
        /// Why animations are paused or slowed, in plain words (nil at full speed).
        public var reason: String?

        public init(fps: Int, onBattery: Bool, lowPower: Bool, reduceMotion: Bool, reason: String? = nil) {
            self.fps = fps; self.onBattery = onBattery; self.lowPower = lowPower; self.reduceMotion = reduceMotion; self.reason = reason
        }
    }

    public enum Thermal: Int, Sendable { case nominal, fair, serious, critical }

    /// What the Mac is doing right now.
    public struct Inputs: Equatable, Sendable {
        public var onBattery = false
        /// 0...1, or nil on a Mac without a battery
        public var batteryLevel: Double?
        public var lowPower = false
        public var reduceMotion = false
        public var thermal = Thermal.nominal
        public init(onBattery: Bool = false, batteryLevel: Double? = nil, lowPower: Bool = false, reduceMotion: Bool = false, thermal: Thermal = .nominal) {
            self.onBattery = onBattery; self.batteryLevel = batteryLevel; self.lowPower = lowPower; self.reduceMotion = reduceMotion; self.thermal = thermal
        }
    }

    /// What the user chose in Settings > Energy.
    public struct Rules: Equatable, Sendable {
        /// Animation speed on battery: 0 (paused), 15 or 30.
        public var batteryFPS = 15
        /// Pause everything when the battery is at or below 20%.
        public var pauseWhenLow = true
        public init(batteryFPS: Int = 15, pauseWhenLow: Bool = true) { self.batteryFPS = batteryFPS; self.pauseWhenLow = pauseWhenLow }
    }

    public static let fullFPS = 30
    public static let lowBattery = 0.2

    /// The rules, most important first. Kept free of system calls so it can be tested.
    public static func budget(for i: Inputs, rules: Rules) -> Budget {
        var fps = fullFPS
        var reason: String?
        if i.lowPower {
            fps = 0; reason = "Low Power Mode"
        } else if i.thermal.rawValue >= Thermal.serious.rawValue {
            fps = 0; reason = "your Mac is hot"
        } else if i.onBattery, rules.pauseWhenLow, let level = i.batteryLevel, level <= lowBattery {
            fps = 0; reason = "battery below 20%"
        } else if i.onBattery {
            fps = min(max(rules.batteryFPS, 0), fullFPS)
            if fps < fullFPS { reason = "on battery" }
        }
        if fps > 15, i.thermal == .fair {
            fps = 15; reason = "your Mac is warm"
        }
        return Budget(fps: fps, onBattery: i.onBattery, lowPower: i.lowPower, reduceMotion: i.reduceMotion, reason: reason)
    }

    public private(set) var budget: Budget
    public private(set) var inputs = Inputs()
    public var rules: Rules {
        didSet {
            guard rules != oldValue else { return }
            defaults.set(rules.batteryFPS, forKey: Self.fpsKey)
            defaults.set(rules.pauseWhenLow, forKey: Self.lowKey)
            update()
        }
    }
    /// What the user picked for animations on battery: paused (0), 15 or 30 fps.
    public var batteryFPS: Int {
        get { rules.batteryFPS }
        set { rules.batteryFPS = newValue }
    }

    static let fpsKey = "batteryFPS"
    static let lowKey = "pauseWhenBatteryLow"
    private let defaults: UserDefaults
    private let bus: EventBus
    private var observers: [NSObjectProtocol] = []
    private var runLoopSource: CFRunLoopSource?

    public init(bus: EventBus, defaults: UserDefaults = .standard) {
        self.bus = bus
        self.defaults = defaults
        rules = Rules(batteryFPS: defaults.object(forKey: Self.fpsKey) as? Int ?? 15,
                      pauseWhenLow: defaults.object(forKey: Self.lowKey) as? Bool ?? true)
        budget = Budget(fps: Self.fullFPS, onBattery: false, lowPower: false, reduceMotion: false)
        let nc = NotificationCenter.default
        let wnc = NSWorkspace.shared.notificationCenter
        observers.append(nc.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        })
        observers.append(wnc.addObserver(forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        })
        observers.append(nc.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        })
        // power source changes (plugged in, unplugged, charge level)
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
        let thermal: Thermal = switch ProcessInfo.processInfo.thermalState {
        case .nominal: .nominal
        case .fair: .fair
        case .serious: .serious
        case .critical: .critical
        @unknown default: .nominal
        }
        inputs = Inputs(onBattery: Self.isOnBattery(), batteryLevel: BatteryMonitor.current()?.level,
                        lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled,
                        reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion, thermal: thermal)
        let next = Self.budget(for: inputs, rules: rules)
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
