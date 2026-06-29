import Foundation

/// Fetches live departures from PTV via the keyless Cloudflare Worker proxy.
/// The proxy holds the devid/key and signs each request — the app ships no secret.
actor PtvService {
    static let shared = PtvService()

    private let baseURL = "https://ptvon-proxy.108000.workers.dev"
    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    func departures(for stop: Stop, maxResults: Int = 4) async -> [Departure] {
        var comps = URLComponents(string: "\(baseURL)/v3/departures/route_type/\(stop.routeType.rawValue)/stop/\(stop.id)")!
        comps.queryItems = [
            URLQueryItem(name: "max_results", value: String(maxResults)),
            URLQueryItem(name: "expand", value: "Route"),
            URLQueryItem(name: "expand", value: "Direction"),
            URLQueryItem(name: "expand", value: "Run"),
        ]
        guard let url = comps.url else { return [] }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            let decoded = try JSONDecoder().decode(DeparturesResponse.self, from: data)
            return map(decoded).prefix(maxResults).map { $0 }
        } catch {
            return []
        }
    }

    /// Searches stops across train, tram and bus. Used by the stop picker.
    func searchStops(_ term: String) async -> [Stop] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else { return [] }

        var comps = URLComponents(string: "\(baseURL)/v3/search/\(encoded)")!
        comps.queryItems = [
            // 0 = train, 1 = tram, 2 = bus, 3 = V/Line
            URLQueryItem(name: "route_types", value: "0"),
            URLQueryItem(name: "route_types", value: "1"),
            URLQueryItem(name: "route_types", value: "2"),
            URLQueryItem(name: "route_types", value: "3"),
            URLQueryItem(name: "include_outlets", value: "false"),
        ]
        guard let url = comps.url else { return [] }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
            let stops = (decoded.stops ?? []).map { dto in
                Stop(
                    id: dto.stop_id,
                    name: dto.stop_name?.trimmingCharacters(in: .whitespaces) ?? "Stop \(dto.stop_id)",
                    suburb: dto.stop_suburb ?? "",
                    routeType: RouteType.from(dto.route_type)
                )
            }
            // De-duplicate by id, keep order (PTV returns most-relevant first).
            var seen = Set<Int>()
            return stops.filter { seen.insert($0.id).inserted }
        } catch {
            return []
        }
    }

    /// Downstream stops for a service, used to pick where to alight.
    /// Returns stops strictly after `boardingStopId`, with arrival times.
    func stoppingPattern(runRef: String, routeType: RouteType, after boardingStopId: Int) async -> [PatternStop] {
        var comps = URLComponents(string: "\(baseURL)/v3/pattern/run/\(runRef)/route_type/\(routeType.rawValue)")!
        comps.queryItems = [URLQueryItem(name: "expand", value: "Stop")]
        guard let url = comps.url else { return [] }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            let decoded = try JSONDecoder().decode(PatternResponse.self, from: data)

            let ordered = decoded.departures.compactMap { dto -> PatternStop? in
                let isoStr = dto.estimated_departure_utc ?? dto.scheduled_departure_utc
                guard let isoStr, let date = parse(isoStr) else { return nil }
                let name = decoded.stops[String(dto.stop_id)]?.stop_name?.trimmingCharacters(in: .whitespaces)
                return PatternStop(id: dto.stop_id, name: name ?? "Stop \(dto.stop_id)", arrival: date)
            }
            // Keep only the stops after boarding (the rest of the journey).
            if let idx = ordered.firstIndex(where: { $0.id == boardingStopId }) {
                return Array(ordered[(idx + 1)...])
            }
            return ordered
        } catch {
            return []
        }
    }

    private func map(_ res: DeparturesResponse) -> [Departure] {
        res.departures.compactMap { dto -> Departure? in
            let isoStr = dto.estimated_departure_utc ?? dto.scheduled_departure_utc
            guard let isoStr, let date = parse(isoStr) else { return nil }
            let route = res.routes[String(dto.route_id)]
            let direction = res.directions[String(dto.direction_id)]
            let run = dto.run_ref.flatMap { res.runs?[$0] }
            let type = RouteType.from(route?.route_type ?? 2)
            let label = (route?.route_number?.isEmpty == false ? route?.route_number : route?.route_name) ?? type.displayName
            return Departure(
                routeType: type,
                label: label,
                destination: run?.destination_name ?? direction?.direction_name ?? "—",
                departureDate: date,
                isLive: dto.estimated_departure_utc != nil,
                platform: dto.platform_number,
                runRef: dto.run_ref,
                routeId: dto.route_id,
                directionId: dto.direction_id,
                flags: dto.flags ?? ""
            )
        }
        .sorted { $0.departureDate < $1.departureDate }
    }

    private func parse(_ s: String) -> Date? {
        iso.date(from: s) ?? ISO8601DateFormatter().date(from: s)
    }
}
