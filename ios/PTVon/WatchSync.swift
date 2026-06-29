import Foundation
import WatchConnectivity

/// Pushes the user's selected stops to the paired Apple Watch.
@MainActor
final class WatchSync: NSObject, ObservableObject {
    static let shared = WatchSync()
    private let session = WCSession.default

    func start() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    func send(_ stops: [Stop]) {
        guard WCSession.isSupported(),
              session.activationState == .activated,
              let data = try? JSONEncoder().encode(stops) else { return }
        try? session.updateApplicationContext(["stops": data])
    }

    private func currentStopsData() -> Data {
        (try? JSONEncoder().encode(StopStore.shared.stops)) ?? Data()
    }
}

extension WatchSync: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    /// The watch asks for the current stops on launch — reply with them.
    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            replyHandler(["stops": self.currentStopsData()])
        }
    }
}
