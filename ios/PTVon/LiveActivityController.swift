import ActivityKit
import Foundation

/// Starts/stops the departure Live Activity (Dynamic Island + Lock Screen).
@MainActor
final class LiveActivityController: ObservableObject {
    static let shared = LiveActivityController()

    /// Stable key of the departure currently being tracked, or nil.
    @Published private(set) var trackedKey: String?
    /// What's being tracked, so the destination picker has context.
    @Published private(set) var trackedStop: Stop?
    @Published private(set) var trackedDeparture: Departure?
    /// The chosen alight stop, if any (optional).
    @Published private(set) var arrivalStopName: String?

    var activitiesEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    static func key(stop: Stop, departure: Departure) -> String {
        "\(stop.id)|\(Int(departure.departureDate.timeIntervalSince1970))"
    }

    func toggle(stop: Stop, departure: Departure, next: Departure? = nil) {
        let key = Self.key(stop: stop, departure: departure)
        if trackedKey == key {
            endTracking()
        } else {
            start(stop: stop, departure: departure, next: next, key: key)
        }
    }

    /// Public entry point used by the background scheduler.
    func startTracking(stop: Stop, departure: Departure, next: Departure?) {
        start(stop: stop, departure: departure, next: next,
              key: Self.key(stop: stop, departure: departure))
    }

    private func start(stop: Stop, departure: Departure, next: Departure?, key: String) {
        guard activitiesEnabled else { return }
        endAllActivities()

        let attributes = DepartureAttributes(
            stopName: stop.name,
            routeLabel: departure.label,
            destination: departure.destination,
            modeColorHex: departure.routeType.colorHex,
            modeSymbol: departure.routeType.symbol,
            modeName: departure.routeType.displayName
        )
        let state = DepartureAttributes.ContentState(
            startDate: .now,
            departureDate: departure.departureDate,
            isLive: departure.isLive,
            status: departure.isLive ? "On time" : "Scheduled",
            platform: departure.platform,
            nextDepartureDate: next?.departureDate
        )
        let content = ActivityContent(
            state: state,
            staleDate: departure.departureDate.addingTimeInterval(120)
        )

        do {
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
            trackedKey = key
            trackedStop = stop
            trackedDeparture = departure
            arrivalStopName = nil
            ArrivalReminder.cancelAll()
            DepartureReminders.schedule(stop: stop, departure: departure)
        } catch {
            print("Live Activity error: \(error)")
        }
    }

    /// When the tracked service has departed, roll the Live Activity forward to
    /// the next departure on the same route + direction at the same stop. The
    /// phone activity mirrors to the Apple Watch Smart Stack automatically.
    func advanceIfDeparted() async {
        guard let stop = trackedStop, let dep = trackedDeparture else { return }
        guard Date() >= dep.departureDate else { return }      // not gone yet

        let deps = await PtvService.shared.departures(for: stop, maxResults: 8)
        let sameLine = deps
            .filter { $0.routeId == dep.routeId && $0.directionId == dep.directionId }
            .filter { $0.departureDate > dep.departureDate.addingTimeInterval(20) }
            .sorted { $0.departureDate < $1.departureDate }

        if let nextSame = sameLine.first {
            let after = sameLine.first { $0.departureDate > nextSame.departureDate }
            start(stop: stop, departure: nextSame, next: after,
                  key: Self.key(stop: stop, departure: nextSame))
        } else {
            endTracking()   // nothing left to roll to
        }
    }

    /// Optional "alight at…": buzz the phone + watch as the service reaches `stop`.
    func setArrival(_ stop: PatternStop) {
        ArrivalReminder.schedule(stopName: stop.name, arrival: stop.arrival)
        arrivalStopName = stop.name
    }

    func clearArrival() {
        ArrivalReminder.cancelAll()
        arrivalStopName = nil
    }

    func endTracking() {
        endAllActivities()
        DepartureReminders.cancelAll()
        ArrivalReminder.cancelAll()
        trackedKey = nil
        trackedStop = nil
        trackedDeparture = nil
        arrivalStopName = nil
    }

    /// Used for verification: start a Live Activity with a sample departure.
    func startDemo() {
        let stop = Stop(id: 1162, name: "Richmond Station", suburb: "Richmond", routeType: .train)
        let dep = Departure(
            routeType: .train,
            label: "Belgrave",
            destination: "City (Flinders St)",
            departureDate: Date().addingTimeInterval(4 * 60 + 40),
            isLive: true,
            platform: "3"
        )
        let next = Departure(
            routeType: .train,
            label: "Lilydale",
            destination: "City (Flinders St)",
            departureDate: Date().addingTimeInterval(11 * 60),
            isLive: true,
            platform: "3"
        )
        start(stop: stop, departure: dep, next: next, key: Self.key(stop: stop, departure: dep))
    }

    private func endAllActivities() {
        for activity in Activity<DepartureAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
