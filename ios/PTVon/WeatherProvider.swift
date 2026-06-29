import Foundation
import CoreLocation
import Combine

/// Owns location + the latest weather snapshot for the dashboard header.
/// Falls back to Melbourne CBD if location is unavailable or denied.
@MainActor
final class WeatherProvider: NSObject, ObservableObject {
    static let shared = WeatherProvider()

    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var loading = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private static let melbourneCBD = CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)
    private var lastFetch: Date?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            Task { await fetch(at: Self.melbourneCBD, name: "Melbourne") }   // show something now
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            Task { await fetch(at: Self.melbourneCBD, name: "Melbourne") }
        }
    }

    /// Throttled refresh (used on appear / pull-to-refresh).
    func refresh() {
        if let last = lastFetch, Date().timeIntervalSince(last) < 300 { return }
        start()
    }

    private func fetch(at coordinate: CLLocationCoordinate2D, name: String) async {
        loading = true
        let snap = await WeatherService.shared.fetch(at: coordinate, placeName: name)
        if let snap { snapshot = snap; lastFetch = Date() }
        loading = false
    }
}

extension WeatherProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
            case .denied, .restricted: await fetch(at: Self.melbourneCBD, name: "Melbourne")
            default: break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            let name = (try? await geocoder.reverseGeocodeLocation(loc))?
                .first.flatMap { $0.locality ?? $0.subLocality ?? $0.name } ?? "Nearby"
            await fetch(at: loc.coordinate, name: name)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if snapshot == nil { await fetch(at: Self.melbourneCBD, name: "Melbourne") }
        }
    }
}
