import AppKit
import NotchiCore
import NotchiWallpaper
import SwiftUI

/// The Wallpapers window: Notchi's library, one click to download and use a wallpaper.
@MainActor
@Observable
final class WallpaperBrowserModel {
    enum Load: Equatable { case loading, ready, failed(String) }
    var load: Load = .loading
    var catalog: WallpaperLibrary.Catalog?
    /// wallpaper id → download progress 0...1
    var downloading: [String: Double] = [:]
    var error: String?
    var used = 0
    /// Bumped after a download or delete so the "downloaded" marks refresh.
    var revision = 0

    let library = WallpaperLibrary()
    @ObservationIgnored private unowned let app: AppDelegate

    init(app: AppDelegate) { self.app = app }

    var currentPath: String? { app.wallpaper.url?.standardizedFileURL.path }

    func refresh() {
        load = .loading
        Task {
            do {
                catalog = try await library.fetchCatalog()
                load = .ready
            } catch {
                load = .failed("\(error)")
            }
            used = library.usedBytes()
        }
    }

    func items(in c: WallpaperLibrary.Collection) -> [WallpaperLibrary.Item] {
        catalog?.wallpapers.filter { $0.collection == c.id } ?? []
    }

    func isCurrent(_ item: WallpaperLibrary.Item) -> Bool {
        currentPath == library.localURL(for: item.id).standardizedFileURL.path
    }

    func isDownloaded(_ item: WallpaperLibrary.Item) -> Bool {
        _ = revision
        return library.isDownloaded(item)
    }

    func use(_ item: WallpaperLibrary.Item) {
        guard downloading[item.id] == nil else { return }
        error = nil
        downloading[item.id] = library.isDownloaded(item) ? 1 : 0
        let id = item.id
        Task {
            do {
                let file = try await library.download(item) { p in
                    Task { @MainActor in if self.downloading[id] != nil { self.downloading[id] = p } }
                }
                try app.wallpaper.set(file, source: .user, animated: true)
                app.bus.post(.notify(message: "Wallpaper: \(item.name)"))
            } catch {
                self.error = "\(item.name): \(error)"
            }
            downloading[id] = nil
            used = library.usedBytes()
            revision += 1
        }
    }

    func remove(_ item: WallpaperLibrary.Item) {
        if isCurrent(item) { app.wallpaper.turnOff(animated: true) }
        library.remove(item)
        used = library.usedBytes()
        revision += 1
    }

    func turnOff() {
        app.wallpaper.turnOff(animated: true)
        revision += 1
    }

    func showFolder() {
        try? FileManager.default.createDirectory(at: library.folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(library.folder)
    }
}

@MainActor
final class WallpaperBrowserController {
    private let window: NSWindow
    private let model: WallpaperBrowserModel

    init(app: AppDelegate) {
        model = WallpaperBrowserModel(app: app)
        window = NSWindow(contentViewController: NSHostingController(rootView: WallpaperBrowserView(model: model)))
        window.title = "Wallpapers"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 860, height: 640))
        window.contentMinSize = NSSize(width: 560, height: 420)
        window.isReleasedWhenClosed = false
        window.center()
    }

    func show() {
        if model.catalog == nil { model.refresh() }
        model.revision += 1
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

struct WallpaperBrowserView: View {
    @Bindable var model: WallpaperBrowserModel

    var body: some View {
        VStack(spacing: 0) {
            switch model.load {
            case .loading:
                ProgressView("Loading the wallpaper library…").frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let why):
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark").font(.system(size: 34)).foregroundStyle(.secondary)
                    Text(why).multilineTextAlignment(.center).foregroundStyle(.secondary).frame(maxWidth: 420)
                    Button("Try Again") { model.refresh() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .ready:
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 26) {
                        ForEach(model.catalog?.collections ?? []) { c in
                            VStack(alignment: .leading, spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(c.name).font(.system(size: 22, weight: .bold, design: .serif))
                                    if let t = c.tagline { Text(t).font(.callout).foregroundStyle(.secondary) }
                                }
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230, maximum: 320), spacing: 14)], spacing: 14) {
                                    ForEach(model.items(in: c)) { WallpaperCard(item: $0, model: model) }
                                }
                            }
                        }
                    }
                    .padding(22)
                }
                .defaultScrollAnchor(.top)
            }
            Divider()
            HStack(spacing: 12) {
                if let e = model.error {
                    Label(e, systemImage: "exclamationmark.triangle").foregroundStyle(.orange).lineLimit(2)
                } else {
                    Text("Downloaded wallpapers use \(ByteCountFormatter.string(fromByteCount: Int64(model.used), countStyle: .file)).")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Show in Finder") { model.showFolder() }
                Button("Turn Off Wallpaper") { model.turnOff() }.disabled(model.currentPath == nil)
            }
            .font(.callout)
            .padding(.horizontal, 18).padding(.vertical, 10)
        }
        .frame(minWidth: 560, minHeight: 420)
    }
}

struct WallpaperCard: View {
    let item: WallpaperLibrary.Item
    @Bindable var model: WallpaperBrowserModel

    var body: some View {
        let current = model.isCurrent(item)
        let progress = model.downloading[item.id]
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: item.poster) { phase in
                    if let img = phase.image { img.resizable().aspectRatio(16 / 9, contentMode: .fill) }
                    else { Rectangle().fill(.quaternary) }
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(current ? Color.accentColor : .clear, lineWidth: 3))
                if current {
                    Label("In use", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold)).padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule()).padding(8)
                }
            }
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.headline)
                    Text(item.credit ?? item.kind ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                if let p = progress {
                    ProgressView(value: p).frame(width: 70)
                } else if current {
                    EmptyView()
                } else {
                    Button(model.isDownloaded(item) ? "Use" : "Get") { model.use(item) }
                        .help(model.isDownloaded(item) ? "Set as your wallpaper" : "Download\(item.bytes.map { " (\(ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file)))" } ?? "") and set as your wallpaper")
                }
            }
        }
        .contextMenu {
            Button("Use as Wallpaper") { model.use(item) }
            if model.isDownloaded(item) { Button("Delete Download", role: .destructive) { model.remove(item) } }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name)\(current ? ", in use" : "")")
    }
}
