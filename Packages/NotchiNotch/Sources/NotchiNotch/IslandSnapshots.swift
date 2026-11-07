import AppKit
import NotchiCore
import SwiftUI

/// Renders each island state to a PNG. Used for visual checks and snapshot tests:
///   Notchi.app/Contents/MacOS/Notchi --snapshot <folder>
@MainActor
public enum IslandSnapshots {
    public static func render(to folder: URL, accent: HexColor = HexColor("#FF6A3D")!) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let cases: [(String, (IslandModel) -> Void)] = [
            ("closed", { _ in }),
            ("compact-music", { $0.nowPlaying = .sample }),
            ("notify", { $0.activity = .notify("Build done ✅") }),
            ("progress", { $0.activity = .progress(0.42, "Exporting") }),
            ("theme", { $0.activity = .theme("Neon Rain") }),
            ("battery", { $0.activity = .battery(.init(level: 0.87, isCharging: true, isPluggedIn: true)) }),
            ("volume", { $0.activity = .volume(0.62, false) }),
            ("expanded-home", { $0.hovering = true; $0.battery = .init(level: 0.64, isCharging: false, isPluggedIn: false) }),
            ("expanded-player", { $0.hovering = true; $0.nowPlaying = .sample }),
        ]
        for (name, setup) in cases {
            let m = IslandModel()
            m.notchSize = CGSize(width: 185, height: 32)
            m.accent = Color(.sRGB, red: accent.red, green: accent.green, blue: accent.blue, opacity: 1)
            m.animate = false
            setup(m)
            let view = IslandView(model: m)
                .frame(width: 600, height: 200)
                .background(Color(red: 0.92, green: 0.9, blue: 0.83))
            let r = ImageRenderer(content: view)
            r.scale = 2
            guard let img = r.nsImage, let tiff = img.tiffRepresentation,
                  let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { continue }
            try png.write(to: folder.appendingPathComponent("\(name).png"))
        }
    }
}

extension NowPlaying {
    static let sample = NowPlaying(title: "Night Drive", artist: "Notchi Radio", album: "Ink Tide", isPlaying: true, source: .music)
}
