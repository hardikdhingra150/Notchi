import AppKit
import NotchiCore
import NotchiNotch
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let window: NSWindow

    init(app: AppDelegate) {
        let view = SettingsView(island: app.island, themes: app.themes, hud: app.systemHUD, energy: EnergyModel(governor: app.energy, bus: app.bus),
                                coordinator: app.coordinator, setup: app.setup)
        window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Notchi Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 580, height: 470))
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
    let island: NotchIslandController?
    let themes: ThemeEngine
    let hud: SystemHUD
    @Bindable var energy: EnergyModel
    @Bindable var coordinator: ThemeCoordinator
    let setup: SetupManager

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
                IslandSettings(island: island)
                LabeledContent("Version") { Text(Version.string) }
                Text("Hover the notch to open it. Use the notchi command to send messages to it.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .tabItem { Label("General", systemImage: "gearshape") }

            VStack(alignment: .leading, spacing: 10) {
                List(themes.themes) { t in
                    HStack(spacing: 12) {
                        Circle().fill(Color(nsColor: NSColor(t.accent))).frame(width: 18, height: 18)
                        VStack(alignment: .leading) {
                            Text(t.name).font(.headline)
                            Text("by \(t.author) · \(t.appearance.rawValue)\(themes.isUserTheme(t.id) ? " · installed by you" : "")").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu {
                            Button("Export…") { setup.exportThemePanel(id: t.id) }
                            if themes.isUserTheme(t.id) {
                                Button("Remove", role: .destructive) { try? themes.remove(id: t.id) }
                            }
                        } label: { Image(systemName: "ellipsis.circle") }
                            .menuStyle(.borderlessButton).fixedSize()
                            .accessibilityLabel("More for \(t.name)")
                        if t.id == themes.active.id {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(nsColor: NSColor(t.accent)))
                                .accessibilityLabel("Active")
                        } else {
                            Button("Apply") { themes.apply(t) }
                        }
                    }
                    .padding(.vertical, 4)
                }
                Toggle("Themes change my wallpaper", isOn: $coordinator.setsWallpaper)
                Toggle("Folders tinted with the accent follow the theme", isOn: $coordinator.tintsIcons)
                HStack {
                    Button("Import Theme…") { setup.importThemePanel() }
                    Button("Open Themes Folder") {
                        try? FileManager.default.createDirectory(at: themes.userThemesFolder, withIntermediateDirectories: true)
                        NSWorkspace.shared.open(themes.userThemesFolder)
                    }
                    Spacer()
                    if !themes.loadErrors.isEmpty {
                        Label("\(themes.loadErrors.count) theme file\(themes.loadErrors.count == 1 ? "" : "s") couldn't load", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.orange)
                            .help(themes.loadErrors.joined(separator: "\n"))
                    }
                }
            }
            .padding(.horizontal, 6)
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

            Form {
                Section {
                    LabeledContent("Back up my setup") { Button("Save Backup…") { setup.backupPanel() } }
                    LabeledContent("Restore a backup") { Button("Choose File…") { setup.restorePanel() } }
                    LabeledContent("Automatic backups") { Button("Show in Finder") {
                        try? FileManager.default.createDirectory(at: setup.backupsFolder, withIntermediateDirectories: true)
                        NSWorkspace.shared.open(setup.backupsFolder)
                    } }
                } footer: {
                    Text("A backup is one file with your theme, settings, installed themes, custom icons and wallpaper. Notchi also saves one by itself before a restore or a reset, and keeps the newest five.")
                }
                Section {
                    LabeledContent("Restore stock macOS") { Button("Restore…") { setup.confirmReset() } }
                } footer: {
                    Text("Turns off the wallpaper, puts back every icon Notchi changed and gives volume and brightness back to macOS.")
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Backup", systemImage: "externaldrive") }

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
        .frame(width: 580, height: 470)
    }
}

/// Where the island lives, and how it behaves on a screen without a notch.
struct IslandSettings: View {
    let island: NotchIslandController?
    @AppStorage(DisplayManager.placementKey) private var placement = DisplayManager.Placement.automatic.rawValue
    @AppStorage(NotchIslandController.hideIdleKey) private var hideIdle = false

    private var onHardware: Bool { DisplayManager.preferredScreen.map { DisplayManager.notch(on: $0).isHardware } == true }

    var body: some View {
        Picker("Show the island on", selection: $placement) {
            ForEach(DisplayManager.Placement.allCases, id: \.rawValue) { Text($0.label).tag($0.rawValue) }
        }
        .onChange(of: placement) { island?.settingsChanged() }
        Toggle("On screens without a notch, hide the island until something happens", isOn: $hideIdle)
            .onChange(of: hideIdle) { island?.settingsChanged() }
        LabeledContent("Right now") { Text(onHardware ? "On the notch" : "A virtual island at the top of the screen") }
    }
}
