import AppKit
import NotchiNotch

// Notchi is a menu-bar app: no Dock icon, no main window.
MainActor.assumeIsolated {
    // Notchi --snapshot <folder>: render every island state to PNG and exit
    let args = CommandLine.arguments
    if let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count {
        do { try IslandSnapshots.render(to: URL(fileURLWithPath: args[i + 1])); exit(0) }
        catch { FileHandle.standardError.write(Data("\(error)\n".utf8)); exit(1) }
    }
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(delegate) { app.run() }
}
