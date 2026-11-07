import AppKit
import Foundation
import NotchiCore
import Testing
@testable import NotchiIcons

@MainActor
@Suite struct IconStudioTests {
    let dir: URL
    let studio: IconStudio

    init() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("notchi-icons-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("Projects"), withIntermediateDirectories: true)
        studio = IconStudio(ledgerURL: dir.appendingPathComponent("icons.json"))
    }

    @Test func rendersFolderIcon() {
        let img = IconStudio.folderIcon(badge: .emoji("🚀"), tint: HexColor("#FF6A3D"), size: 256)
        #expect(img.size == NSSize(width: 256, height: 256))
        #expect(img.pngData() != nil)
    }

    @Test func setAndRestoreRecordsLedger() throws {
        let folder = dir.appendingPathComponent("Projects").path
        try studio.set(folder, badge: .emoji("🚀"), tint: nil)
        #expect(studio.load().map(\.path) == [folder])
        #expect(studio.load().first?.badge == "🚀")
        // setting again replaces, doesn't duplicate
        try studio.set(folder, badge: .emoji("🎨"), tint: HexColor("#4F9A3A"))
        #expect(studio.load().count == 1)
        #expect(studio.load().first?.tint == "#4F9A3A")
        #expect(studio.restoreAll() == 1)
        #expect(studio.load().isEmpty)
    }

    @Test func missingPathThrows() {
        #expect(throws: IconStudio.IconError.self) { try studio.set(dir.appendingPathComponent("nope").path, badge: .emoji("x"), tint: nil) }
    }

    @Test func parsesBadge() {
        #expect(IconStudio.badge(from: "🚀") == .emoji("🚀"))
    }
}
