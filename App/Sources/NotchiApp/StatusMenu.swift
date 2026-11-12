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

        app.themes.reload()   // themes added or edited by hand show up without a restart
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
        sub.addItem(.separator())
        sub.addItem(withTitle: "Import Theme…", action: #selector(importTheme), keyEquivalent: "").target = self
        sub.addItem(withTitle: "Export \(app.themes.active.name)…", action: #selector(exportTheme), keyEquivalent: "").target = self
        sub.addItem(withTitle: "Open Themes Folder", action: #selector(openThemesFolder), keyEquivalent: "").target = self
        themeItem.submenu = sub
        menu.addItem(themeItem)

        let profItem = NSMenuItem(title: "Profile", action: nil, keyEquivalent: "")
        let prof = NSMenu()
        let saved = app.setup.profiles.load()
        let active = app.setup.activeProfile.map(ProfileStore.key)
        for p in saved {
            let mi = NSMenuItem(title: p.name, action: #selector(pickProfile(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = p.name
            mi.state = p.id == active ? .on : .off
            prof.addItem(mi)
        }
        if !saved.isEmpty { prof.addItem(.separator()) }
        prof.addItem(withTitle: "Save Current Setup as Profile…", action: #selector(saveProfile), keyEquivalent: "").target = self
        if !saved.isEmpty {
            let rm = NSMenuItem(title: "Remove", action: nil, keyEquivalent: "")
            let rmMenu = NSMenu()
            for p in saved {
                let mi = NSMenuItem(title: p.name, action: #selector(removeProfile(_:)), keyEquivalent: "")
                mi.target = self
                mi.representedObject = p.name
                rmMenu.addItem(mi)
            }
            rm.submenu = rmMenu
            prof.addItem(rm)
        }
        profItem.submenu = prof
        menu.addItem(profItem)

        let wpItem = NSMenuItem(title: "Live Wallpaper", action: nil, keyEquivalent: "")
        let wp = NSMenu()
        wp.addItem(withTitle: "Browse Wallpapers…", action: #selector(browseWallpapers), keyEquivalent: "w").target = self
        wp.addItem(withTitle: "Choose Your Own Video…", action: #selector(chooseWallpaper), keyEquivalent: "").target = self
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

        let hud = NSMenuItem(title: "Volume & Brightness in the Notch", action: #selector(toggleHUD), keyEquivalent: "")
        hud.target = self
        switch app.systemHUD.state {
        case .active: hud.state = .on
        case .needsPermission: hud.state = .mixed; hud.title += " (needs Accessibility)"
        case .failed: hud.state = .mixed; hud.title += " (couldn't start)"
        case .off: hud.state = .off
        }
        hud.toolTip = "Shows volume and brightness changes in the notch instead of the macOS indicator."
        menu.addItem(hud)

        menu.addItem(withTitle: "Test the Notch", action: #selector(testNotch), keyEquivalent: "t").target = self
        menu.addItem(.separator())

        let setupItem = NSMenuItem(title: "Backup", action: nil, keyEquivalent: "")
        let setup = NSMenu()
        setup.addItem(withTitle: "Back Up My Setup…", action: #selector(backUp), keyEquivalent: "").target = self
        setup.addItem(withTitle: "Restore from Backup…", action: #selector(restoreBackup), keyEquivalent: "").target = self
        setup.addItem(.separator())
        setup.addItem(withTitle: "Restore Stock macOS…", action: #selector(resetStock), keyEquivalent: "").target = self
        setupItem.submenu = setup
        menu.addItem(setupItem)

        let login = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        if app.updater.isEnabled {
            menu.addItem(withTitle: "Check for Updates…", action: #selector(checkUpdates), keyEquivalent: "").target = self
        }
        menu.addItem(withTitle: "Welcome Tour…", action: #selector(openTour), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Notchi", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    @objc private func pickTheme(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        app.themes.apply(id: id)
    }

    @objc private func importTheme() { app.setup.importThemePanel() }
    @objc private func exportTheme() { app.setup.exportThemePanel(id: app.themes.active.id) }
    @objc private func openThemesFolder() {
        let dir = app.themes.userThemesFolder
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(dir)
    }
    @objc private func backUp() { app.setup.backupPanel() }
    @objc private func restoreBackup() { app.setup.restorePanel() }
    @objc private func resetStock() { app.setup.confirmReset() }

    @objc private func browseWallpapers() { app.showWallpapers() }
    @objc private func pickProfile(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        do { try app.setup.useProfile(name) } catch {
            let a = NSAlert(); a.messageText = "Couldn't switch profile"; a.informativeText = "\(error)"; a.runModal()
        }
    }
    @objc private func saveProfile() { app.setup.saveProfilePanel() }
    @objc private func removeProfile(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        try? app.setup.profiles.remove(name)
        if app.setup.activeProfile.map(ProfileStore.key) == ProfileStore.key(name) { UserDefaults.standard.removeObject(forKey: SetupManager.profileKey) }
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

    @objc private func toggleHUD() {
        let hud = app.systemHUD
        switch hud.state {
        case .active: hud.setEnabled(false)
        case .needsPermission, .failed: hud.requestPermission()
        case .off: hud.setEnabled(true)
        }
    }

    @objc private func openSettings() { app.showSettings() }
    @objc private func openTour() { app.showOnboarding() }
    @objc private func checkUpdates() { app.updater.checkForUpdates() }

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
