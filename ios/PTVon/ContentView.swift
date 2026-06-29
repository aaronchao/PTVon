import SwiftUI
import UIKit

@MainActor
final class DashboardModel: ObservableObject {
    @Published var boards: [(stop: Stop, departures: [Departure])] = []
    @Published var alerts: [Int: [Disruption]] = [:]
    @Published var loading = false

    func load(_ stops: [Stop]) async {
        loading = true
        var result: [(Stop, [Departure])] = []
        await withTaskGroup(of: (Int, [Departure]).self) { group in
            for (i, stop) in stops.enumerated() {
                group.addTask { (i, await PtvService.shared.departures(for: stop, maxResults: 4)) }
            }
            var byIndex: [Int: [Departure]] = [:]
            for await (i, deps) in group { byIndex[i] = deps }
            result = stops.enumerated().map { ($0.element, byIndex[$0.offset] ?? []) }
        }
        boards = result
        loading = false

        await loadAlerts(stops)
    }

    /// Reorder existing boards to match a new stop order without refetching.
    func applyOrder(_ stops: [Stop]) {
        let map = Dictionary(boards.map { ($0.stop.id, $0) }, uniquingKeysWith: { a, _ in a })
        guard Set(map.keys) == Set(stops.map(\.id)) else { return }
        boards = stops.compactMap { map[$0.id] }
    }

    private func loadAlerts(_ stops: [Stop]) async {
        await withTaskGroup(of: (Int, [Disruption]).self) { group in
            for stop in stops {
                group.addTask { (stop.id, await DisruptionsService.shared.disruptions(forStop: stop.id)) }
            }
            var found: [Int: [Disruption]] = [:]
            for await (id, ds) in group { found[id] = ds }
            alerts = found
        }
    }
}

struct ContentView: View {
    @StateObject private var model = DashboardModel()
    @StateObject private var live = LiveActivityController.shared
    @StateObject private var stops = StopStore.shared
    @StateObject private var weather = WeatherProvider.shared

    @State private var showStops = false
    @State private var showSchedule = false
    @State private var showWeather = false
    @State private var disruptionContext: DisruptionContext?
    @State private var arrivalContext: ArrivalContext?
    @State private var editMode: EditMode = .inactive
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    private var appearance: Appearance { Appearance(rawValue: appearanceRaw) ?? .system }
    private let advanceTimer = Timer.publish(every: 25, on: .main, in: .common).autoconnect()

    private func enterReorder() {
        guard editMode != .active else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.snappy) { editMode = .active }
    }

    var body: some View {
        NavigationStack {
            List {
                HStack(alignment: .center, spacing: 10) {
                    Image("AppGlyph")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    PTVonWordmark()
                    Spacer()
                    if let snap = weather.snapshot {
                        WeatherTempChip(snapshot: snap) { showWeather = true }
                    }
                }
                .padding(.top, 2)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .moveDisabled(true)

                if stops.stops.isEmpty {
                    EmptyStopsCard { showStops = true }
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .moveDisabled(true)
                } else {
                    ForEach(model.boards, id: \.stop.id) { board in
                        StopCard(
                            board: board,
                            live: live,
                            alerts: model.alerts[board.stop.id] ?? [],
                            onShowAlerts: {
                                disruptionContext = DisruptionContext(
                                    stopName: board.stop.name,
                                    items: model.alerts[board.stop.id] ?? []
                                )
                            },
                            onSetAlight: { dep in
                                arrivalContext = ArrivalContext(stop: board.stop, departure: dep)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .onLongPressGesture(minimumDuration: 0.45) { enterReorder() }
                    }
                    .onMove { indices, newOffset in
                        model.boards.move(fromOffsets: indices, toOffset: newOffset)
                        stops.move(from: indices, to: newOffset)
                    }

                    Label("Tap a service for live alerts · touch & hold a card to reorder",
                          systemImage: "hand.tap")
                        .font(.caption2).foregroundStyle(.pTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 20, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .moveDisabled(true)
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden)
            .background(WeatherBackground(condition: weather.snapshot?.condition,
                                          isDay: weather.snapshot?.isDay ?? true,
                                          windy: weather.snapshot?.isWindy ?? false))
            .refreshable {
                weather.refresh()
                await model.load(stops.stops)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button { showSchedule = true } label: {
                        Image(systemName: "clock.badge")
                    }
                    Button {
                        withAnimation(.easeInOut) { appearanceRaw = appearance.next.rawValue }
                    } label: {
                        Image(systemName: appearance.icon)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if editMode == .active {
                        Button("Done") {
                            withAnimation(.snappy) { editMode = .inactive }
                        }.fontWeight(.semibold)
                    } else {
                        if live.trackedKey != nil {
                            Button(role: .destructive) {
                                withAnimation(.snappy) { live.endTracking() }
                            } label: { Image(systemName: "stop.circle.fill") }
                                .tint(.red)
                        }
                        Button { showStops = true } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .tint(Color(hex: "3F7BFF"))
        .preferredColorScheme(appearance.colorScheme)
        .sheet(isPresented: $showStops) { StopSearchView() }
        .sheet(isPresented: $showSchedule) { ScheduleSettingsView() }
        .sheet(item: $disruptionContext) { DisruptionsSheet(context: $0) }
        .sheet(item: $arrivalContext) { DestinationPickerView(context: $0) }
        .sheet(isPresented: $showWeather) {
            if let snap = weather.snapshot { WeatherDetailSheet(snapshot: snap) }
        }
        .task {
            if CommandLine.arguments.contains("-demoLiveActivity") { live.startDemo() }
            if CommandLine.arguments.contains("-showStops") { showStops = true }
            if CommandLine.arguments.contains("-showSchedule") { showSchedule = true }
            weather.start()
            WatchSync.shared.start()
            WatchSync.shared.send(stops.stops)
            await model.load(stops.stops)
            if CommandLine.arguments.contains("-demoAlerts"), let first = stops.stops.first {
                model.alerts[first.id] = [
                    Disruption(id: 1, title: "Delays up to 15 minutes due to a track fault near Richmond.",
                               description: "Buses may replace trains between Richmond and Camberwell. Allow extra travel time.",
                               type: "Minor Delays", url: "http://ptv.vic.gov.au/live-travel-updates/"),
                    Disruption(id: 2, title: "Lift unavailable at Melbourne Central.",
                               description: "Use Elizabeth Street entrance for step-free access.",
                               type: "Planned Works", url: nil),
                ]
            }
        }
        .onChange(of: stops.stops) { oldStops, newStops in
            WatchSync.shared.send(newStops)
            if Set(oldStops.map(\.id)) == Set(newStops.map(\.id)) {
                model.applyOrder(newStops)          // pure reorder — no refetch
            } else {
                Task { await model.load(newStops) } // added/removed — reload
            }
        }
        .onReceive(advanceTimer) { _ in
            if live.trackedKey != nil { Task { await live.advanceIfDeparted() } }
        }
    }
}

// MARK: - Header weather chip

private struct WeatherTempChip: View {
    let snapshot: WeatherSnapshot
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: snapshot.condition.symbol(isDay: snapshot.isDay))
                    .symbolRenderingMode(.multicolor).font(.system(size: 16))
                Text(snapshot.tempText)
                    .font(.title3.weight(.semibold)).foregroundStyle(.pText)
                if snapshot.needsUmbrella {
                    Image(systemName: "umbrella.fill")
                        .font(.caption).foregroundStyle(Color(hex: "5B8CFF"))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wordmark

struct PTVonWordmark: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("PTV").foregroundStyle(.pText)
            Text("on").foregroundStyle(Color(hex: "35C07A"))
        }
        .font(.system(size: 34, weight: .bold, design: .rounded))
        .tracking(-0.5)
    }
}

// MARK: - Drag preview

private struct StopDragPreview: View {
    let stop: Stop
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: stop.routeType.symbol).foregroundStyle(stop.routeType.color)
            Text(stop.name).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Stop card

private struct StopCard: View {
    let board: (stop: Stop, departures: [Departure])
    @ObservedObject var live: LiveActivityController
    let alerts: [Disruption]
    let onShowAlerts: () -> Void
    let onSetAlight: (Departure) -> Void

    private var alertSummary: String {
        if let first = alerts.first, alerts.count == 1 { return first.title }
        return "\(alerts.count) service alerts"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(board.stop.routeType.color.opacity(0.20))
                    Image(systemName: board.stop.routeType.symbol)
                        .foregroundStyle(board.stop.routeType.color)
                }
                .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(board.stop.name).font(.headline).foregroundStyle(.pText)
                        .lineLimit(1)
                    Text("\(board.stop.routeType.displayName)\(board.stop.suburb.isEmpty ? "" : " · \(board.stop.suburb)")")
                        .font(.caption).foregroundStyle(.pSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "line.3.horizontal")
                    .font(.callout).foregroundStyle(.pTertiary)
            }
            .padding(.horizontal, 16).padding(.top, 15).padding(.bottom, alerts.isEmpty ? 10 : 8)

            if !alerts.isEmpty {
                Button(action: onShowAlerts) {
                    HStack(spacing: 7) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(alertSummary).font(.caption.weight(.semibold)).lineLimit(1)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right").font(.caption2)
                    }
                    .foregroundStyle(Color(hex: "FFCB52"))
                    .padding(.horizontal, 11).padding(.vertical, 7)
                    .background(Color(hex: "FFCB52").opacity(0.14), in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12).padding(.bottom, 10)
            }

            if board.departures.isEmpty {
                Text("No upcoming departures")
                    .font(.subheadline).foregroundStyle(.pTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16).padding(.bottom, 16)
            } else {
                ForEach(Array(board.departures.enumerated()), id: \.element.id) { idx, dep in
                    let next = idx + 1 < board.departures.count ? board.departures[idx + 1] : nil
                    let tracked = live.trackedKey == LiveActivityController.key(stop: board.stop, departure: dep)
                    DepartureRow(
                        departure: dep,
                        isTracked: tracked,
                        arrivalName: tracked ? live.arrivalStopName : nil,
                        onToggle: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                live.toggle(stop: board.stop, departure: dep, next: next)
                            }
                        },
                        onSetAlight: { onSetAlight(dep) }
                    )
                    if idx < board.departures.count - 1 {
                        Divider().overlay(Color.pHairline).padding(.leading, 16)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .glassCard()
    }
}

// MARK: - Departure row

private struct DepartureRow: View {
    let departure: Departure
    let isTracked: Bool
    var arrivalName: String? = nil
    var onToggle: () -> Void = {}
    var onSetAlight: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Fixed width so destinations + the live dots line up across rows.
                Text(departure.label)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.65)
                    .frame(width: 78, height: 28)
                    .background(departure.routeType.color, in: Capsule())

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(departure.destination)
                            .font(.body.weight(.semibold)).foregroundStyle(.pText)
                            .lineLimit(1)
                        if departure.isExpress { ExpressTag(color: departure.routeType.color) }
                    }
                    HStack(spacing: 6) {
                        if departure.isLive { PulsingDot() }
                        Text(isTracked ? "Tracking" : (departure.isLive ? "Live" : "Scheduled"))
                            .foregroundStyle(isTracked ? departure.routeType.color : .pSecondary)
                        if let p = departure.platform, !p.isEmpty {
                            Text("· Plat \(p)").foregroundStyle(.pSecondary)
                        }
                    }
                    .font(.caption)
                }

                Spacer(minLength: 8)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let m = departure.minutesUntil(context.date)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(m == 0 ? "Now" : "\(m)")
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                        if m > 0 { Text("min").font(.caption2).foregroundStyle(.pTertiary) }
                    }
                    .foregroundStyle(isTracked ? departure.routeType.color : .pText)
                }

                Image(systemName: isTracked ? "bell.fill" : "bell")
                    .foregroundStyle(isTracked ? departure.routeType.color : .pTertiary)
                    .symbolEffect(.bounce, value: isTracked)
            }
            .contentShape(Rectangle())
            .onTapGesture { onToggle() }

            if isTracked, let onSetAlight {
                Button(action: onSetAlight) {
                    HStack(spacing: 6) {
                        Image(systemName: arrivalName == nil ? "figure.walk.circle" : "bell.badge.fill")
                        Text(arrivalName == nil ? "Set alight stop — buzz on arrival"
                                                : "Alight: \(arrivalName!) · change")
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        Image(systemName: "chevron.right").font(.caption2)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(departure.routeType.color)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(departure.routeType.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
        .background {
            ZStack {
                if isTracked { departure.routeType.color.opacity(0.10) }
                if departure.isExpress { ExpressShimmer(color: departure.routeType.color) }
            }
        }
    }
}

// MARK: - Express highlight

private struct ExpressTag: View {
    let color: Color
    @State private var phase = false
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "bolt.fill").font(.system(size: 8))
            Text("Express")
            HStack(spacing: -2) {
                ForEach(0..<3) { i in
                    Image(systemName: "chevron.right").font(.system(size: 7, weight: .bold))
                        .opacity(phase ? 1 : 0.25)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.16), value: phase)
                }
            }
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(color)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(color.opacity(0.16), in: Capsule())
        .onAppear { phase = true }
    }
}

/// A bright streak that sweeps across an express row — makes it feel fast.
private struct ExpressShimmer: View {
    let color: Color
    @State private var sweep = false
    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: [.clear, color.opacity(0.22), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: geo.size.width * 0.5)
                .offset(x: sweep ? geo.size.width * 1.1 : -geo.size.width * 0.6)
                .onAppear {
                    withAnimation(.linear(duration: 1.7).repeatForever(autoreverses: false)) { sweep = true }
                }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Empty state

private struct EmptyStopsCard: View {
    let add: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color(hex: "5B8CFF"))
            Text("Add your stops")
                .font(.title2.weight(.bold)).foregroundStyle(.pText)
            Text("Pick up to \(StopStore.maxStops) train, tram or bus stops to see live departures.")
                .font(.subheadline).foregroundStyle(.pSecondary)
                .multilineTextAlignment(.center)
            Button(action: add) {
                Label("Find stops", systemImage: "magnifyingglass")
                    .font(.headline).padding(.horizontal, 22).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "3F7BFF"))
            .clipShape(Capsule())
            .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}
