import AppKit

/// Finds the notch on each display. Macs without one get a virtual island.
@MainActor
public enum DisplayManager {
    public struct NotchGeometry: Equatable, Sendable {
        /// The notch rect in global screen coordinates (origin bottom-left).
        public var rect: CGRect
        /// false when this is a virtual island on a screen without a notch.
        public var isHardware: Bool
        public var screenFrame: CGRect
    }

    /// Which screen the island lives on (Settings > General).
    public enum Placement: String, CaseIterable, Sendable {
        /// the built-in notch when there is one, else the screen with the menu bar
        case automatic
        /// always the screen with the menu bar (set in System Settings > Displays)
        case menuBar
        /// whichever screen the pointer is on; it moves when you do
        case pointer

        public var label: String {
            switch self {
            case .automatic: "The notch, or the menu bar screen"
            case .menuBar: "The screen with the menu bar"
            case .pointer: "The screen with the pointer"
            }
        }
    }

    public static let placementKey = "islandScreen"
    public static var placement: Placement {
        get { UserDefaults.standard.string(forKey: placementKey).flatMap(Placement.init) ?? .automatic }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: placementKey) }
    }

    /// The screen to put the island on.
    public static var preferredScreen: NSScreen? { screen(for: placement) }

    public static func screen(for placement: Placement, pointer: CGPoint = NSEvent.mouseLocation) -> NSScreen? {
        let menuBarScreen = NSScreen.screens.first   // macOS lists the menu bar screen first
        switch placement {
        case .automatic: return NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? menuBarScreen
        case .menuBar: return menuBarScreen
        case .pointer: return NSScreen.screens.first(where: { NSMouseInRect(pointer, $0.frame, false) }) ?? menuBarScreen
        }
    }

    public static func notch(on screen: NSScreen) -> NotchGeometry {
        let f = screen.frame
        let top = screen.safeAreaInsets.top
        if top > 0, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            // the notch is the gap between the two menu bar areas beside it
            let x = f.minX + left.width
            let w = f.width - left.width - right.width
            return NotchGeometry(rect: CGRect(x: x, y: f.maxY - top, width: w, height: top), isHardware: true, screenFrame: f)
        }
        // virtual island: same proportions as a 14" MacBook notch, hanging from the top
        let menuBar = f.maxY - screen.visibleFrame.maxY
        let h = max(menuBar, 24)
        let w: CGFloat = 190
        return NotchGeometry(rect: CGRect(x: f.midX - w / 2, y: f.maxY - h, width: w, height: h), isHardware: false, screenFrame: f)
    }
}
