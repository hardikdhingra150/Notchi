import Foundation
import Testing
@testable import NotchiCore

@Suite struct SetupBackupTests {
    func defaults() -> UserDefaults { UserDefaults(suiteName: "notchi-tests-\(UUID().uuidString)")! }

    @Test func backupAndRestoreBringEverythingBack() throws {
        let s = Scratch()
        let support = s.url.appendingPathComponent("Notchi")
        _ = s.file("Notchi/Themes/dusk/theme.json", String(decoding: try sampleTheme().encoded(), as: UTF8.self))
        _ = s.file("Notchi/Themes/dusk/wallpapers/dusk.mp4", "theme video")
        _ = s.file("Notchi/icons.json", #"[{"path":"/tmp/a","badge":"🚀","date":"2026-01-01T00:00:00Z"}]"#)
        let video = s.file("Movies/waves.mp4", "my video")
        let d = defaults()
        d.set("dusk", forKey: "activeTheme")
        d.set(video.path, forKey: "wallpaperVideo")
        d.set(0, forKey: "batteryFPS")
        d.set(false, forKey: "replaceSystemHUD")
        d.set("not ours", forKey: "somethingElse")

        let file = s.url.appendingPathComponent("setup.notchibackup")
        let made = try SetupBackup.create(to: file, defaults: d, support: support, appVersion: "0.5.0")
        #expect(made.themeCount == 1)
        #expect(made.iconCount == 1)
        #expect(made.wallpaperFile == "waves.mp4")
        #expect(made.settings["somethingElse"] == nil)
        #expect(try SetupBackup.inspect(file) == made)

        // lose everything, on a "new Mac" where the video is gone too
        try FileManager.default.removeItem(at: support)
        try FileManager.default.removeItem(at: video)
        let fresh = defaults()
        fresh.set(true, forKey: "themeTintsIcons")
        let support2 = s.url.appendingPathComponent("NewMac/Notchi")
        try SetupBackup.restore(from: file, defaults: fresh, support: support2)

        #expect(fresh.string(forKey: "activeTheme") == "dusk")
        #expect(fresh.integer(forKey: "batteryFPS") == 0)
        #expect(fresh.object(forKey: "replaceSystemHUD") as? Bool == false)
        #expect(fresh.object(forKey: "themeTintsIcons") == nil)   // wasn't in the backup: back to default
        let restoredVideo = try #require(fresh.string(forKey: "wallpaperVideo"))
        #expect(restoredVideo == support2.appendingPathComponent("Wallpapers/waves.mp4").path)
        #expect(try String(contentsOfFile: restoredVideo, encoding: .utf8) == "my video")
        #expect(try ThemePackage.read(support2.appendingPathComponent("Themes/dusk")).theme == sampleTheme())
        #expect(FileManager.default.fileExists(atPath: support2.appendingPathComponent("icons.json").path))
    }

    @Test func restoreReplacesWhatIsThere() throws {
        let s = Scratch()
        let support = s.url.appendingPathComponent("Notchi")
        let file = s.url.appendingPathComponent("empty.notchibackup")
        try SetupBackup.create(to: file, defaults: defaults(), support: support)
        _ = s.file("Notchi/Themes/later/theme.json", "{}")
        _ = s.file("Notchi/icons.json", "[]")
        try SetupBackup.restore(from: file, defaults: defaults(), support: support)
        #expect(!FileManager.default.fileExists(atPath: support.appendingPathComponent("Themes/later").path))
        #expect(!FileManager.default.fileExists(atPath: support.appendingPathComponent("icons.json").path))
    }

    @Test func refusesFilesThatAreNotBackups() throws {
        let s = Scratch()
        _ = s.file("stuff/readme.txt")
        let zip = s.url.appendingPathComponent("stuff.notchibackup")
        try Archive.create(from: s.url.appendingPathComponent("stuff"), to: zip)
        #expect(throws: SetupBackup.BackupError.notABackup("stuff.notchibackup")) { try SetupBackup.restore(from: zip, defaults: defaults(), support: s.url) }

        _ = s.file("future/manifest.json", #"{"schema":99,"created":"2030-01-01T00:00:00Z","appVersion":"9","settings":{},"themeCount":0,"iconCount":0}"#)
        let future = s.url.appendingPathComponent("future.notchibackup")
        try Archive.create(from: s.url.appendingPathComponent("future"), to: future)
        #expect(throws: SetupBackup.BackupError.unsupportedSchema(99)) { try SetupBackup.inspect(future) }
    }

    @Test func automaticBackupsKeepOnlyTheNewest() throws {
        let s = Scratch()
        let d = defaults()
        for i in 0..<(SetupBackup.keep + 3) {
            try SetupBackup.automatic("before-reset", defaults: d, support: s.url, now: Date(timeIntervalSince1970: Double(1_800_000_000 + i * 60)))
        }
        let left = try FileManager.default.contentsOfDirectory(atPath: s.url.appendingPathComponent("Backups").path)
        #expect(left.count == SetupBackup.keep)
    }
}
