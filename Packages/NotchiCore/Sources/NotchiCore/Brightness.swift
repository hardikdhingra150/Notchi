import CoreGraphics
import Foundation

/// Built-in display brightness.
///
/// macOS has no public brightness API, so this uses DisplayServices, the private
/// framework that MonitorControl and other open-source tools rely on. It is loaded
/// with dlopen: if a future macOS removes it, `isAvailable` turns false and the
/// brightness keys are simply left to macOS.
@MainActor
public enum Brightness {
    private typealias GetFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetFn = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private static let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
    private static let getFn: GetFn? = symbol("DisplayServicesGetBrightness")
    private static let setFn: SetFn? = symbol("DisplayServicesSetBrightness")

    private static func symbol<T>(_ name: String) -> T? {
        guard let handle, let s = dlsym(handle, name) else { return nil }
        return unsafeBitCast(s, to: T.self)
    }

    /// The built-in panel (brightness keys only drive that one).
    public static var builtInDisplay: CGDirectDisplayID? {
        var count: UInt32 = 0
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        guard CGGetOnlineDisplayList(16, &ids, &count) == .success else { return nil }
        return ids.prefix(Int(count)).first { CGDisplayIsBuiltin($0) != 0 }
    }

    public static var isAvailable: Bool { getFn != nil && setFn != nil && builtInDisplay != nil && level != nil }

    /// 0...1, or nil when it can't be read (lid closed, no built-in display).
    public static var level: Double? {
        guard let getFn, let id = builtInDisplay else { return nil }
        var b: Float = 0
        guard getFn(id, &b) == 0 else { return nil }
        return Double(b)
    }

    @discardableResult
    public static func set(_ value: Double) -> Bool {
        guard let setFn, let id = builtInDisplay else { return false }
        return setFn(id, Float(min(max(value, 0), 1))) == 0
    }

    /// One key press: 16 steps like macOS, or 64 with Shift+Option. Returns the new level.
    public static func step(_ direction: Int, fine: Bool) -> Double? {
        guard let now = level else { return nil }
        let next = LevelStep.next(now, direction: direction, fine: fine)
        return set(next) ? next : nil
    }
}

/// The same stepping macOS uses for volume and brightness keys.
public enum LevelStep {
    public static func next(_ value: Double, direction: Int, fine: Bool) -> Double {
        let n = fine ? 64.0 : 16.0
        return min(max((value * n).rounded() + Double(direction), 0), n) / n
    }
}
