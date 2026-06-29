import Foundation

/// Fetches current PTV disruptions for a stop, via the keyless proxy.
actor DisruptionsService {
    static let shared = DisruptionsService()
    private let baseURL = "https://ptvon-proxy.108000.workers.dev"

    func disruptions(forStop id: Int) async -> [Disruption] {
        guard let url = URL(string: "\(baseURL)/v3/disruptions/stop/\(id)") else { return [] }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            let env = try JSONDecoder().decode(DisruptionsEnvelope.self, from: data)

            var seen = Set<Int>()
            var out: [Disruption] = []
            for (_, items) in env.disruptions {
                for dto in items where seen.insert(dto.disruption_id).inserted {
                    if let status = dto.disruption_status, status.lowercased() != "current" { continue }
                    let type = dto.disruption_type ?? ""
                    // Skip "Service Information" noise; keep delays, works, suspensions.
                    if type.lowercased() == "service information", (dto.description ?? "").isEmpty { continue }
                    out.append(Disruption(
                        id: dto.disruption_id,
                        title: dto.title ?? "Service disruption",
                        description: dto.description ?? "",
                        type: type,
                        url: dto.url
                    ))
                }
            }
            // Unplanned issues (delays/suspensions) first, planned works after.
            return out.sorted { !$0.isPlanned && $1.isPlanned }
        } catch {
            return []
        }
    }
}
