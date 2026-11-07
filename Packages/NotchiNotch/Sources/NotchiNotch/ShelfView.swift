import AppKit
import SwiftUI
import UniformTypeIdentifiers

private let ink = Color(red: 0.95, green: 0.93, blue: 0.89)
private let dim = Color(red: 0.66, green: 0.64, blue: 0.58)

/// Files held in the notch. Drag them back out anywhere, or AirDrop them all.
struct ShelfView: View {
    @Bindable var model: IslandModel

    var body: some View {
        HStack(spacing: 10) {
            if model.shelf.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "tray.and.arrow.down.fill").font(.system(size: 16, weight: .bold))
                    Text("Drop to keep it on the shelf").font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(model.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 8) {
                    // newest first; the rest are counted
                    ForEach(model.shelf.suffix(5).reversed(), id: \.self) { url in
                        FileChip(url: url, onRemove: { model.removeFromShelf(url) })
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                    if model.shelf.count > 5 {
                        Text("+\(model.shelf.count - 5)")
                            .font(.system(size: 13, weight: .bold)).foregroundStyle(dim)
                            .frame(width: 34)
                    }
                    Spacer(minLength: 0)
                }
                VStack(spacing: 6) {
                    ShelfButton(symbol: "airplayaudio", label: "AirDrop", accent: model.accent) { Shelf.airDrop(model.shelf) }
                    ShelfButton(symbol: "xmark", label: "Clear shelf", accent: model.accent) { withAnimation(model.spring) { model.shelf.removeAll() } }
                }
            }
        }
        .padding(10)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(model.dropTargeted ? model.accent : Color.white.opacity(0.16), style: StrokeStyle(lineWidth: 1.5, dash: model.shelf.isEmpty ? [5, 4] : []))
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(model.dropTargeted ? 0.08 : 0.04)))
        )
    }
}

struct FileChip: View {
    let url: URL
    let onRemove: () -> Void
    var body: some View {
        VStack(spacing: 3) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable().frame(width: 34, height: 34)
            Text(url.lastPathComponent)
                .font(.system(size: 10, weight: .medium)).foregroundStyle(ink)
                .lineLimit(1).truncationMode(.middle)
                .frame(width: 62)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onDrag { NSItemProvider(contentsOf: url) ?? NSItemProvider() }
        .contextMenu {
            Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
            Button("Remove from Shelf", action: onRemove)
        }
        .help(url.path)
        .accessibilityLabel("\(url.lastPathComponent), on the shelf. Drag to move it out.")
    }
}

struct ShelfButton: View {
    let symbol: String
    let label: String
    let accent: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 26, height: 26)
                .background(Circle().fill(accent))
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

@MainActor
enum Shelf {
    static func airDrop(_ urls: [URL]) {
        guard !urls.isEmpty, let s = NSSharingService(named: .sendViaAirDrop) else { return }
        NSApp.activate(ignoringOtherApps: true)
        s.perform(withItems: urls)
    }

    /// Load file URLs from a drop.
    static func load(_ providers: [NSItemProvider], into model: IslandModel) -> Bool {
        let files = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !files.isEmpty else { return false }
        for p in files {
            _ = p.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in model.addToShelf([url]) }
            }
        }
        return true
    }
}
