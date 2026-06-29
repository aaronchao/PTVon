import Foundation
import WatchConnectivity
import WidgetKit
import Combine

/// Receives the user's selected stops from the iPhone (falling back to the
/// default stops until the first sync arrives).
@MainActor
final class WatchStops: NSObject, ObservableObject {
    static let shared = WatchStops()

    @Published var stops: [Stop] = KnownStops.all
    private let session = WCSession.default
    private let key = "watch.stops.v1"

    func start() {
        loadCached()
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    /// Pull the latest stops from the phone immediately when it's reachable.
    func requestSync() {
        guard session.activationState == .activated, session.isReachable else { return }
        session.sendMessage(["request": "stops"], replyHandler: { reply in
            if let data = reply["stops"] as? Data { Task { @MainActor in self.apply(data) } }
        }, errorHandler: nil)
    }

    private func loadCached() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Stop].self, from: data), !saved.isEmpty {
            stops = saved
        }
    }

    fileprivate func apply(_ data: Data) {
        guard let decoded = try? JSONDecoder().decode([Stop].self, from: data), !decoded.isEmpty else { return }
        stops = decoded
        UserDefaults.standard.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()   // refresh the complication
    }
}

extension WatchStops: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        let data = session.receivedApplicationContext["stops"] as? Data
        Task { @MainActor in
            if let data { self.apply(data) }
            self.requestSync()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.requestSync() }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["stops"] as? Data {
            Task { @MainActor in self.apply(data) }
        }
    }
}
