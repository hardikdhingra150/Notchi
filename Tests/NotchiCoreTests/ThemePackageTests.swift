import Foundation
import Testing
@testable import NotchiCore

/// A scratch folder that cleans up after itself.
final class Scratch {
    let url: URL
    init() {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("notchi-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    deinit { try? FileManager.default.removeItem(at: url) }
    func file(_ path: String, _ contents: String = "x") -> URL {
        let u = url.appendingPathComponent(path)
        try? FileManager.default.createDirectory(at: u.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? Data(contents.utf8).write(to: u)
        return u
    }
}

func sampleTheme(id: String = "dusk", wallpaper: String? = "wallpapers/dusk.mp4") -> Theme {
    var t = Theme.paper
    t.id = id
    t.name = "Dusk"
    t.author = "tester"
    t.accent = HexColor("#3366FF")!
    t.wallpaper = wallpaper.map { .init(type: .video, src: $0, fps: 30) }
    return t
}

@Suite struct ThemeFormatTests {
    @Test func assetPathsMustStayInsideTheTheme() {
        #expect(Theme.isSafeRelativePath("wallpapers/a.mp4"))
        #expect(Theme.isSafeRelativePath("a.mp4"))
        #expect(!Theme.isSafeRelativePath("../a.mp4"))
        #expect(!Theme.isSafeRelativePath("wallpapers/../../a.mp4"))
        #expect(!Theme.isSafeRelativePath("/etc/passwd"))
        #expect(!Theme.isSafeRelativePath("~/a.mp4"))
        #expect(!Theme.isSafeRelativePath(""))
        #expect(throws: ThemeError.badPath("../secret.mp4")) { try sampleTheme(wallpaper: "../secret.mp4").validate() }
    }

    @Test func rejectsBadGlowAndFps() {
        var t = sampleTheme()
        t.notch.glow = "sparkly"
        #expect(throws: ThemeError.self) { try t.validate() }
        t.notch.glow = "#00FFAA"
        #expect(t.glowColor == HexColor("#00FFAA"))
        t.notch.glow = "none"
        #expect(t.glowColor == nil)
        t.wallpaper?.fps = 240
        #expect(throws: ThemeError.self) { try t.validate() }
    }

    @Test func warnsAboutThingsThatDoNothingYet() {
        var t = sampleTheme()
        #expect(t.warnings().isEmpty)
        t.notch.idle = "disco"
        t.wallpaper?.type = .shader
        #expect(t.warnings().count == 2)
    }

    @Test func encodesBackToTheSameTheme() throws {
        let t = sampleTheme()
        #expect(try Theme.decode(t.encoded()) == t)
    }

    @Test func builtInThemesUseVideosThatExist() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../..").standardized
        let files = try FileManager.default.contentsOfDirectory(at: root.appendingPathComponent("Themes"), includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" }
        for f in files {
            let t = try Theme.decode(Data(contentsOf: f))
            #expect(t.warnings().isEmpty, "\(t.id): \(t.warnings())")
            let src = try #require(t.wallpaper?.src)
            // scripts/bundle.sh copies these from the website's wallpaper library
            let video = root.appendingPathComponent("web/public").appendingPathComponent(src)
            #expect(FileManager.default.fileExists(atPath: video.path), "\(t.id) wants \(src)")
        }
    }
}

@Suite struct ThemePackageTests {
    @Test func exportThenInstallRoundTrips() throws {
        let s = Scratch()
        let t = sampleTheme()
        let source = s.url.appendingPathComponent("source")
        _ = s.file("source/wallpapers/dusk.mp4", "pretend video")
        let pkg = s.url.appendingPathComponent("dusk.notchitheme")
        try ThemePackage.export(t, base: source, to: pkg)
        #expect(try Archive.entries(of: pkg).contains("theme.json"))

        let themes = s.url.appendingPathComponent("Themes")
        let installed = try ThemePackage.install(pkg, into: themes)
        #expect(installed == t)
        let (read, base) = try ThemePackage.read(themes.appendingPathComponent("dusk"))
        #expect(read == t)
        let video = try #require(ThemePackage.asset("wallpapers/dusk.mp4", base: base))
        #expect(try String(contentsOf: video, encoding: .utf8) == "pretend video")
    }

    @Test func exportFailsWhenTheVideoIsMissing() {
        let s = Scratch()
        #expect(throws: ThemePackage.PackageError.missingAsset("wallpapers/dusk.mp4")) {
            try ThemePackage.export(sampleTheme(), base: s.url, to: s.url.appendingPathComponent("x.notchitheme"))
        }
    }

    @Test func installsALooseJSONWithItsVideo() throws {
        let s = Scratch()
        let json = s.url.appendingPathComponent("dusk.json")
        try sampleTheme().encoded().write(to: json)
        _ = s.file("wallpapers/dusk.mp4")
        let themes = s.url.appendingPathComponent("Themes")
        try ThemePackage.install(json, into: themes)
        #expect(FileManager.default.fileExists(atPath: themes.appendingPathComponent("dusk/theme.json").path))
        #expect(FileManager.default.fileExists(atPath: themes.appendingPathComponent("dusk/wallpapers/dusk.mp4").path))
    }

    @Test func refusesPackagesWithoutAThemeOrItsVideo() throws {
        let s = Scratch()
        _ = s.file("empty/readme.txt")
        let empty = s.url.appendingPathComponent("empty.notchitheme")
        try Archive.create(from: s.url.appendingPathComponent("empty"), to: empty)
        #expect(throws: ThemePackage.PackageError.missingManifest) { try ThemePackage.install(empty, into: s.url.appendingPathComponent("T")) }

        try FileManager.default.createDirectory(at: s.url.appendingPathComponent("novideo"), withIntermediateDirectories: true)
        try sampleTheme().encoded().write(to: s.url.appendingPathComponent("novideo/theme.json"))
        let novideo = s.url.appendingPathComponent("novideo.notchitheme")
        try Archive.create(from: s.url.appendingPathComponent("novideo"), to: novideo)
        #expect(throws: ThemePackage.PackageError.missingAsset("wallpapers/dusk.mp4")) { try ThemePackage.install(novideo, into: s.url.appendingPathComponent("T")) }

        let notZip = s.file("fake.notchitheme", "this is not a zip")
        #expect(throws: Archive.ArchiveError.notAnArchive("fake.notchitheme")) { try ThemePackage.install(notZip, into: s.url.appendingPathComponent("T")) }
        #expect(throws: ThemePackage.PackageError.notATheme("a.txt")) { try ThemePackage.install(s.file("a.txt"), into: s.url.appendingPathComponent("T")) }
    }

    @Test func refusesArchivesThatEscapeTheirFolder() throws {
        let s = Scratch()
        // build a zip whose entry is "../escape.txt" with the system zip tool
        let inner = s.url.appendingPathComponent("a/b")
        try FileManager.default.createDirectory(at: inner, withIntermediateDirectories: true)
        _ = s.file("a/escape.txt")
        let zip = s.url.appendingPathComponent("evil.notchitheme")
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        p.currentDirectoryURL = inner
        p.arguments = ["-q", zip.path, "../escape.txt"]
        try p.run(); p.waitUntilExit()
        try #require(FileManager.default.fileExists(atPath: zip.path))
        #expect(throws: Archive.ArchiveError.unsafeEntry("../escape.txt")) { try Archive.extract(zip, to: s.url.appendingPathComponent("out")) }
        #expect(!FileManager.default.fileExists(atPath: s.url.appendingPathComponent("escape.txt").path))
    }

    @Test func refusesArchivesOverTheSizeLimit() throws {
        let s = Scratch()
        _ = s.file("big/data.bin", String(repeating: "a", count: 50_000))
        let zip = s.url.appendingPathComponent("big.zip")
        try Archive.create(from: s.url.appendingPathComponent("big"), to: zip)
        #expect(throws: Archive.ArchiveError.self) { try Archive.extract(zip, to: s.url.appendingPathComponent("out"), limit: 1_000) }
        #expect(!FileManager.default.fileExists(atPath: s.url.appendingPathComponent("out/data.bin").path))
    }
}

@MainActor
@Suite struct ThemeEngineTests {
    func engine(_ s: Scratch) -> ThemeEngine {
        let d = UserDefaults(suiteName: "notchi-tests-\(UUID().uuidString)")!
        return ThemeEngine(bus: EventBus(), builtInDir: s.url.appendingPathComponent("BuiltIn"), userDir: s.url.appendingPathComponent("User"), defaults: d)
    }

    @Test func loadsLooseFilesAndFolders() throws {
        let s = Scratch()
        _ = s.file("BuiltIn/midnight.json", String(decoding: try sampleTheme(id: "midnight").encoded(), as: UTF8.self))
        _ = s.file("BuiltIn/wallpapers/dusk.mp4")
        _ = s.file("User/mine/theme.json", String(decoding: try sampleTheme(id: "mine").encoded(), as: UTF8.self))
        _ = s.file("User/broken.json", "{ nope")
        let e = engine(s)
        e.reload()
        #expect(Set(e.themes.map(\.id)) == ["paper", "midnight", "mine"])
        #expect(e.loadErrors.count == 1)
        #expect(e.isUserTheme("mine"))
        #expect(!e.isUserTheme("midnight"))
        #expect(e.wallpaperURL(for: e.theme(id: "midnight")!) != nil)
        #expect(e.wallpaperURL(for: e.theme(id: "mine")!) == nil)   // its video isn't there
    }

    @Test func installApplyExportRemove() throws {
        let s = Scratch()
        _ = s.file("src/wallpapers/dusk.mp4")
        let pkg = s.url.appendingPathComponent("dusk.notchitheme")
        try ThemePackage.export(sampleTheme(), base: s.url.appendingPathComponent("src"), to: pkg)

        let e = engine(s)
        e.reload()
        let t = try e.install(pkg)
        #expect(e.themes.contains(t))
        #expect(e.apply(id: "dusk"))
        #expect(e.active.id == "dusk")

        let again = s.url.appendingPathComponent("again.notchitheme")
        try e.export(id: "dusk", to: again)
        #expect(try Archive.entries(of: again).contains("wallpapers/dusk.mp4"))

        try e.remove(id: "dusk")
        #expect(e.theme(id: "dusk") == nil)
        #expect(e.active.id == "paper")
        #expect(throws: ThemeEngine.EngineError.builtIn("paper")) { try e.remove(id: "paper") }
        #expect(throws: ThemeEngine.EngineError.unknown("nope")) { try e.remove(id: "nope") }
    }
}
