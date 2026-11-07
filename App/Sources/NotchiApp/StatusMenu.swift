import AppKit
import NotchiCore
import NotchiIcons
import ServiceManagement

/// The menu-bar icon and its menu.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private unowned let app: AppDelegate

    init(app: AppDelegate) {
        self.app = app
        super.init()
        item.button?.image = Self.icon()
        item.button?.toolTip = "Notchi"
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    /// Rebuild every time it opens, so theme checkmarks and login state are current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let title = NSMenuItem(title: "Notchi \(Version.string)", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())

        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for t in app.themes.themes {
            let mi = NSMenuItem(title: t.name, action: #selector(pickTheme(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = t.id
            mi.state = t.id == app.themes.active.id ? .on : .off
            mi.image = Self.swatch(t.accent)
            sub.addItem(mi)
        }
        themeItem.submenu = sub
        menu.addItem(themeItem)

        let wpItem = NSMenuItem(title: "Live Wallpaper", action: nil, keyEquivalent: "")
        let wp = NSMenu()
        wp.addItem(withTitle: "Choose Video…", action: #selector(chooseWallpaper), keyEquivalent: "").target = self
        let off = NSMenuItem(title: "Turn Off", action: #selector(wallpaperOff), keyEquivalent: "")
        off.target = self
        off.isEnabled = app.wallpaper.url != nil
        wp.addItem(off)
        if let u = app.wallpaper.url {
            wp.addItem(.separator())
            let cur = NSMenuItem(title: u.lastPathComponent, action: nil, keyEquivalent: "")
            cur.isEnabled = false
            wp.addItem(cur)
        }
        wpItem.submenu = wp
        menu.addItem(wpItem)

        let changed = IconStudio().load().count
        let restore = NSMenuItem(title: changed > 0 ? "Restore \(changed) Original Icon\(changed == 1 ? "" : "s")" : "Restore Original Icons", action: #selector(restoreIcons), keyEquivalent: "")
        restore.target = self
        restore.isEnabled = changed > 0
        menu.addItem(restore)

        menu.addItem(withTitle: "Test the Notch", action: #selector(testNotch), keyEquivalent: "t").target = self
        menu.addItem(.separator())

        let login = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Notchi", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    @objc private func pickTheme(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        app.themes.apply(id: id)
    }

    @objc private func chooseWallpaper() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.message = "Choose a video for your desktop. It loops silently and pauses when it's covered."
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try app.wallpaper.set(url) } catch {
            let a = NSAlert(); a.messageText = "Couldn't use that video"; a.informativeText = "\(error)"; a.runModal()
        }
    }

    @objc private func wallpaperOff() { app.wallpaper.turnOff() }

    @objc private func restoreIcons() {
        let n = IconStudio().restoreAll()
        app.bus.post(.notify(message: "Restored \(n) original icon\(n == 1 ? "" : "s")"))
    }

    @objc private func testNotch() {
        app.bus.post(.notify(message: "Hello from Notchi 👋"))
    }

    @objc private func openSettings() { app.showSettings() }

    @objc private func toggleLogin() {
        LoginItem.toggle()
    }

    /// A small notch-screen glyph, drawn as a template image so it follows the menu bar colour.
    static func icon() -> NSImage {
        let img = NSImage(size: NSSize(width: 20, height: 15), flipped: true) { r in
            let body = NSBezierPath(roundedRect: r.insetBy(dx: 1.2, dy: 1.2), xRadius: 3.5, yRadius: 3.5)
            body.lineWidth = 1.8
            NSColor.black.setStroke()
            body.stroke()
            let notch = NSBezierPath(roundedRect: NSRect(x: 6.5, y: 0.5, width: 7, height: 4.2), xRadius: 1.6, yRadius: 1.6)
            NSColor.black.setFill()
            notch.fill()
            return true
        }
        img.isTemplate = true
        return img
    }

    static func swatch(_ c: HexColor) -> NSImage {
        NSImage(size: NSSize(width: 12, height: 12), flipped: false) { r in
            NSColor(c).setFill()
            NSBezierPath(ovalIn: r.insetBy(dx: 1, dy: 1)).fill()
            return true
        }
    }
}

@MainActor
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func toggle() {
        do {
            if isEnabled { try SMAppService.mainApp.unregister() } else { try SMAppService.mainApp.register() }
        } catch {
            let a = NSAlert()
            a.messageText = "Couldn't change Open at Login"
            a.informativeText = "\(error.localizedDescription)\n\nThis works when Notchi runs as Notchi.app (scripts/bundle.sh), not from swift run."
            a.runModal()
        }
    }
}

enum Version {
    static var string: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev" }
}

extension NSColor {
    convenience init(_ c: HexColor) {
        self.init(srgbRed: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
    }
}
