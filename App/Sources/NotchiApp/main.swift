import AppKit
import NotchiCore
import NotchiNotch
import NotchiSidebar
import SwiftUI

// Notchi is a menu-bar app: no Dock icon, no main window.
MainActor.assumeIsolated {
    // Notchi --snapshot <folder>: render every island state to PNG and exit
    let args = CommandLine.arguments
    if let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count {
        do { try IslandSnapshots.render(to: URL(fileURLWithPath: args[i + 1])); exit(0) }
        catch { FileHandle.standardError.write(Data("\(error)\n".utf8)); exit(1) }
    }
    if let i = args.firstIndex(of: "--snapshot-onboarding"), i + 1 < args.count {
        let dir = URL(fileURLWithPath: args[i + 1])
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let themes = ThemeEngine(bus: EventBus())
        themes.reload()
        for step in 0..<4 {
            let m = OnboardingModel()
            m.step = step
            let r = ImageRenderer(content: OnboardingView(model: m, themes: themes, cliPath: "/Applications/Notchi.app/Contents/Helpers/notchi").background(Color(nsColor: .windowBackgroundColor)))
            r.scale = 1
            if let png = r.nsImage.flatMap({ $0.tiffRepresentation }).flatMap({ NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:]) }) {
                try? png.write(to: dir.appendingPathComponent("onboarding-\(step).png"))
            }
        }
        exit(0)
    }
    if let i = args.firstIndex(of: "--snapshot-sidebar"), i + 1 < args.count {
        let dir = URL(fileURLWithPath: args[i + 1])
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for dark in [true, false] {
            let m = SidebarModel(notesURL: dir.appendingPathComponent("notes-sample.txt"))
            m.isSnapshot = true
            m.dark = dark
            m.accent = dark ? Color(red: 0.56, green: 0.49, blue: 1) : Color(red: 1, green: 0.42, blue: 0.24)
            m.widgets = SidebarWidget.allCases
            m.nowPlaying = NowPlaying(title: "Night Drive", artist: "Notchi Radio", album: "", isPlaying: true, source: .music)
            m.battery = BatteryState(level: 0.82, isCharging: false, isPluggedIn: false)
            m.stats = SystemStats(cpu: 0.23, memoryUsed: 11_200_000_000, memoryTotal: 16_000_000_000, diskFree: 182_000_000_000,
                                  diskTotal: 494_000_000_000, downloadRate: 1_840_000, uploadRate: 96_000)
            m.notes = "Ship beta 6 ✨"
            let r = ImageRenderer(content: SidebarView(model: m).frame(width: SidebarController.width, height: 1060).padding(20)
                .background(dark ? Color(red: 0.1, green: 0.1, blue: 0.16) : Color(red: 0.92, green: 0.9, blue: 0.84)))
            r.scale = 2
            if let png = r.nsImage.flatMap({ $0.tiffRepresentation }).flatMap({ NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:]) }) {
                try? png.write(to: dir.appendingPathComponent("sidebar-\(dark ? "dark" : "light").png"))
            }
        }
        exit(0)
    }
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(delegate) { app.run() }
}
