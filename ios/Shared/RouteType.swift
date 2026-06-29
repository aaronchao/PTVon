import SwiftUI

/// PTV transport modes (route_type) with friendly brand colours + SF Symbols.
enum RouteType: Int, CaseIterable, Codable {
    case train = 0
    case tram = 1
    case bus = 2
    case vline = 3
    case nightBus = 4

    var displayName: String {
        switch self {
        case .train: return "Train"
        case .tram: return "Tram"
        case .bus: return "Bus"
        case .vline: return "V/Line"
        case .nightBus: return "Night Bus"
        }
    }

    var colorHex: String {
        switch self {
        case .train: return "3F7BFF"
        case .tram: return "35C07A"
        case .bus, .nightBus: return "FF9D4D"
        case .vline: return "A06CFF"
        }
    }

    var symbol: String {
        switch self {
        case .train, .vline: return "train.side.front.car"
        case .tram: return "tram.fill"
        case .bus, .nightBus: return "bus.fill"
        }
    }

    var color: Color { Color(hex: colorHex) }

    static func from(_ value: Int) -> RouteType { RouteType(rawValue: value) ?? .bus }
}
