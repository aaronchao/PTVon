import Foundation

/// A PTV service disruption affecting a stop or line.
struct Disruption: Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String
    let type: String          // e.g. "Minor Delays", "Planned Works"
    let url: String?

    var isPlanned: Bool {
        let t = type.lowercased()
        return t.contains("planned") || t.contains("works") || t.contains("maintenance")
    }

    var symbol: String { isPlanned ? "wrench.adjustable.fill" : "exclamationmark.triangle.fill" }
}

// MARK: - DTOs (response is grouped by mode: metro_train, metro_tram, …)

struct DisruptionsEnvelope: Decodable {
    let disruptions: [String: [DisruptionDTO]]
}

struct DisruptionDTO: Decodable {
    let disruption_id: Int
    let title: String?
    let description: String?
    let disruption_type: String?
    let disruption_status: String?
    let url: String?
}
