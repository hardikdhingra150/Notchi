import Foundation
import NotchiCore

/// Listens for commands from the `notchi` CLI (local distributed notifications only).
@MainActor
final class IPCServer {
    private unowned let app: AppDelegate
    private var observer: NSObjectProtocol?

    init(app: AppDelegate) { self.app = app }

    func start() {
        observer = DistributedNotificationCenter.default().addObserver(forName: IPC.commandName, object: nil, queue: .main) { [weak self] n in
            let cmd = IPC.decode(IPCCommand.self, from: n.userInfo)
            MainActor.assumeIsolated { if let cmd { self?.handle(cmd) } }
        }
    }

    /// Run something that can fail and send back its message or its error.
    private func answer(_ token: String, _ work: () throws -> String) {
        do {
            IPC.reply(IPCReply(ok: true, message: try work(), themes: app.themes.themes.map(\.id), activeTheme: app.themes.active.id), to: token)
        } catch {
            IPC.reply(IPCReply(ok: false, message: "\(error)", themes: app.themes.themes.map(\.id), activeTheme: app.themes.active.id), to: token)
        }
    }

    private func handle(_ cmd: IPCCommand) {
        switch cmd {
        case .notify(let message):
            app.bus.post(.notify(message: String(message.prefix(80))))
        case .progress(let value, let label):
            app.bus.post(.progress(value: value, label: String(label.prefix(40))))
        case .apply(let id, let token):
            if app.themes.theme(id: id) == nil { app.themes.reload() }   // maybe it was just added by hand
            let ok = app.themes.apply(id: id)
            if let token {
                IPC.reply(IPCReply(ok: ok, message: ok ? "Applied \(app.themes.active.name)" : "No theme named \"\(id)\"",
                                   themes: app.themes.themes.map(\.id), activeTheme: app.themes.active.id), to: token)
            }
        case .themeInstall(let path, let token):
            answer(token) {
                let t = try app.setup.installTheme(URL(fileURLWithPath: path), apply: false)
                return "Installed \(t.name). Apply it: notchi apply \(t.id)"
            }
        case .themeExport(let id, let path, let token):
            answer(token) {
                try app.themes.export(id: id == "." ? app.themes.active.id : id, to: URL(fileURLWithPath: path))
                return "Exported to \(path)"
            }
        case .themeRemove(let id, let token):
            answer(token) {
                try app.themes.remove(id: id)
                return "Removed \(id)"
            }
        case .backup(let path, let token):
            answer(token) {
                let m = try app.setup.backup(to: URL(fileURLWithPath: path))
                return "Backup saved to \(path) (\(m.themeCount) installed theme\(m.themeCount == 1 ? "" : "s"), \(m.iconCount) icon\(m.iconCount == 1 ? "" : "s")\(m.wallpaperFile == nil ? "" : ", wallpaper video"))"
            }
        case .restore(let path, let token):
            answer(token) { try app.setup.restore(from: URL(fileURLWithPath: path)) }
        case .reset(let token):
            answer(token) { app.setup.resetToStock() }
        case .ping(let token):
            let np = app.nowPlaying.current.map { "\($0.title) · \($0.artist) (\($0.appName)\($0.isPlaying ? "" : ", paused"))" }
            IPC.reply(IPCReply(
                ok: true, message: "pong", themes: app.themes.themes.map(\.id), activeTheme: app.themes.active.id,
                version: Version.string, island: app.island.map { $0.model.mode == .expanded ? "expanded (\($0.model.currentPage))" : "\($0.model.mode)" }, nowPlaying: np,
                hardwareNotch: app.island?.model.isHardwareNotch,
                wallpaper: app.wallpaper.url.map { "\($0.path) (\(app.wallpaper.pauseReason.map { "paused: \($0)" } ?? "playing"))" },
                accent: app.themes.active.accent.description, systemHUD: app.systemHUD.state.rawValue, adHocSigned: SystemHUD.isAdHocSigned), to: token)
        case .wallpaper(let path, let token):
            guard let path else {
                app.wallpaper.turnOff()
                return IPC.reply(IPCReply(ok: true, message: "Video wallpaper off"), to: token)
            }
            do {
                try app.wallpaper.set(URL(fileURLWithPath: path))
                IPC.reply(IPCReply(ok: true, message: "Wallpaper set to \((path as NSString).lastPathComponent)"), to: token)
            } catch {
                IPC.reply(IPCReply(ok: false, message: "\(error)"), to: token)
            }
        }
    }
}
