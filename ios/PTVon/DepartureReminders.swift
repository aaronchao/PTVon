import Foundation
import UserNotifications
import AVFoundation

/// Schedules buzz-reminders for a tracked departure at 10 / 5 / 3 minutes before
/// and at departure. These are local notifications, so they fire even when the
/// app is closed and are automatically mirrored to the paired Apple Watch.
/// The gentle sound is routed by iOS to Bluetooth headphones when connected.
enum DepartureReminders {
    private static let idPrefix = "dep-reminder-"
    private static let marks = [10, 5, 3, 0]      // minutes before departure

    static func schedule(stop: Stop, departure: Departure) {
        cancelAll()
        let center = UNUserNotificationCenter.current()

        for m in marks {
            let fire = departure.departureDate.addingTimeInterval(Double(-m * 60))
            let seconds = fire.timeIntervalSinceNow
            guard seconds > 5 else { continue }          // skip marks already past

            let content = UNMutableNotificationContent()
            content.title = "\(departure.label) · \(stop.name)"
            content.body = m == 0
                ? "Departing now → \(departure.destination)"
                : "Leaves in \(m) min → \(departure.destination)"
            // Gentle sound. iOS plays it through Bluetooth headphones if connected;
            // the buzz reaches the phone and the watch regardless.
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            center.add(UNNotificationRequest(identifier: "\(idPrefix)\(m)", content: content, trigger: trigger))
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: marks.map { "\(idPrefix)\($0)" })
    }

    /// True when audio is currently routed to Bluetooth headphones.
    static var bluetoothHeadphonesConnected: Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains {
            [.bluetoothA2DP, .bluetoothHFP, .bluetoothLE].contains($0.portType)
        }
    }
}
