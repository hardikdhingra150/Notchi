import AppKit
import NotchiCore
import NotchiIcons

/// Themes in and out, backups, and "Restore stock macOS". The menu, Settings,
/// the `notchi` command and double-clicked files all come through here.
@MainActor
final class SetupManager {
    private unowned let app: AppDelegate
    init(app: AppDelegate) { self.app = app }

    // MARK: Themes

    /// Install a .notchitheme or .json. `apply` switches to it straight away (double-click, Import…).
    @discardableResult
    func installTheme(_ file: URL, apply: Bool) throws -> Theme {
        let t = try app.themes.install(file)
        if apply { app.themes.apply(t) } else { app.bus.post(.notify(message: "Installed \(t.name) 🎨")) }
        return t
    }

    // MARK: Backups

    @discardableResult
    func backup(to file: URL) throws -> SetupBackup.Manifest {
        try SetupBackup.create(to: file, appVersion: Version.string)
    }

    /// Restore a backup. The setup you had a moment ago is saved first, in Notchi's Backups folder.
    @discardableResult
    func restore(from file: URL) throws -> String {
        let m = try SetupBackup.inspect(file)   // check it before touching anything
        let safety = try? SetupBackup.automatic("before-restore", appVersion: Version.string)
        let studio = IconStudio()
        _ = studio.restoreAll()
        try SetupBackup.restore(from: file)

        app.themes.reload()
        app.energy.reloadRules()
        app.coordinator.reloadSettings()
        app.coordinator.quiet = true
        app.themes.apply(app.themes.active)     // the notch picks up the restored theme
        app.coordinator.quiet = false
        app.coordinator.syncWallpaper(animated: true)
        if app.systemHUD.isEnabled { app.systemHUD.start() } else { app.systemHUD.setEnabled(false) }
        let icons = studio.reapplyAll()

        var parts = ["theme \(app.themes.active.name)", "\(m.themeCount) installed theme\(m.themeCount == 1 ? "" : "s")", "\(icons) icon\(icons == 1 ? "" : "s")"]
        if app.wallpaper.url != nil { parts.append("wallpaper") }
        return "Restored: " + parts.joined(separator: ", ") + (safety.map { ". Your previous setup is saved in \($0.deletingLastPathComponent().path)" } ?? "")
    }

    /// Everything Notchi changed outside itself goes back: the wallpaper, the icons and the
    /// macOS volume indicator. Notchi stays installed; a backup is taken first.
    @discardableResult
    func resetToStock() -> String {
        let safety = try? SetupBackup.automatic("before-reset", appVersion: Version.string)
        app.wallpaper.turnOff(animated: true)
        let icons = IconStudio().restoreAll()
        app.systemHUD.setEnabled(false)
        return "Stock macOS is back: wallpaper off, \(icons) original icon\(icons == 1 ? "" : "s") restored, macOS volume indicator on."
            + (safety.map { " To undo: notchi restore \"\($0.path)\"" } ?? "")
    }

    // MARK: Panels (menu and Settings)

    private func alert(_ title: String, _ error: Error) {
        let a = NSAlert()
        a.messageText = title
        a.informativeText = "\(error)"
        a.runModal()
    }

    func importThemePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: ThemePackage.fileExtension), .json, .zip].compactMap { $0 }
        panel.message = "Choose a .notchitheme (or a theme's .json) to install."
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try installTheme(url, apply: true) } catch { alert("Couldn't install that theme", error) }
    }

    func exportThemePanel(id: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(id).\(ThemePackage.fileExtension)"
        panel.message = "Save this theme as a file anyone can install."
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try app.themes.export(id: id, to: url) } catch { alert("Couldn't export the theme", error) }
    }

    func backupPanel() {
        let panel = NSSavePanel()
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        panel.nameFieldStringValue = "Notchi \(f.string(from: Date())).\(SetupBackup.fileExtension)"
        panel.message = "Saves your theme, settings, installed themes, custom icons and wallpaper in one file."
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try backup(to: url)
            app.bus.post(.notify(message: "Backup saved ✅"))
        } catch { alert("Couldn't save the backup", error) }
    }

    func restorePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: SetupBackup.fileExtension), .zip].compactMap { $0 }
        panel.message = "Choose a .notchibackup file."
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        confirmRestore(url)
    }

    func confirmRestore(_ url: URL) {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = "Restore this backup?"
        a.informativeText = "Your theme, settings, installed themes, icons and wallpaper are replaced by the ones in \(url.lastPathComponent). Your current setup is saved first, so you can go back."
        a.addButton(withTitle: "Restore")
        a.addButton(withTitle: "Cancel")
        guard a.runModal() == .alertFirstButtonReturn else { return }
        do {
            try restore(from: url)
            app.bus.post(.notify(message: "Backup restored ✅"))
        } catch { alert("Couldn't restore that backup", error) }
    }

    func confirmReset() {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = "Restore stock macOS?"
        a.informativeText = "Notchi turns off its wallpaper, puts back every icon it changed and gives volume and brightness back to macOS. Your setup is saved first, so you can undo this from Restore from Backup."
        a.addButton(withTitle: "Restore Stock macOS")
        a.addButton(withTitle: "Cancel")
        guard a.runModal() == .alertFirstButtonReturn else { return }
        _ = resetToStock()
        app.bus.post(.notify(message: "Stock macOS is back"))
    }

    var backupsFolder: URL { SetupBackup.supportURL.appendingPathComponent("Backups", isDirectory: true) }
}
