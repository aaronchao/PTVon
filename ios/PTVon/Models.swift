import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// A pinned stop shown on the dashboard.
struct Stop: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let suburb: String
    let routeType: RouteType
}

extension Stop: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

/// A UI-ready upcoming departure.
struct Departure: Identifiable, Hashable {
    let id = UUID()
    let routeType: RouteType
    let label: String          // line name or route number
    let destination: String
    let departureDate: Date
    let isLive: Bool
    let platform: String?
    var runRef: String? = nil  // for fetching the stopping pattern
    var routeId: Int = 0       // for "next same service" matching
    var directionId: Int = 0
    var flags: String = ""

    func minutesUntil(_ now: Date = .now) -> Int {
        max(0, Int(departureDate.timeIntervalSince(now) / 60))
    }

    /// Best-effort express detection from PTV flags (the feed marks this sparsely).
    var isExpress: Bool {
        let f = flags.uppercased()
        return f.contains("EXP") || f.contains("LTD") || f.contains("ZONE")
    }
}

/// A stop on a service's stopping pattern (used for "alight at…").
struct PatternStop: Identifiable, Hashable {
    let id: Int
    let name: String
    let arrival: Date

    func minutesUntil(_ now: Date = .now) -> Int {
        max(0, Int(arrival.timeIntervalSince(now) / 60))
    }
}

// MARK: - Stopping pattern DTOs

struct PatternResponse: Decodable {
    let departures: [PatternDepartureDTO]
    let stops: [String: PatternStopDTO]
}

struct PatternDepartureDTO: Decodable {
    let stop_id: Int
    let scheduled_departure_utc: String?
    let estimated_departure_utc: String?
}

struct PatternStopDTO: Decodable {
    let stop_name: String?
}

// MARK: - PTV proxy DTOs

struct DeparturesResponse: Decodable {
    let departures: [DepartureDTO]
    let routes: [String: RouteDTO]
    let directions: [String: DirectionDTO]
    let runs: [String: RunDTO]?
}

struct DepartureDTO: Decodable {
    let route_id: Int
    let run_ref: String?
    let direction_id: Int
    let scheduled_departure_utc: String?
    let estimated_departure_utc: String?
    let platform_number: String?
    let flags: String?
}

struct RouteDTO: Decodable {
    let route_type: Int
    let route_name: String?
    let route_number: String?
}

struct DirectionDTO: Decodable {
    let direction_name: String?
}

struct RunDTO: Decodable {
    let destination_name: String?
}

// MARK: - Stop search DTOs

struct SearchResponse: Decodable {
    let stops: [SearchStopDTO]?
}

struct SearchStopDTO: Decodable {
    let stop_id: Int
    let stop_name: String?
    let stop_suburb: String?
    let route_type: Int
}
