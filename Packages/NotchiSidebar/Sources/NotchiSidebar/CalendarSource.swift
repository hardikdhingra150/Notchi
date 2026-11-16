import EventKit
import Foundation

/// Upcoming events from the Calendar app. Asks for access only when you press
/// "Show my events" in the sidebar; until then the calendar widget shows just the month.
@MainActor
final class CalendarSource {
    struct Event: Identifiable, Equatable, Sendable {
        let id: String
        let title: String
        let start: Date
        let end: Date
        let allDay: Bool
        let colorHex: String?
    }

    private let store = EKEventStore()
    private var observer: NSObjectProtocol?
    var onChange: () -> Void = {}

    var isAllowed: Bool { EKEventStore.authorizationStatus(for: .event) == .fullAccess }
    var wasDenied: Bool {
        let s = EKEventStore.authorizationStatus(for: .event)
        return s == .denied || s == .restricted || s == .writeOnly
    }

    init() {
        observer = NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.onChange() }
        }
    }

    func requestAccess() async -> Bool {
        (try? await store.requestFullAccessToEvents()) ?? false
    }

    /// The next few events from now until the end of tomorrow.
    func upcoming(limit: Int = 4, now: Date = Date()) -> [Event] {
        guard isAllowed else { return [] }
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 2, to: cal.startOfDay(for: now)) ?? now.addingTimeInterval(172_800)
        let pred = store.predicateForEvents(withStart: now.addingTimeInterval(-3600), end: end, calendars: nil)
        return store.events(matching: pred)
            .filter { $0.endDate > now }
            .sorted { $0.startDate < $1.startDate }
            .prefix(limit)
            .map { e in
                let c = e.calendar?.cgColor.flatMap { NSColorHex.hex($0) }
                return Event(id: e.eventIdentifier ?? UUID().uuidString, title: e.title ?? "Untitled", start: e.startDate, end: e.endDate,
                             allDay: e.isAllDay, colorHex: c)
            }
    }
}

enum NSColorHex {
    static func hex(_ c: CGColor) -> String? {
        guard let rgb = c.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil),
              let p = rgb.components, p.count >= 3 else { return nil }
        return String(format: "#%02X%02X%02X", Int(p[0] * 255), Int(p[1] * 255), Int(p[2] * 255))
    }
}
