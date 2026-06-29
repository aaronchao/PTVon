import Foundation
import BackgroundTasks
import UserNotifications

/// Drives the "auto pop-up during a time window" feature.
///
/// iOS does not let an app freely launch a Live Activity at an arbitrary clock
/// time while it's suspended. The supported no-server mechanisms are used here,
/// belt-and-braces:
///   1. `BGAppRefreshTask` — iOS wakes us near the window; we start the activity.
///   2. A repeating local notification at each window start — a tappable nudge
///      that opens the app, which then starts the activity immediately.
///   3. Foreground evaluation — opening the app inside a window starts it at once.
///
/// Fully unattended start (screen never touched) is only guaranteed via APNs
/// push-to-start, which needs a paid account + push server; see TESTFLIGHT.md.
@MainActor
final class BackgroundScheduler {
    static let shared = BackgroundScheduler()
    static let taskID = "com.ptvon.app.refresh"

    private let schedule = SchedulePreferences.shared
    private let live = LiveActivityController.shared

    // MARK: Registration (call once, early in launch)

    func registerTasks() {
        // The launch handler is invoked on a background queue, so hop to main.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskID, using: nil) { task in
            guard let refresh = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false); return
            }
            Task { @MainActor in self.handle(refresh) }
        }
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: Scheduling

    /// Re-plan everything after the schedule changes (or on launch).
    func reschedule() {
        scheduleNextRefresh()
        refreshLocalNotifications()
    }

    private func scheduleNextRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskID)

        let begin: Date?
        if schedule.activeWindow() != nil {
            begin = Date().addingTimeInterval(60)            // keep refreshing inside a window
        } else {
            begin = schedule.nextStart()?.addingTimeInterval(-60)  // wake just before it opens
        }
        guard let begin else { return }

        let request = BGAppRefreshTaskRequest(identifier: Self.taskID)
        request.earliestBeginDate = begin
        try? BGTaskScheduler.shared.submit(request)
    }

    private func refreshLocalNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for window in schedule.enabledWindows {
            let content = UNMutableNotificationContent()
            content.title = "PTVon · \(window.stop.name)"
            content.body = "Live departures are starting — open to see them on your Lock Screen."
            content.sound = .default

            let weekdays: [Int?] = window.weekdays.isEmpty ? [nil] : window.weekdays.sorted().map { $0 }
            for weekday in weekdays {
                var comps = DateComponents()
                comps.hour = window.startMinutes / 60
                comps.minute = window.startMinutes % 60
                if let weekday { comps.weekday = weekday }
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                let id = "win-\(window.id.uuidString)-\(weekday.map(String.init) ?? "all")"
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }

    // MARK: Execution

    private func handle(_ task: BGAppRefreshTask) {
        scheduleNextRefresh()   // chain the next wake-up immediately

        let work = Task { @MainActor in
            await live.advanceIfDeparted()       // roll a finished trip to the next service
            await evaluateAndStartIfDue()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { work.cancel() }
    }

    /// If a window is open right now and nothing is being tracked, start the
    /// next departure's Live Activity. Safe to call repeatedly.
    func evaluateAndStartIfDue() async {
        guard live.trackedKey == nil, let window = schedule.activeWindow() else { return }
        let deps = await PtvService.shared.departures(for: window.stop, maxResults: 4)
        guard let first = deps.first else { return }
        let next = deps.count > 1 ? deps[1] : nil
        live.startTracking(stop: window.stop, departure: first, next: next)
    }
}
