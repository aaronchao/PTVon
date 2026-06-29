import SwiftUI

@main
struct PTVonApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Must register BG task handlers before launch finishes.
        MainActor.assumeIsolated {
            BackgroundScheduler.shared.registerTasks()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    BackgroundScheduler.shared.requestAuthorization()
                    BackgroundScheduler.shared.reschedule()
                    await BackgroundScheduler.shared.evaluateAndStartIfDue()
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        WatchSync.shared.send(StopStore.shared.stops)
                        Task {
                            await LiveActivityController.shared.advanceIfDeparted()
                            await BackgroundScheduler.shared.evaluateAndStartIfDue()
                        }
                    case .background:
                        BackgroundScheduler.shared.reschedule()
                    default: break
                    }
                }
        }
    }
}
