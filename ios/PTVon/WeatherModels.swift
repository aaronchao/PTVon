import Foundation

/// What the sky is doing — drives both the icon and the animated scene.
enum WeatherCondition {
    case clear, partlyCloudy, cloudy, fog, drizzle, rain, snow, thunderstorm

    /// Map a WMO weather code (Open-Meteo) to a condition.
    static func from(code: Int) -> WeatherCondition {
        switch code {
        case 0:              return .clear
        case 1, 2:           return .partlyCloudy
        case 3:              return .cloudy
        case 45, 48:         return .fog
        case 51, 53, 55, 56, 57: return .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82: return .rain
        case 71, 73, 75, 77, 85, 86: return .snow
        case 95, 96, 99:     return .thunderstorm
        default:             return .cloudy
        }
    }

    func title(isDay: Bool) -> String {
        switch self {
        case .clear:        return isDay ? "Clear" : "Clear night"
        case .partlyCloudy: return "Partly cloudy"
        case .cloudy:       return "Cloudy"
        case .fog:          return "Fog"
        case .drizzle:      return "Drizzle"
        case .rain:         return "Rain"
        case .snow:         return "Snow"
        case .thunderstorm: return "Storms"
        }
    }

    func symbol(isDay: Bool) -> String {
        switch self {
        case .clear:        return isDay ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloudy:       return "cloud.fill"
        case .fog:          return "cloud.fog.fill"
        case .drizzle:      return "cloud.drizzle.fill"
        case .rain:         return "cloud.rain.fill"
        case .snow:         return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        }
    }

    var isWet: Bool {
        switch self {
        case .drizzle, .rain, .snow, .thunderstorm: return true
        default: return false
        }
    }
}

/// One hour in the mini forecast strip.
struct HourForecast: Identifiable {
    let id = UUID()
    let date: Date
    let temperature: Double
    let precipitationChance: Int
    let condition: WeatherCondition
}

/// Everything the weather widget needs.
struct WeatherSnapshot {
    let temperature: Double
    let apparent: Double            // RealFeel
    let condition: WeatherCondition
    let isDay: Bool
    let windSpeed: Double           // km/h
    let precipitation: Double       // mm
    let hourly: [HourForecast]
    let placeName: String

    var tempText: String { "\(Int(temperature.rounded()))°" }
    var feelsText: String { "Feels \(Int(apparent.rounded()))°" }

    /// Noticeable wind (≈25 km/h+) drives the windy animations.
    var isWindy: Bool { windSpeed >= 25 }
    var windText: String { "\(Int(windSpeed.rounded())) km/h wind" }

    /// Highest rain chance over the next few hours.
    var soonRainChance: Int { hourly.prefix(4).map(\.precipitationChance).max() ?? 0 }

    /// "Take an umbrella" guidance.
    var needsUmbrella: Bool {
        condition.isWet || precipitation > 0.1 || soonRainChance >= 40
    }

    var umbrellaAdvice: String {
        if condition.isWet || precipitation > 0.2 { return "Take an umbrella" }
        if soonRainChance >= 40 { return "Umbrella — \(soonRainChance)% rain soon" }
        return "No umbrella needed"
    }

    /// What to wear, tuned to Melbourne's RealFeel swings.
    var clothingAdvice: String {
        switch apparent {
        case ..<6:    return "Rug up — coat, scarf & gloves"
        case 6..<11:  return "Warm coat weather"
        case 11..<15: return "A jacket will do"
        case 15..<20: return "Light layers"
        case 20..<26: return "T-shirt weather"
        default:      return "Stay cool & hydrated"
        }
    }

    var clothingSymbol: String {
        switch apparent {
        case ..<11:   return "snowflake"
        case 11..<20: return "wind"
        default:      return "tshirt"
        }
    }
}

// MARK: - Open-Meteo DTOs

struct OpenMeteoResponse: Decodable {
    let current: CurrentDTO
    let hourly: HourlyDTO

    struct CurrentDTO: Decodable {
        let temperature_2m: Double
        let apparent_temperature: Double
        let precipitation: Double
        let weather_code: Int
        let wind_speed_10m: Double
        let is_day: Int
    }
    struct HourlyDTO: Decodable {
        let time: [String]
        let temperature_2m: [Double]
        let precipitation_probability: [Int?]
        let weather_code: [Int]
    }
}
