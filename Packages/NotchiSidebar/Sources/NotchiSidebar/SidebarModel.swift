import AppKit
import NotchiCore
import Observation
import SwiftUI

/// Everything the sidebar shows. Lives as long as the app; only samples stats while open.
@MainActor
@Observable
public final class SidebarModel {
    public var isOpen = false
    public var widgets: [SidebarWidget] = SidebarWidget.allCases
    public var accent: Color = .orange
    public var dark = true
    public var glassTint: Double = 0.25
    public var reduceMotion = false

    public var nowPlaying: NowPlaying?
    public var artwork: NSImage?
    public var battery: BatteryState?
    public var stats: SystemStats?
    var events: [CalendarSource.Event] = []
    var calendarAllowed = false
    var calendarDenied = false

    public var notes: String = "" {
        didSet { if notes != oldValue { scheduleSave() } }
    }

    public var onPlayPause: () -> Void = {}
    public var onNext: () -> Void = {}
    public var onPrevious: () -> Void = {}
    var onConnectCalendar: () -> Void = {}
    public var onOpenSettings: () -> Void = {}

    /// Rendering to an image (snapshots): no live material or timers.
    public var isSnapshot = false

    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored let notesURL: URL

    public init(notesURL: URL = SetupBackup.supportURL.appendingPathComponent("notes.txt")) {
        self.notesURL = notesURL
        notes = (try? String(contentsOf: notesURL, encoding: .utf8)) ?? ""
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let text = notes, url = notesURL
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    public func reloadNotes() {
        let text = (try? String(contentsOf: notesURL, encoding: .utf8)) ?? ""
        if text != notes { notes = text }
    }
}
