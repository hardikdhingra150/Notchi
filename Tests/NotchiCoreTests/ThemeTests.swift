import Foundation
import Testing
@testable import NotchiCore

@Suite struct ThemeTests {
    let sample = """
    {
      "schema": 1, "id": "neon-rain", "name": "Neon Rain", "author": "you", "version": "1.0.0",
      "appearance": "dark", "accent": "#7C5CFF",
      "glass": { "blur": 0.8, "tint": 0.25 },
      "wallpaper": { "type": "shader", "src": "rain.metal", "fps": 30 },
      "icons": { "pack": "neon-line", "tintFolders": true },
      "notch": { "glow": "accent", "idle": "breathing", "visualizer": true },
      "sidebar": { "widgets": ["nowPlaying", "calendar", "stats"] },
      "dock": { "style": "floating-glass", "magnify": 1.4 },
      "menuBar": { "tint": "accent", "opacity": 0.4 },
      "sounds": { "pack": "soft-synth" },
      "cursor": { "trail": "spark" }
    }
    """

    @Test func decodesBlueprintExample() throws {
        let t = try Theme.decode(Data(sample.utf8))
        #expect(t.id == "neon-rain")
        #expect(t.appearance == .dark)
        #expect(t.accent == HexColor("#7C5CFF"))
        #expect(t.wallpaper?.type == .shader)
        #expect(t.dock?.magnify == 1.4)
    }

    @Test func rejectsUnknownSchema() {
        let bad = sample.replacingOccurrences(of: "\"schema\": 1", with: "\"schema\": 9")
        #expect(throws: ThemeError.unsupportedSchema(9)) { try Theme.decode(Data(bad.utf8)) }
    }

    @Test func rejectsBadID() {
        let bad = sample.replacingOccurrences(of: "\"neon-rain\"", with: "\"Neon Rain!\"")
        #expect(throws: ThemeError.invalidID("Neon Rain!")) { try Theme.decode(Data(bad.utf8)) }
    }

    @Test func rejectsOutOfRangeGlass() {
        let bad = sample.replacingOccurrences(of: "\"blur\": 0.8", with: "\"blur\": 3")
        #expect(throws: ThemeError.outOfRange("glass.blur")) { try Theme.decode(Data(bad.utf8)) }
    }

    @Test func builtInThemeFilesAreValid() throws {
        let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("../../Themes").standardized
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" }
        #expect(files.count >= 5)
        for f in files { _ = try Theme.decode(Data(contentsOf: f)) }
    }

    @Test func hexColorRoundTrips() {
        #expect(HexColor("#ff6a3d")?.description == "#FF6A3D")
        #expect(HexColor("FF6A3D80")?.alpha == Double(0x80) / 255)
        #expect(HexColor("#12") == nil)
        #expect(HexColor("#GGGGGG") == nil)
    }

    @Test func fallbackThemeIsValid() throws {
        try Theme.paper.validate()
    }
}

@Suite struct IPCTests {
    @Test func commandsRoundTrip() {
        let cmds: [IPCCommand] = [.notify(message: "Build done ✅"), .progress(value: 0.42, label: "Exporting"), .apply(theme: "paper", replyTo: nil), .apply(theme: "midnight", replyTo: "t1"), .ping(replyTo: "abc")]
        for c in cmds {
            #expect(IPC.decode(IPCCommand.self, from: IPC.encode(c)) == c)
        }
    }
}

@Suite struct BatteryTests {
    @Test func readingIsInRangeWhenPresent() {
        // Desktop Macs and CI runners have no battery; laptops must report 0...1.
        if let b = BatteryMonitor.current() {
            #expect((0...1).contains(b.level))
        }
    }
}
