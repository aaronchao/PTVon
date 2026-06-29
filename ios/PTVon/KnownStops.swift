import Foundation

/// The stops PTVon tracks. Single source of truth shared by the dashboard
/// and the Siri / App Shortcuts integration so the two never drift apart.
enum KnownStops {
    static let flindersStreet = Stop(id: 1071, name: "Flinders Street", suburb: "Melbourne City", routeType: .train)
    static let richmond       = Stop(id: 1162, name: "Richmond", suburb: "Richmond", routeType: .train)
    static let melbourneCentral = Stop(id: 1190, name: "Melbourne Central", suburb: "Melbourne City", routeType: .train)

    static let all: [Stop] = [flindersStreet, richmond, melbourneCentral]
}
