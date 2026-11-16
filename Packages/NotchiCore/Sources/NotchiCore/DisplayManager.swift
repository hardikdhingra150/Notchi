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

    /// The virtual island's closed size, in points.
    public static let virtualSize = CGSize(width: 190, height: 24)

    public static func notch(on screen: NSScreen) -> NotchGeometry {
        let f = screen.frame
        let top = screen.safeAreaInsets.top
        if top > 0, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            // the notch is the gap between the two menu bar areas beside it
            let x = f.minX + left.width
            let w = f.width - left.width - right.width
            return NotchGeometry(rect: CGRect(x: x, y: f.maxY - top, width: w, height: top), isHardware: true, screenFrame: f)
        }
        // virtual island: one fixed size, hanging from the top. It used to follow the menu bar's
        // height, so it came out taller or shorter depending on whether a full-screen app had
        // hidden the menu bar when Notchi last measured the screen.
        let w = virtualSize.width, h = virtualSize.height
        return NotchGeometry(rect: CGRect(x: f.midX - w / 2, y: f.maxY - h, width: w, height: h), isHardware: false, screenFrame: f)
    }
}
