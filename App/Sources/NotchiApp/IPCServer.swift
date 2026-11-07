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

    private func handle(_ cmd: IPCCommand) {
        switch cmd {
        case .notify(let message):
            app.bus.post(.notify(message: String(message.prefix(80))))
        case .progress(let value, let label):
            app.bus.post(.progress(value: value, label: String(label.prefix(40))))
        case .apply(let id, let token):
            let ok = app.themes.apply(id: id)
            if let token {
                IPC.reply(IPCReply(ok: ok, message: ok ? "Applied \(app.themes.active.name)" : "No theme named \"\(id)\"",
                                   themes: app.themes.themes.map(\.id), activeTheme: app.themes.active.id), to: token)
            }
        case .ping(let token):
            let np = app.nowPlaying.current.map { "\($0.title) · \($0.artist) (\($0.source.rawValue)\($0.isPlaying ? "" : ", paused"))" }
            IPC.reply(IPCReply(
                ok: true, message: "pong", themes: app.themes.themes.map(\.id), activeTheme: app.themes.active.id,
                version: Version.string, island: app.island.map { "\($0.model.mode)" }, nowPlaying: np,
                hardwareNotch: app.island?.model.isHardwareNotch), to: token)
        }
    }
}
