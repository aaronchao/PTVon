import SwiftUI

@MainActor
final class WatchModel: ObservableObject {
    @Published var boards: [(stop: Stop, departures: [Departure])] = []
    @Published var loading = false

    func load() async {
        loading = true
        var result: [(Stop, [Departure])] = []
        for stop in WatchStops.shared.stops {
            result.append((stop, await PtvService.shared.departures(for: stop, maxResults: 3)))
        }
        boards = result
        loading = false
    }
}

struct WatchDashboard: View {
    @StateObject private var vm = WatchModel()
    @StateObject private var stops = WatchStops.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                if vm.boards.isEmpty && vm.loading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
                ForEach(vm.boards, id: \.stop.id) { board in
                    Section(board.stop.name) {
                        if board.departures.isEmpty {
                            Text("No departures")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        ForEach(board.departures) { dep in
                            WatchDepartureRow(dep: dep)
                        }
                    }
                }
            }
            .navigationTitle("PTVon")
        }
        .task {
            stops.start()
            await vm.load()
        }
        .onChange(of: stops.stops) { _, _ in
            Task { await vm.load() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { stops.requestSync() }
        }
    }
}

private struct WatchDepartureRow: View {
    let dep: Departure
    var body: some View {
        HStack(spacing: 9) {
            RoundedRectangle(cornerRadius: 3)
                .fill(dep.routeType.color)
                .frame(width: 4, height: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(dep.destination).font(.caption.weight(.medium)).lineLimit(1)
                HStack(spacing: 4) {
                    if dep.isLive { Circle().fill(.green).frame(width: 5, height: 5) }
                    Text(dep.label).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            TimelineView(.periodic(from: .now, by: 5)) { context in
                let m = dep.minutesUntil(context.date)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(m == 0 ? "Now" : "\(m)")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    if m > 0 { Text("m").font(.caption2).foregroundStyle(.secondary) }
                }
                .foregroundStyle(dep.routeType.color)
            }
        }
        .padding(.vertical, 2)
    }
}
