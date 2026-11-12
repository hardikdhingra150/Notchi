import Foundation
import Testing
@testable import NotchiWallpaper

@Suite struct WallpaperLibraryTests {
    let sample = #"""
    {"schema":1,"collections":[{"id":"earth","name":"Earth from Orbit","note":"Real footage · NASA"}],
     "wallpapers":[{"id":"earth-cloud-deck","name":"Cloud Deck","collection":"earth","kind":"Footage","theme":"Midnight",
       "line":"Clouds.","credit":"NASA","video":"https://example.com/w/earth-cloud-deck.mp4","poster":"https://example.com/w/earth-cloud-deck.jpg",
       "bytes":7634611,"somethingNew":true}]}
    """#

    @Test func decodesTheCatalogAndIgnoresNewFields() throws {
        let c = try WallpaperLibrary.decode(Data(sample.utf8))
        #expect(c.collections.map(\.name) == ["Earth from Orbit"])
        #expect(c.wallpapers.first?.name == "Cloud Deck")
        #expect(c.wallpapers.first?.bytes == 7634611)
        #expect(c.wallpapers.first?.preview == nil)
    }

    @Test func refusesNewerOrBrokenCatalogs() {
        #expect(throws: WallpaperLibrary.LibraryError.newerCatalog(2)) { try WallpaperLibrary.decode(Data(sample.replacingOccurrences(of: #""schema":1"#, with: #""schema":2"#).utf8)) }
        #expect(throws: WallpaperLibrary.LibraryError.badCatalog) { try WallpaperLibrary.decode(Data("<html>".utf8)) }
    }

    @Test func filesStayInsideTheFolder() {
        let lib = WallpaperLibrary(folder: URL(fileURLWithPath: "/tmp/notchi-lib"))
        #expect(lib.localURL(for: "earth-cloud-deck").path == "/tmp/notchi-lib/earth-cloud-deck.mp4")
        #expect(lib.localURL(for: "../../etc/passwd").path == "/tmp/notchi-lib/etcpasswd.mp4")
        #expect(lib.localURL(for: "/").path == "/tmp/notchi-lib/wallpaper.mp4")
    }

    @Test func onlyDownloadsOverHTTPS() async throws {
        var item = try WallpaperLibrary.decode(Data(sample.utf8)).wallpapers[0]
        item.video = URL(string: "http://example.com/a.mp4")!
        let lib = WallpaperLibrary(folder: FileManager.default.temporaryDirectory.appendingPathComponent("notchi-lib-\(UUID().uuidString)"))
        await #expect(throws: WallpaperLibrary.LibraryError.unsafeURL("http://example.com/a.mp4")) { try await lib.download(item) }
    }
}
