import Foundation
import NotchiCore

/// The widgets the sidebar can show, in the order the user (or the theme) picked.
public enum SidebarWidget: String, CaseIterable, Sendable, Identifiable {
    case clock, nowPlaying, calendar, stats, notes

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .clock: "Clock"
        case .nowPlaying: "Now playing"
        case .calendar: "Calendar"
        case .stats: "System"
        case .notes: "Notes"
        }
    }
    public var symbol: String {
        switch self {
        case .clock: "clock"
        case .nowPlaying: "music.note"
        case .calendar: "calendar"
        case .stats: "gauge.with.dots.needle.33percent"
        case .notes: "note.text"
        }
    }
}

/// Sidebar settings, kept in UserDefaults (and so in backups and profiles).
public enum SidebarSettings {
    public static let widgetsKey = "sidebarWidgets"
    public static let edgeKey = "sidebarEdge"
    public static let hotEdgeKey = "sidebarHotEdge"

    public enum Edge: String, CaseIterable, Sendable { case right, left }

    public static var edge: Edge {
        get { UserDefaults.standard.string(forKey: edgeKey).flatMap(Edge.init) ?? .right }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: edgeKey) }
    }

    /// Open when the pointer rests against the screen edge. On unless turned off.
    public static var hotEdge: Bool {
        get { UserDefaults.standard.object(forKey: hotEdgeKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: hotEdgeKey) }
    }

    /// The widgets you chose, or nil when you haven't (then the theme decides).
    public static var customWidgets: [SidebarWidget]? {
        get { UserDefaults.standard.string(forKey: widgetsKey).map(parse) }
        set { UserDefaults.standard.set(newValue.map { $0.map(\.rawValue).joined(separator: ",") }, forKey: widgetsKey) }
    }

    /// Unknown names are skipped and duplicates dropped, so any theme file is safe.
    public static func parse<S: Sequence>(_ names: S) -> [SidebarWidget] where S.Element: StringProtocol {
        var out: [SidebarWidget] = []
        for n in names {
            if let w = SidebarWidget(rawValue: n.trimmingCharacters(in: .whitespaces)), !out.contains(w) { out.append(w) }
        }
        return out
    }
    static func parse(_ csv: String) -> [SidebarWidget] { parse(csv.split(separator: ",")) }

    /// What the sidebar shows: your choice, else the theme's list with a clock on top.
    public static func widgets(for theme: Theme) -> [SidebarWidget] {
        if let mine = customWidgets { return mine }
        let fromTheme = parse(theme.sidebar?.widgets ?? ["nowPlaying", "calendar", "stats"])
        return [.clock] + fromTheme.filter { $0 != .clock }
    }
}
