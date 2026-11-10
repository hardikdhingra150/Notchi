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

    @Test func foldersThatFollowTheAccentAreRecoloured() throws {
        let follows = dir.appendingPathComponent("Projects").path
        let fixed = dir.appendingPathComponent("Fixed").path
        try FileManager.default.createDirectory(atPath: fixed, withIntermediateDirectories: true)
        try studio.set(follows, badge: .emoji("🚀"), tint: HexColor("#FF6A3D"), followsAccent: true)
        try studio.set(fixed, badge: .none, tint: HexColor("#FF6A3D"))

        #expect(studio.retint(to: HexColor("#8F7CFF")!) == 1)
        let after = Dictionary(uniqueKeysWithValues: studio.load().map { ($0.path, $0) })
        #expect(after[follows]?.tint == "#8F7CFF")
        #expect(after[follows]?.badge == "🚀")
        #expect(after[follows]?.followsAccent == true)
        #expect(after[fixed]?.tint == "#FF6A3D")
        // same colour again: nothing to do
        #expect(studio.retint(to: HexColor("#8F7CFF")!) == 0)
        #expect(studio.reapplyAll() == 2)
        _ = studio.restoreAll()
    }

    @Test func missingPathThrows() {
        #expect(throws: IconStudio.IconError.self) { try studio.set(dir.appendingPathComponent("nope").path, badge: .emoji("x"), tint: nil) }
    }

    @Test func parsesBadge() {
        #expect(IconStudio.badge(from: "🚀") == .emoji("🚀"))
    }
}
