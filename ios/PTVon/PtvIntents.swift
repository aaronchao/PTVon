import AppIntents
import Foundation

/// A stop the user can name out loud to Siri, e.g. "next train from Richmond".
enum StopOption: String, AppEnum {
    case flindersStreet
    case richmond
    case melbourneCentral

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Stop")

    static var caseDisplayRepresentations: [StopOption: DisplayRepresentation] = [
        .flindersStreet: "Flinders Street",
        .richmond: "Richmond",
        .melbourneCentral: "Melbourne Central",
    ]

    var stop: Stop {
        switch self {
        case .flindersStreet: return KnownStops.flindersStreet
        case .richmond: return KnownStops.richmond
        case .melbourneCentral: return KnownStops.melbourneCentral
        }
    }
}

/// "Hey Siri, next departure in PTVon" — fetches live data through the keyless
/// proxy and speaks how many minutes are left, without opening the app.
struct NextDepartureIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Departure"
    static var description = IntentDescription(
        "Ask how many minutes until the next departure from one of your stops."
    )
    /// Run in the background and just speak the answer — no need to open the app.
    static var openAppWhenRun = false

    @Parameter(title: "Stop")
    var stop: StopOption?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let chosen = stop ?? .richmond
        let s = chosen.stop
        let departures = await PtvService.shared.departures(for: s, maxResults: 3)

        guard let next = departures.first else {
            return .result(
                dialog: IntentDialog(stringLiteral:
                    "I couldn't find any upcoming departures from \(s.name) right now.")
            )
        }

        let mode = s.routeType.displayName.lowercased()
        let mins = next.minutesUntil()
        let timing: String
        switch mins {
        case ...0: timing = "is departing now"
        case 1:    timing = "leaves in 1 minute"
        default:   timing = "leaves in \(mins) minutes"
        }
        let qualifier = next.isLive ? "" : " That's the scheduled time."

        let spoken = "The next \(mode) from \(s.name) \(timing), heading to \(next.destination).\(qualifier)"
        return .result(dialog: IntentDialog(stringLiteral: spoken))
    }
}

/// Registers the Siri phrases. Phrases must contain the app name; a couple also
/// capture the stop so users can say a specific station.
struct PTVonShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextDepartureIntent(),
            phrases: [
                "Next departure in \(.applicationName)",
                "When is my next train in \(.applicationName)",
                "How long until my next train in \(.applicationName)",
                "Next departure from \(\.$stop) in \(.applicationName)",
                "When is the next train from \(\.$stop) in \(.applicationName)",
            ],
            shortTitle: "Next Departure",
            systemImageName: "tram.fill"
        )
    }
}
