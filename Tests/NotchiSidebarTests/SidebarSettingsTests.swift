import Foundation
import Testing
@testable import NotchiCore
@testable import NotchiSidebar

@Suite(.serialized) struct SidebarSettingsTests {
    init() { UserDefaults.standard.removeObject(forKey: SidebarSettings.widgetsKey) }

    @Test func themeListGetsAClockOnTopAndUnknownNamesAreSkipped() {
        var t = Theme.paper
        t.sidebar = .init(widgets: ["stats", "weather", "nowPlaying", "stats"])
        #expect(SidebarSettings.widgets(for: t) == [.clock, .stats, .nowPlaying])
        t.sidebar = nil
        #expect(SidebarSettings.widgets(for: t) == [.clock, .nowPlaying, .calendar, .stats])
    }

    @Test func yourChoiceWinsOverTheTheme() {
        SidebarSettings.customWidgets = [.notes, .calendar]
        defer { UserDefaults.standard.removeObject(forKey: SidebarSettings.widgetsKey) }
        #expect(SidebarSettings.widgets(for: .paper) == [.notes, .calendar])
        SidebarSettings.customWidgets = []
        #expect(SidebarSettings.widgets(for: .paper) == [])
    }
}
