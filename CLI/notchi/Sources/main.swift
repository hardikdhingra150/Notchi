import AppKit
import NotchiCore
import NotchiIcons

// notchi: talk to the Notchi app from your terminal (blueprint section 12).

let version = "0.1.0"
let args = Array(CommandLine.arguments.dropFirst())

func out(_ s: String) { print(s) }
func fail(_ s: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data("notchi: \(s)\n".utf8))
    exit(code)
}

let help = """
notchi \(version), the command line for Notchi

Usage:
  notchi notify "<message>"          show a message in the notch
  notchi progress <0-100> "<label>"   show progress in the notch (100 hides it)
  notchi apply <theme>               apply a theme
  notchi theme list                  list installed themes
  notchi wallpaper set <video>       loop a video behind your desktop icons
  notchi wallpaper off               go back to your normal wallpaper
  notchi icon set <path> [🚀|img.png] [--tint #hex|accent]
                                     give a folder or file a new icon
  notchi icon restore <path>|--all   put the original icons back
  notchi icon list                   icons Notchi has changed
  notchi status                      what the notch is showing right now
  notchi doctor                      check that everything is set up
  notchi --version

Examples:
  npm run build && notchi notify "Build done ✅" || notchi notify "Build failed ❌"
  notchi progress 42 "Exporting"

Coming in later versions: profile, export.
"""

var isAppRunning: Bool {
    !NSRunningApplication.runningApplications(withBundleIdentifier: IPC.bundleID).isEmpty
}

/// Send a command that expects an answer and wait briefly for it.
@MainActor func request(_ make: (String) -> IPCCommand, timeout: TimeInterval = 1.5) -> IPCReply? {
    let token = UUID().uuidString
    nonisolated(unsafe) var reply: IPCReply?
    let obs = DistributedNotificationCenter.default().addObserver(forName: IPC.replyName, object: token, queue: nil) { n in
        reply = IPC.decode(IPCReply.self, from: n.userInfo)
    }
    defer { DistributedNotificationCenter.default().removeObserver(obs) }
    IPC.send(make(token))
    let end = Date().addingTimeInterval(timeout)
    while reply == nil && Date() < end {
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
    }
    return reply
}

@MainActor func requireApp() {
    guard isAppRunning else { fail("Notchi isn't running. Open Notchi.app first.", code: 2) }
}

/// Distributed notifications are delivered asynchronously; give the run loop a moment to flush.
@MainActor func flush() { RunLoop.current.run(until: Date().addingTimeInterval(0.15)) }

switch args.first {
case nil, "help", "-h", "--help":
    out(help)

case "--version", "-v", "version":
    out("notchi \(version)")

case "notify":
    let msg = args.dropFirst().joined(separator: " ")
    guard !msg.isEmpty else { fail("usage: notchi notify \"<message>\"") }
    requireApp()
    IPC.send(.notify(message: msg))
    flush()

case "progress":
    guard args.count >= 2, let n = Double(args[1].replacingOccurrences(of: "%", with: "")) else {
        fail("usage: notchi progress <0-100> \"<label>\"")
    }
    requireApp()
    let label = args.dropFirst(2).joined(separator: " ")
    IPC.send(.progress(value: min(max(n, 0), 100) / 100, label: label.isEmpty ? "Working" : label))
    flush()

case "apply":
    guard args.count >= 2 else { fail("usage: notchi apply <theme>   (see: notchi theme list)") }
    requireApp()
    guard let r = request({ .apply(theme: args[1], replyTo: $0) }) else { fail("Notchi didn't answer.") }
    if r.ok { out("✓ \(r.message)") } else { fail("\(r.message). Installed: \((r.themes ?? []).joined(separator: ", "))") }

case "theme", "themes":
    guard args.count < 2 || args[1] == "list" else { fail("usage: notchi theme list") }
    requireApp()
    guard let r = request({ .ping(replyTo: $0) }) else { fail("Notchi didn't answer.") }
    for t in r.themes ?? [] { out("\(t == r.activeTheme ? "●" : " ") \(t)") }

case "status":
    requireApp()
    guard let r = request({ .ping(replyTo: $0) }) else { fail("Notchi didn't answer.") }
    out("Island:      \(r.island ?? "?")")
    out("Theme:       \(r.activeTheme ?? "?")")
    out("Now playing: \(r.nowPlaying ?? "nothing")")
    out("Wallpaper:   \(r.wallpaper ?? "macOS default")")
    out("Volume HUD:  \(r.systemHUD.map { "in the notch: \($0)" } ?? "?")")

case "doctor":
    var problems = 0
    func check(_ ok: Bool, _ label: String, _ detail: String) {
        out("\(ok ? "✓" : "✗") \(label.padding(toLength: 18, withPad: " ", startingAt: 0)) \(detail)")
        if !ok { problems += 1 }
    }
    let running = isAppRunning
    check(running, "Notchi app", running ? "running" : "not running (open Notchi.app)")
    if running {
        let r = request({ .ping(replyTo: $0) })
        check(r != nil, "Connection", r != nil ? "app answered (v\(r?.version ?? "?"))" : "no answer")
        if let r {
            check(true, "Themes", "\(r.themes?.count ?? 0) installed, active: \(r.activeTheme ?? "?")")
            check(true, "Island", r.hardwareNotch == true ? "on the hardware notch" : "virtual island (no notch on this screen)")
            if let hud = r.systemHUD {
                check(hud != "needs Accessibility access" && hud != "couldn't start", "Volume HUD",
                      hud == "needs Accessibility access" ? "macOS indicator still shows; allow Notchi in System Settings > Privacy & Security > Accessibility"
                      : hud == "on" ? "volume and brightness show in the notch" : hud)
            }
        }
    }
    let info = ProcessInfo.processInfo
    check(true, "macOS", info.operatingSystemVersionString)
    check(true, "Low Power Mode", info.isLowPowerModeEnabled ? "on (animations paused)" : "off")
    check(true, "Reduce Motion", NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? "on (calm animations)" : "off")
    // apps that also draw over the notch or manage the menu bar (matched by exact name)
    let others: Set<String> = ["notchnook", "alcove", "boring.notch", "boringnotch", "notchly", "notchable", "bartender", "bartender 5", "ice", "dynamiclake", "mediamate"]
    let found = NSWorkspace.shared.runningApplications.compactMap(\.localizedName).filter { others.contains($0.lowercased()) }
    check(found.isEmpty, "Conflicts", found.isEmpty ? "none" : "\(found.joined(separator: ", ")) may overlap the notch or menu bar")
    out(problems == 0 ? "\nAll good." : "\n\(problems) thing\(problems == 1 ? "" : "s") to look at.")
    exit(problems == 0 ? 0 : 1)

case "wallpaper":
    requireApp()
    switch args.dropFirst().first {
    case "set":
        guard args.count >= 3 else { fail("usage: notchi wallpaper set <video.mp4|mov>") }
        let path = URL(fileURLWithPath: (args[2] as NSString).expandingTildeInPath).standardizedFileURL.path
        guard let r = request({ .wallpaper(path: path, replyTo: $0) }, timeout: 4) else { fail("Notchi didn't answer.") }
        if r.ok { out("✓ \(r.message)") } else { fail(r.message) }
    case "off":
        guard let r = request({ .wallpaper(path: nil, replyTo: $0) }) else { fail("Notchi didn't answer.") }
        out("✓ \(r.message)")
    default:
        fail("usage: notchi wallpaper set <file>  |  notchi wallpaper off")
    }

case "icon":
    let studio = IconStudio()
    /// --tint #RRGGBB, or --tint accent for the active theme's colour
    func tint() -> HexColor? {
        guard let i = args.firstIndex(of: "--tint"), i + 1 < args.count else { return nil }
        if args[i + 1] == "accent" {
            guard isAppRunning, let hex = request({ .ping(replyTo: $0) })?.accent else { fail("--tint accent needs Notchi running") }
            return HexColor(hex)
        }
        guard let c = HexColor(args[i + 1]) else { fail("--tint wants a colour like #FF6A3D, or accent") }
        return c
    }
    // positional args, minus --tint and its value
    var rest = Array(args.dropFirst(2))
    if let i = rest.firstIndex(of: "--tint") { rest.removeSubrange(i..<min(i + 2, rest.count)) }
    rest.removeAll { $0 == "--all" }
    switch args.dropFirst().first {
    case "set":
        guard rest.count >= 1 else { fail("usage: notchi icon set <path> [emoji|image.png] [--tint #hex|accent]") }
        let badge = rest.count >= 2 ? IconStudio.badge(from: rest[1]) : .none
        do {
            try studio.set(rest[0], badge: badge, tint: tint())
            out("✓ New icon on \((rest[0] as NSString).lastPathComponent). Undo: notchi icon restore \(rest[0])")
        } catch { fail("\(error)") }
    case "restore":
        if args.contains("--all") {
            out("✓ Restored \(studio.restoreAll()) original icon(s)")
        } else {
            guard let path = rest.first else { fail("usage: notchi icon restore <path> | --all") }
            out(studio.restore(path) ? "✓ Original icon is back" : "Nothing to restore at \(path)")
        }
    case "list":
        let all = studio.load()
        if all.isEmpty { out("No custom icons yet. Try: notchi icon set ~/Projects 🚀") }
        for c in all { out("\(c.badge.isEmpty ? "·" : c.badge)  \(c.path)\(c.tint.map { "  (tint \($0))" } ?? "")") }
    case "preview":
        guard rest.count >= 2 else { fail("usage: notchi icon preview <emoji|image.png> <out.png> [--tint …]") }
        let img = IconStudio.folderIcon(badge: IconStudio.badge(from: rest[0]), tint: tint())
        let outURL = URL(fileURLWithPath: (rest[1] as NSString).expandingTildeInPath)
        do { try img.pngData()?.write(to: outURL); out("✓ Wrote \(outURL.path)") } catch { fail("\(error)") }
    default:
        fail("usage: notchi icon set|restore|list|preview (see notchi help)")
    }

case "profile", "export":
    fail("`\(args[0])` is coming in a later version. Follow along: https://github.com/hardikdhingra150/Notchi")

default:
    fail("unknown command \"\(args[0])\". Try: notchi help")
}
