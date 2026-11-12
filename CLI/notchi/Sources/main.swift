import AppKit
import NotchiCore
import NotchiIcons
import NotchiWallpaper

// notchi: talk to the Notchi app from your terminal (blueprint section 12).

let version = "0.5.0"
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
  notchi theme install <file>        install a .notchitheme (or a theme's .json)
  notchi theme export <theme> [file] save a theme as a .notchitheme to share
  notchi theme remove <theme>        remove a theme you installed
  notchi theme new <id> ["Name"]     start your own theme from the active one
  notchi theme validate <file>       check a theme file without installing it
  notchi export [file]               save the active theme as a .notchitheme
  notchi profile save <name>         remember this setup (theme, wallpaper, energy, island)
  notchi profile <name>              switch to a saved profile
  notchi profile list | remove <name>
  notchi backup [file]               save your whole setup in one file
  notchi restore <file>              bring a backup back
  notchi reset                       restore stock macOS (wallpaper, icons, volume)
  notchi wallpaper browse            open the Wallpapers window
  notchi wallpaper list              wallpapers in Notchi's library
  notchi wallpaper get <id>          download one from the library and use it
  notchi wallpaper set <video>       loop your own video behind your desktop icons
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

/// Run async work from this synchronous tool and wait for it.
func wait<T: Sendable>(_ work: @escaping @Sendable () async throws -> T) throws -> T {
    nonisolated(unsafe) var result: Result<T, Error>?
    Task { do { result = .success(try await work()) } catch { result = .failure(error) } }
    while result == nil { RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05)) }
    return try result!.get()
}

/// A path the app can use: absolute, with ~ expanded.
func absolute(_ path: String) -> String {
    URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL.path
}

/// Print the app's answer, or stop with its error.
func say(_ r: IPCReply?) {
    guard let r else { fail("Notchi didn't answer.") }
    if r.ok { out("✓ \(r.message)") } else { fail(r.message) }
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
    switch args.count < 2 ? "list" : args[1] {
    case "list":
        requireApp()
        guard let r = request({ .ping(replyTo: $0) }) else { fail("Notchi didn't answer.") }
        for t in r.themes ?? [] { out("\(t == r.activeTheme ? "●" : " ") \(t)") }
    case "install", "import":
        guard args.count >= 3 else { fail("usage: notchi theme install <file.notchitheme|theme.json>") }
        requireApp()
        say(request({ .themeInstall(path: absolute(args[2]), replyTo: $0) }, timeout: 20))
    case "export":
        guard args.count >= 3 else { fail("usage: notchi theme export <theme> [file.notchitheme]") }
        requireApp()
        let file = absolute(args.count >= 4 ? args[3] : "\(args[2]).\(ThemePackage.fileExtension)")
        say(request({ .themeExport(id: args[2], path: file, replyTo: $0) }, timeout: 20))
    case "remove", "rm":
        guard args.count >= 3 else { fail("usage: notchi theme remove <theme>") }
        requireApp()
        say(request({ .themeRemove(id: args[2], replyTo: $0) }))
    case "validate":
        guard args.count >= 3 else { fail("usage: notchi theme validate <file.notchitheme|theme.json|theme folder>") }
        let url = URL(fileURLWithPath: absolute(args[2]))
        do {
            let theme: Theme
            var missing: [String] = []
            if [ThemePackage.fileExtension, "zip"].contains(url.pathExtension.lowercased()) {
                // unpack it somewhere temporary, exactly as an install would
                let tmp = try Archive.scratch("validate")
                defer { try? FileManager.default.removeItem(at: tmp) }
                theme = try ThemePackage.install(url, into: tmp)
            } else {
                let (t, base) = try ThemePackage.read(url)
                theme = t
                missing = ThemePackage.assetPaths(of: t).filter { ThemePackage.asset($0, base: base) == nil }
            }
            out("✓ \(theme.name) (\(theme.id)) by \(theme.author), version \(theme.version)")
            for w in theme.warnings() { out("! \(w)") }
            for m in missing { out("! \(m) isn't next to the theme file; the wallpaper won't change until it is.") }
        } catch { fail("\(error)") }
    case "new":
        guard args.count >= 3 else { fail("usage: notchi theme new <id> [\"Name\"]") }
        var t = Theme.paper
        if isAppRunning, let hex = request({ .ping(replyTo: $0) })?.accent, let c = HexColor(hex) { t.accent = c }
        t.id = args[2]
        t.name = args.count >= 4 ? args.dropFirst(3).joined(separator: " ") : args[2].split(separator: "-").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
        t.author = NSUserName()
        t.wallpaper = nil
        do {
            try t.validate()
            let dir = ThemeEngine.userThemesURL.appendingPathComponent(t.id, isDirectory: true)
            guard !FileManager.default.fileExists(atPath: dir.path) else { fail("There's already a theme at \(dir.path)") }
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try t.encoded().write(to: dir.appendingPathComponent(ThemePackage.manifestName))
            out("✓ Created \(dir.path)/theme.json")
            out("  Edit it, then: notchi apply \(t.id)")
            out("  For a wallpaper, put a video in that folder and add:  \"wallpaper\": { \"type\": \"video\", \"src\": \"my-video.mp4\" }")
            out("  Share it: notchi theme export \(t.id)")
        } catch { fail("\(error)") }
    default:
        fail("usage: notchi theme list | install <file> | export <theme> [file] | remove <theme> | new <id> | validate <file>")
    }

case "export":
    requireApp()
    guard let active = request({ .ping(replyTo: $0) })?.activeTheme else { fail("Notchi didn't answer.") }
    let file = absolute(args.count >= 2 ? args[1] : "\(active).\(ThemePackage.fileExtension)")
    say(request({ .themeExport(id: active, path: file, replyTo: $0) }, timeout: 20))

case "backup":
    requireApp()
    let stamp = DateFormatter()
    stamp.dateFormat = "yyyy-MM-dd"
    let file = absolute(args.count >= 2 ? args[1] : "Notchi-\(stamp.string(from: Date())).\(SetupBackup.fileExtension)")
    say(request({ .backup(path: file, replyTo: $0) }, timeout: 60))

case "restore":
    guard args.count >= 2 else { fail("usage: notchi restore <file.notchibackup>") }
    requireApp()
    say(request({ .restore(path: absolute(args[1]), replyTo: $0) }, timeout: 60))

case "reset":
    requireApp()
    if !args.contains("--yes") {
        guard isatty(0) != 0 else { fail("notchi reset turns off the wallpaper, puts back original icons and the macOS volume indicator. Add --yes to go ahead.") }
        print("Turn off the wallpaper, put back every original icon and the macOS volume indicator? A backup is saved first. [y/N] ", terminator: "")
        guard let a = readLine(), ["y", "yes"].contains(a.lowercased()) else { out("Nothing changed."); exit(0) }
    }
    say(request({ .reset(replyTo: $0) }, timeout: 30))

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
            if r.adHocSigned == true {
                check(false, "Signing", "ad hoc: macOS forgets Accessibility on every rebuild. Run ./scripts/dev-signing.sh once, rebuild, then allow Notchi again")
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
    switch args.dropFirst().first {
    case "list":
        let lib = WallpaperLibrary()
        let catalog: WallpaperLibrary.Catalog
        do { catalog = try wait { try await lib.fetchCatalog() } } catch { fail("\(error)") }
        for c in catalog.collections {
            out("\n\(c.name)\(c.note.map { "  (\($0))" } ?? "")")
            for w in catalog.wallpapers where w.collection == c.id {
                out("  \(lib.isDownloaded(w) ? "↓" : " ") \(w.id.padding(toLength: 22, withPad: " ", startingAt: 0)) \(w.name)")
            }
        }
        out("\nSet one: notchi wallpaper get <id>   (↓ = already downloaded)")
    case "get":
        guard args.count >= 3 else { fail("usage: notchi wallpaper get <id>   (see: notchi wallpaper list)") }
        requireApp()
        let lib = WallpaperLibrary()
        let file: URL
        do {
            file = try wait {
                let catalog = try await lib.fetchCatalog()
                guard let item = catalog.wallpapers.first(where: { $0.id == args[2] }) else { throw WallpaperLibrary.LibraryError.unknown(args[2]) }
                if !lib.isDownloaded(item) { out("Downloading \(item.name)…") }
                return try await lib.download(item)
            }
        } catch { fail("\(error)") }
        guard let r = request({ .wallpaper(path: file.path, replyTo: $0) }, timeout: 4) else { fail("Notchi didn't answer.") }
        if r.ok { out("✓ \(r.message)") } else { fail(r.message) }
    case "browse":
        requireApp()
        IPC.send(.open(window: "wallpapers"))
        flush()
    case "set", "off": requireApp(); fallthrough
    default: switch args.dropFirst().first {
    case "set":
        guard args.count >= 3 else { fail("usage: notchi wallpaper set <video.mp4|mov>") }
        let path = URL(fileURLWithPath: (args[2] as NSString).expandingTildeInPath).standardizedFileURL.path
        guard let r = request({ .wallpaper(path: path, replyTo: $0) }, timeout: 4) else { fail("Notchi didn't answer.") }
        if r.ok { out("✓ \(r.message)") } else { fail(r.message) }
    case "off":
        guard let r = request({ .wallpaper(path: nil, replyTo: $0) }) else { fail("Notchi didn't answer.") }
        out("✓ \(r.message)")
    default:
        fail("usage: notchi wallpaper browse | list | get <id> | set <file> | off")
    }
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
            let follows = args.firstIndex(of: "--tint").map { $0 + 1 < args.count && args[$0 + 1] == "accent" } ?? false
            try studio.set(rest[0], badge: badge, tint: tint(), followsAccent: follows)
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

case "profile", "profiles":
    requireApp()
    let sub = args.count >= 2 ? args[1] : "list"
    let rest = args.dropFirst(2).joined(separator: " ")
    switch sub {
    case "list":
        say(request({ .profile(action: "list", name: nil, replyTo: $0) }))
    case "save":
        guard !rest.isEmpty else { fail("usage: notchi profile save <name>") }
        say(request({ .profile(action: "save", name: rest, replyTo: $0) }))
    case "remove", "rm":
        guard !rest.isEmpty else { fail("usage: notchi profile remove <name>") }
        say(request({ .profile(action: "remove", name: rest, replyTo: $0) }))
    default:
        // notchi profile Work (names can have spaces)
        say(request({ .profile(action: "use", name: args.dropFirst().joined(separator: " "), replyTo: $0) }, timeout: 4))
    }

default:
    fail("unknown command \"\(args[0])\". Try: notchi help")
}
