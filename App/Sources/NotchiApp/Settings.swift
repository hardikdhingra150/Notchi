import AppKit
import NotchiCore
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let window: NSWindow

    init(app: AppDelegate) {
        let view = SettingsView(themes: app.themes, hud: app.systemHUD, energy: EnergyModel(governor: app.energy, bus: app.bus))
        window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Notchi Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 560, height: 420))
        window.isReleasedWhenClosed = false
        window.center()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

@MainActor
@Observable
final class EnergyModel {
    var budget: EnergyGovernor.Budget
    var batteryFPS: Int {
        didSet { governor.batteryFPS = batteryFPS }
    }
    var pauseWhenLow: Bool {
        didSet { governor.rules.pauseWhenLow = pauseWhenLow }
    }
    private let governor: EnergyGovernor
    @ObservationIgnored private var sub: Any?

    init(governor: EnergyGovernor, bus: EventBus) {
        self.governor = governor
        budget = governor.budget
        batteryFPS = governor.batteryFPS
        pauseWhenLow = governor.rules.pauseWhenLow
        sub = bus.events.sink { [weak self] e in
            if case .energy(let b) = e { MainActor.assumeIsolated { self?.budget = b } }
        }
    }
}

struct SettingsView: View {
    let themes: ThemeEngine
    let hud: SystemHUD
    @Bindable var energy: EnergyModel

    var body: some View {
        TabView {
            Form {
                Toggle("Open Notchi at login", isOn: Binding(get: { LoginItem.isEnabled }, set: { _ in LoginItem.toggle() }))
                Toggle("Show volume and brightness in the notch", isOn: Binding(
                    get: { hud.state != .off }, set: { hud.setEnabled($0) }))
                if hud.state == .needsPermission || hud.state == .failed {
                    HStack {
                        Text("Notchi needs Accessibility access to replace the macOS volume and brightness indicator.")
                            .font(.callout).foregroundStyle(.secondary)
                        Button("Allow…") { hud.requestPermission() }
                    }
                }
                LabeledContent("Island") { Text(DisplayManager.preferredScreen.map { DisplayManager.notch(on: $0).isHardware } == true ? "Hardware notch" : "Virtual island") }
                LabeledContent("Version") { Text(Version.string) }
                Text("Hover the notch to open it. Use the notchi command to send messages to it.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .tabItem { Label("General", systemImage: "gearshape") }

            List(themes.themes) { t in
                HStack(spacing: 12) {
                    Circle().fill(Color(nsColor: NSColor(t.accent))).frame(width: 18, height: 18)
                    VStack(alignment: .leading) {
                        Text(t.name).font(.headline)
                        Text("by \(t.author) · \(t.appearance.rawValue)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if t.id == themes.active.id {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(nsColor: NSColor(t.accent)))
                    } else {
                        Button("Apply") { themes.apply(t) }
                    }
                }
                .padding(.vertical, 4)
            }
            .tabItem { Label("Themes", systemImage: "paintpalette") }

            Form {
                Section {
                    LabeledContent("Animations right now") {
                        Text(energy.budget.fps == 0 ? "Paused" : "\(energy.budget.fps) fps")
                            .foregroundStyle(energy.budget.fps == 0 ? .orange : .primary)
                    }
                    if let why = energy.budget.reason {
                        LabeledContent("Because") { Text(why) }
                    }
                    LabeledContent("Power") { Text(energy.budget.onBattery ? "On battery" : "Plugged in") }
                    LabeledContent("Reduce Motion") { Text(energy.budget.reduceMotion ? "On, calm animations" : "Off") }
                }
                Section {
                    Picker("On battery", selection: $energy.batteryFPS) {
                        Text("Pause animations").tag(0)
                        Text("15 fps").tag(15)
                        Text("Full speed (30 fps)").tag(30)
                    }
                    Toggle("Pause when the battery is below 20%", isOn: $energy.pauseWhenLow)
                } footer: {
                    Text("Notchi always pauses in Low Power Mode, when your Mac is hot, and when the wallpaper is covered or the display is asleep.")
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Energy", systemImage: "bolt") }

            VStack(spacing: 10) {
                Text("Notchi").font(.system(size: 34, weight: .bold, design: .serif))
                Text("The notch, with personality.").foregroundStyle(.secondary)
                Text("Free forever. No accounts, no analytics, no tracking.").font(.callout)
                Link("github.com/hardikdhingra150/Notchi", destination: URL(string: "https://github.com/hardikdhingra150/Notchi")!)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding()
        .frame(width: 560, height: 420)
    }
}
