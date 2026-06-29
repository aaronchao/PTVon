import Foundation
import Combine

/// A recurring time window during which a stop's next departure should pop up
/// automatically on the Lock Screen / Dynamic Island.
struct DepartureWindow: Identifiable, Codable, Hashable {
    var id = UUID()
    var stop: Stop
    /// Minutes since midnight (local time).
    var startMinutes: Int
    var endMinutes: Int
    /// 1 = Sunday … 7 = Saturday. Empty means every day.
    var weekdays: Set<Int> = []
    var isEnabled: Bool = true

    func startDate(on day: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: startMinutes / 60, minute: startMinutes % 60,
                      second: 0, of: day)
    }

    func endDate(on day: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: endMinutes / 60, minute: endMinutes % 60,
                      second: 0, of: day)
    }

    func matchesDay(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard !weekdays.isEmpty else { return true }
        return weekdays.contains(calendar.component(.weekday, from: date))
    }

    /// True when `date` falls inside the window today.
    func isActive(at date: Date = .now, calendar: Calendar = .current) -> Bool {
        guard isEnabled, matchesDay(date, calendar: calendar),
              let start = startDate(on: date, calendar: calendar),
              let end = endDate(on: date, calendar: calendar)
        else { return false }
        return date >= start && date <= end
    }

    /// The next time this window opens at or after `date`.
    func nextStart(after date: Date = .now, calendar: Calendar = .current) -> Date? {
        guard isEnabled else { return nil }
        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: date),
                  matchesDay(day, calendar: calendar),
                  let start = startDate(on: day, calendar: calendar),
                  let end = endDate(on: day, calendar: calendar)
            else { continue }
            if date <= start { return start }
            if date >= start && date <= end { return date }  // already open
        }
        return nil
    }

    var rangeLabel: String {
        "\(Self.label(startMinutes)) – \(Self.label(endMinutes))"
    }

    static func label(_ minutes: Int) -> String {
        var comps = DateComponents()
        comps.hour = minutes / 60; comps.minute = minutes % 60
        let date = Calendar.current.date(from: comps) ?? .now
        return date.formatted(.dateTime.hour().minute())
    }
}

@MainActor
final class SchedulePreferences: ObservableObject {
    static let shared = SchedulePreferences()
    static let maxWindows = 10

    @Published private(set) var windows: [DepartureWindow]

    var isFull: Bool { windows.count >= Self.maxWindows }

    private let key = "ptvon.schedule.v1"
    private let defaults = UserDefaults.standard

    private init() {
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode([DepartureWindow].self, from: data) {
            windows = saved
        } else {
            windows = []
        }
    }

    var enabledWindows: [DepartureWindow] { windows.filter(\.isEnabled) }

    func upsert(_ window: DepartureWindow) {
        if let i = windows.firstIndex(where: { $0.id == window.id }) {
            windows[i] = window
        } else if !isFull {
            windows.append(window)
        }
        persist()
    }

    func remove(at offsets: IndexSet) {
        windows.remove(atOffsets: offsets)
        persist()
    }

    func remove(_ window: DepartureWindow) {
        windows.removeAll { $0.id == window.id }
        persist()
    }

    /// The window that is open right now, if any (earliest start wins).
    func activeWindow(at date: Date = .now) -> DepartureWindow? {
        enabledWindows
            .filter { $0.isActive(at: date) }
            .min { ($0.startMinutes) < ($1.startMinutes) }
    }

    /// Soonest upcoming window start across all enabled windows.
    func nextStart(after date: Date = .now) -> Date? {
        enabledWindows.compactMap { $0.nextStart(after: date) }.min()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(windows) {
            defaults.set(data, forKey: key)
        }
    }
}
