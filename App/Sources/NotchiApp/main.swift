import AppKit
import NotchiCore
import NotchiNotch
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
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(delegate) { app.run() }
}
