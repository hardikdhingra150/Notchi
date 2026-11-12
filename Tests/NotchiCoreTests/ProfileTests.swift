import Foundation
import Testing
@testable import NotchiCore

@Suite struct ProfileTests {
    func defaults() -> UserDefaults { UserDefaults(suiteName: "notchi-tests-\(UUID().uuidString)")! }

    @Test func saveSwitchAndRemove() throws {
        let s = Scratch()
        let store = ProfileStore(file: s.url.appendingPathComponent("profiles.json"))
        let d = defaults()
        d.set("midnight", forKey: "activeTheme"); d.set(0, forKey: "batteryFPS"); d.set("not ours", forKey: "other")
        try store.save(name: "  Night ", from: d)
        d.set("paper", forKey: "activeTheme"); d.removeObject(forKey: "batteryFPS"); d.set(true, forKey: "hideIdleVirtualIsland")
        try store.save(name: "Work", from: d)
        #expect(store.load().map(\.name) == ["Night", "Work"])

        try store.apply("night", to: d)
        #expect(d.string(forKey: "activeTheme") == "midnight")
        #expect(d.integer(forKey: "batteryFPS") == 0)
        #expect(d.object(forKey: "hideIdleVirtualIsland") == nil)   // not in that profile: back to default
        #expect(d.string(forKey: "other") == "not ours")              // not a Notchi setting: untouched

        try store.save(name: "WORK", from: d)                         // same name replaces
        #expect(store.load().count == 2)
        try store.remove("Night")
        #expect(store.load().map(\.name) == ["WORK"])
        #expect(throws: ProfileStore.ProfileError.unknown("Night")) { try store.apply("Night", to: d) }
        #expect(throws: ProfileStore.ProfileError.badName) { try store.save(name: "   ", from: d) }
    }
}
