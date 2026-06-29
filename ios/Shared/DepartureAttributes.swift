import ActivityKit
import Foundation

/// Static + dynamic data for the departure Live Activity (Dynamic Island + Lock Screen).
struct DepartureAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When tracking began — gives the progress bar a stable range.
        var startDate: Date
        /// The time we're counting down to.
        var departureDate: Date
        /// True when the time came from live (estimated) data.
        var isLive: Bool
        /// Short status line, e.g. "On time" / "Delayed".
        var status: String
        /// Platform / stop number, when known (e.g. "3").
        var platform: String?
        /// The departure after this one, for "then …" context.
        var nextDepartureDate: Date?
    }

    /// Stop the service departs from, e.g. "Richmond Station".
    var stopName: String
    /// Line or route badge text, e.g. "Belgrave" or "19".
    var routeLabel: String
    /// Where it's headed, e.g. "City (Flinders Street)".
    var destination: String
    /// Mode brand colour as a hex string, e.g. "3F7BFF".
    var modeColorHex: String
    /// SF Symbol for the mode, e.g. "tram.fill".
    var modeSymbol: String
    /// Friendly mode name, e.g. "Train", "Tram", "Bus".
    var modeName: String
}
