import WidgetKit
import SwiftUI
import Foundation

/// The stop the complication shows. Reads the cached synced list when available,
/// otherwise the central city stop.
enum WatchStopStore {
    static let key = "watch.stops.v1"
    static var firstStop: Stop {
        if let data = UserDefaults.standard.data(forKey: key),
           let stops = try? JSONDecoder().decode([Stop].self, from: data),
           let first = stops.first {
            return first
        }
        return KnownStops.flindersStreet
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let stopName: String
    let departure: Departure?
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: .now, stopName: "Flinders St", departure: nil)
    }
    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        Task { completion(await entry()) }
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        Task {
            let e = await entry()
            // Re-pick the next service every few minutes; the countdown itself
            // ticks live via Text(timerInterval:) without needing a reload.
            completion(Timeline(entries: [e], policy: .after(Date().addingTimeInterval(150))))
        }
    }
    private func entry() async -> ComplicationEntry {
        let stop = WatchStopStore.firstStop
        let deps = await PtvService.shared.departures(for: stop, maxResults: 1)
        return ComplicationEntry(date: .now, stopName: stop.name, departure: deps.first)
    }
}

/// OS-driven countdown (mm:ss) that ticks without the app or a timeline reload.
private struct Countdown: View {
    let departure: Departure
    var body: some View {
        let end = departure.departureDate
        let start = min(Date(), end.addingTimeInterval(-1))
        Text(timerInterval: start...end, countsDown: true)
            .monospacedDigit()
    }
}

struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ComplicationEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            if let d = entry.departure {
                Label { Countdown(departure: d) } icon: { Image(systemName: "tram.fill") }
            } else {
                Label(entry.stopName, systemImage: "tram.fill")
            }

        case .accessoryCircular:
            VStack(spacing: 0) {
                Image(systemName: "tram.fill").font(.system(size: 11))
                if let d = entry.departure {
                    Countdown(departure: d)
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .minimumScaleFactor(0.6)
                } else {
                    Text("–").font(.headline)
                }
            }

        case .accessoryCorner:
            Group {
                if let d = entry.departure {
                    Countdown(departure: d)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                } else {
                    Image(systemName: "tram.fill")
                }
            }
            .widgetLabel(entry.stopName)

        default: // accessoryRectangular
            HStack(spacing: 6) {
                Image(systemName: "tram.fill").foregroundStyle(Color(hex: "5B8CFF"))
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.stopName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    if let d = entry.departure {
                        HStack(spacing: 4) {
                            Text(d.label).font(.caption.weight(.semibold)).lineLimit(1)
                            Countdown(departure: d).font(.caption.weight(.semibold))
                        }
                    } else {
                        Text("No departures").font(.caption)
                    }
                }
            }
        }
    }
}

@main
struct PTVonWatchComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PTVonWatchComplication", provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next departure")
        .description("Live countdown to the next train.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular, .accessoryCorner])
    }
}
