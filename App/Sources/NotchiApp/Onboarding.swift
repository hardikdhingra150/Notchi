import AppKit
import NotchiCore
import SwiftUI

@MainActor
@Observable
final class OnboardingModel {
    var step = 0
    var copied = false
    let pages = 4
    var onFinish: () -> Void = {}
}

/// First launch: the notch wakes up, you pick a theme, and learn the three gestures that matter.
@MainActor
final class OnboardingWindowController {
    static let doneKey = "onboardingDone"
    static var isDone: Bool { UserDefaults.standard.bool(forKey: doneKey) }

    private let window: NSWindow
    private let model = OnboardingModel()

    init(app: AppDelegate) {
        let view = OnboardingView(model: model, themes: app.themes, cliPath: Self.cliPath)
        window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 620, height: 520))
        window.center()
        model.onFinish = { [weak self] in
            UserDefaults.standard.set(true, forKey: Self.doneKey)
            self?.window.close()
        }
    }

    static var cliPath: String {
        Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/notchi").path
    }

    func show(bus: EventBus) {
        model.step = 0
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        // the notch "wakes up" while the tour opens
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            bus.post(.notify(message: "Hi, I'm Notchi 👋"))
        }
    }
}

struct OnboardingView: View {
    @Bindable var model: OnboardingModel
    let themes: ThemeEngine
    let cliPath: String

    private var accent: Color { Color(nsColor: NSColor(themes.active.accent)) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch model.step {
                case 0: welcome
                case 1: themePicker
                case 2: gestures
                default: terminal
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 44)
            .padding(.top, 40)
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: model.step)

            HStack {
                HStack(spacing: 7) {
                    ForEach(0..<model.pages, id: \.self) { i in
                        Capsule().fill(i == model.step ? accent : Color.secondary.opacity(0.3))
                            .frame(width: i == model.step ? 22 : 7, height: 7)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.step)
                Spacer()
                if model.step > 0 {
                    Button("Back") { model.step -= 1 }.controlSize(.large)
                }
                Button(model.step == model.pages - 1 ? "Start using Notchi" : "Continue") {
                    if model.step == model.pages - 1 { model.onFinish() } else { model.step += 1 }
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .tint(accent)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 22)
        }
        .frame(width: 620, height: 520)
    }

    // MARK: Pages

    private var welcome: some View {
        VStack(spacing: 18) {
            NotchArt(accent: accent).frame(height: 120)
            Text("Your notch just woke up")
                .font(.system(size: 34, weight: .bold, design: .serif))
            Text("Notchi themes your whole Mac: the notch, wallpaper, icons and more, all following one theme. It's free forever, and nothing you do leaves this Mac.")
                .font(.system(size: 15)).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 440)
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }

    private var themePicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick a starting theme").font(.system(size: 28, weight: .bold, design: .serif))
            Text("It applies right away. Change it any time from the menu bar.").foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                ForEach(themes.themes) { t in
                    let on = t.id == themes.active.id
                    let c = Color(nsColor: NSColor(t.accent))
                    Button { themes.apply(t) } label: {
                        HStack(spacing: 10) {
                            Circle().fill(c).frame(width: 26, height: 26)
                                .overlay(Circle().stroke(Color.primary.opacity(0.25), lineWidth: 1))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.name).font(.system(size: 14, weight: .semibold))
                                Text(t.appearance.rawValue.capitalized).font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if on { Image(systemName: "checkmark.circle.fill").foregroundStyle(c) }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(on ? 0.08 : 0.04)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(on ? c : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(t.name) theme\(on ? ", selected" : "")")
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }

    private var gestures: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Three things to try").font(.system(size: 28, weight: .bold, design: .serif))
            Tip(symbol: "cursorarrow.motionlines", accent: accent, title: "Hover the notch",
                text: "It opens with the time, battery, and what's playing in Music or Spotify, with controls.")
            Tip(symbol: "tray.and.arrow.down.fill", accent: accent, title: "Drop files on it",
                text: "Keep files on the shelf, then drag them out anywhere or AirDrop them all.")
            Tip(symbol: "lock.shield", accent: accent, title: "Permissions only when needed",
                text: "Album art and music controls ask for Automation access the first time you use them. Nothing else is needed.")
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }

    private var terminal: some View {
        let link = "sudo ln -sf '\(cliPath)' /usr/local/bin/notchi"
        return VStack(alignment: .leading, spacing: 16) {
            Text("For terminal people").font(.system(size: 28, weight: .bold, design: .serif))
            Text("Add the notchi command to show build results and progress right in the notch.").foregroundStyle(.secondary)
            HStack {
                Text(link).font(.system(size: 12, design: .monospaced)).lineLimit(2).textSelection(.enabled)
                Spacer()
                Button(model.copied ? "Copied" : "Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(link, forType: .string)
                    model.copied = true
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.82)))
            .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 6) {
                Text("Then try:").font(.system(size: 13, weight: .semibold))
                Text("notchi notify \"Build done ✅\"\nnotchi icon set ~/Projects 🚀 --tint accent\nnotchi doctor")
                    .font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }
}

struct Tip: View {
    let symbol: String
    let accent: Color
    let title: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol).font(.system(size: 18, weight: .semibold)).foregroundStyle(.black)
                .frame(width: 40, height: 40).background(RoundedRectangle(cornerRadius: 11).fill(accent))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(text).font(.system(size: 13)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A little MacBook top edge whose notch glows in the theme colour.
struct NotchArt: View {
    let accent: Color
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 18).fill(Color.black).frame(width: 300, height: 110)
            RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.93)).frame(width: 282, height: 92).padding(.top, 9)
            UnevenRoundedRectangle(bottomLeadingRadius: 9, bottomTrailingRadius: 9).fill(Color.black)
                .frame(width: 72, height: 16).padding(.top, 9)
                .shadow(color: accent.opacity(0.8), radius: 10)
            Capsule().fill(accent).frame(width: 28, height: 2.5).padding(.top, 20)
        }
    }
}
