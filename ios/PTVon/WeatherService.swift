import Foundation
import CoreLocation

/// Fetches current + hourly weather from Open-Meteo. Free, keyless, no account —
/// keeps PTVon's "no credentials" promise intact.
actor WeatherService {
    static let shared = WeatherService()

    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private let hourParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    func fetch(at coordinate: CLLocationCoordinate2D, placeName: String) async -> WeatherSnapshot? {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude", value: String(format: "%.4f", coordinate.latitude)),
            .init(name: "longitude", value: String(format: "%.4f", coordinate.longitude)),
            .init(name: "current", value: "temperature_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day"),
            .init(name: "hourly", value: "temperature_2m,precipitation_probability,weather_code"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_hours", value: "12"),
        ]
        guard let url = comps.url else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let r = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

            let now = Date()
            var hours: [HourForecast] = []
            for (i, t) in r.hourly.time.enumerated() {
                guard let date = hourParser.date(from: t), date >= now.addingTimeInterval(-1800),
                      i < r.hourly.temperature_2m.count, i < r.hourly.weather_code.count
                else { continue }
                hours.append(HourForecast(
                    date: date,
                    temperature: r.hourly.temperature_2m[i],
                    precipitationChance: r.hourly.precipitation_probability[safe: i].flatMap { $0 } ?? 0,
                    condition: .from(code: r.hourly.weather_code[i])
                ))
                if hours.count >= 6 { break }
            }

            return WeatherSnapshot(
                temperature: r.current.temperature_2m,
                apparent: r.current.apparent_temperature,
                condition: .from(code: r.current.weather_code),
                isDay: r.current.is_day == 1,
                windSpeed: r.current.wind_speed_10m,
                precipitation: r.current.precipitation,
                hourly: hours,
                placeName: placeName
            )
        } catch {
            return nil
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
