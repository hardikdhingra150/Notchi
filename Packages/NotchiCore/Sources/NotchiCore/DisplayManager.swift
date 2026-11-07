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

    /// The screen to put the island on: the built-in notched screen when there is one, else the main screen.
    public static var preferredScreen: NSScreen? {
        NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main
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
