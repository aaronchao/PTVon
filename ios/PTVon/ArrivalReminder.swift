import Foundation
import UserNotifications

/// Buzzes the phone (and, mirrored, the Apple Watch) as the tracked service
/// approaches and reaches the chosen alight stop. Optional — only used when the
/// user sets a destination.
enum ArrivalReminder {
    private static let preID = "arrival-reminder-pre"
    private static let nowID = "arrival-reminder-now"

    static func schedule(stopName: String, arrival: Date) {
        cancelAll()
        // "Get ready" ~90s before, then "arriving now".
        add(id: preID, fireAt: arrival.addingTimeInterval(-90),
            title: "Next stop: \(stopName)", body: "Get ready to hop off.")
        add(id: nowID, fireAt: arrival,
            title: "Arriving \(stopName)", body: "Time to alight.")
    }

    static func cancelAll() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [preID, nowID])
    }

    private static func add(id: String, fireAt: Date, title: String, body: String) {
        let seconds = fireAt.timeIntervalSinceNow
        guard seconds > 5 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default       // routes to Bluetooth headphones if connected
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
