import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Configurable stop

struct StopEntity: AppEntity {
    let id: Int
    let name: String
    let suburb: String
    let routeTypeRaw: Int

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Stop"
    static var defaultQuery = StopEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)",
                              subtitle: "\(RouteType.from(routeTypeRaw).displayName)")
    }
    var stop: Stop { Stop(id: id, name: name, suburb: suburb, routeType: RouteType.from(routeTypeRaw)) }
    init(_ s: Stop) { id = s.id; name = s.name; suburb = s.suburb; routeTypeRaw = s.routeType.rawValue }
}

struct StopEntityQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [StopEntity] {
        KnownStops.all.filter { identifiers.contains($0.id) }.map(StopEntity.init)
    }
    func suggestedEntities() async throws -> [StopEntity] {
        KnownStops.all.map(StopEntity.init)
    }
}

extension StopEntityQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [StopEntity] {
        let found = await PtvService.shared.searchStops(string)
        return found.prefix(15).map(StopEntity.init)
    }
}

struct SelectStopIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose stop"
    static var description = IntentDescription("Pick the stop to show departures for.")

    @Parameter(title: "Stop")
    var stop: StopEntity?
}

// MARK: - Timeline

struct DeparturesEntry: TimelineEntry {
    let date: Date
    let stop: Stop
    let departures: [Departure]
}

struct DeparturesProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DeparturesEntry {
        DeparturesEntry(date: .now, stop: KnownStops.flindersStreet, departures: [])
    }
    func snapshot(for configuration: SelectStopIntent, in context: Context) async -> DeparturesEntry {
        await entry(for: configuration)
    }
    func timeline(for configuration: SelectStopIntent, in context: Context) async -> Timeline<DeparturesEntry> {
        let e = await entry(for: configuration)
        return Timeline(entries: [e], policy: .after(Date().addingTimeInterval(120)))
    }
    private func entry(for configuration: SelectStopIntent) async -> DeparturesEntry {
        let stop = configuration.stop?.stop ?? KnownStops.flindersStreet
        let deps = await PtvService.shared.departures(for: stop, maxResults: 4)
        return DeparturesEntry(date: .now, stop: stop, departures: deps)
    }
}

// MARK: - Views

struct DeparturesWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DeparturesEntry

    var body: some View {
        switch family {
        case .accessoryInline:      inlineView
        case .accessoryRectangular: rectangularView
        case .systemSmall:          smallView
        default:                    mediumView
        }
    }

    private var first: Departure? { entry.departures.first }

    private func countdown(_ dep: Departure) -> some View {
        let end = dep.departureDate
        let start = min(entry.date, end.addingTimeInterval(-1))
        return Text(timerInterval: start...end, countsDown: true)
            .monospacedDigit()
    }

    // Home Screen small
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(entry.stop.name, systemImage: entry.stop.routeType.symbol)
                .font(.caption.weight(.semibold)).lineLimit(1)
                .foregroundStyle(entry.stop.routeType.color)
            Spacer(minLength: 0)
            if let dep = first {
                Text(dep.destination).font(.subheadline.weight(.semibold)).lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    countdown(dep).font(.system(.title, design: .rounded).weight(.bold))
                    Text("to go").font(.caption2).foregroundStyle(.secondary)
                }
                Text(dep.label).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            } else {
                Text("No departures").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // Home Screen medium — a few departures
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(entry.stop.name, systemImage: entry.stop.routeType.symbol)
                .font(.subheadline.weight(.bold)).lineLimit(1)
                .foregroundStyle(entry.stop.routeType.color)
            ForEach(entry.departures.prefix(3)) { dep in
                HStack(spacing: 8) {
                    Text(dep.label).font(.caption2.weight(.bold)).foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(dep.routeType.color, in: Capsule())
                    Text(dep.destination).font(.caption).lineLimit(1)
                    Spacer(minLength: 4)
                    countdown(dep).font(.callout.weight(.semibold))
                        .foregroundStyle(dep.routeType.color)
                }
            }
            if entry.departures.isEmpty {
                Text("No departures").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // Lock Screen / StandBy
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.stop.name).font(.caption2.weight(.semibold)).lineLimit(1)
            if let dep = first {
                HStack(spacing: 4) {
                    Text(dep.label).lineLimit(1)
                    Spacer(minLength: 2)
                    countdown(dep).font(.caption.weight(.bold))
                }.font(.caption2)
                if entry.departures.count > 1 {
                    Text("then \(entry.departures[1].minutesUntil(entry.date)) min")
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            } else {
                Text("No departures").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var inlineView: some View {
        Text(first.map { "\(entry.stop.name): \($0.minutesUntil(entry.date)) min" } ?? entry.stop.name)
    }
}

struct DeparturesWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "PTVonDepartures",
                               intent: SelectStopIntent.self,
                               provider: DeparturesProvider()) { entry in
            DeparturesWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Departures")
        .description("Next departures for a stop.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}
