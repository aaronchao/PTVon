import SwiftUI

/// Optional "alight at…" — pick a downstream stop; the phone + watch buzz on arrival.
struct ArrivalContext: Identifiable {
    let id = UUID()
    let stop: Stop
    let departure: Departure
}

struct DestinationPickerView: View {
    let context: ArrivalContext
    @ObservedObject private var live = LiveActivityController.shared
    @Environment(\.dismiss) private var dismiss

    @State private var stops: [PatternStop] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            List {
                if loading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else if stops.isEmpty {
                    Text("Couldn't load the stop list for this service.")
                        .foregroundStyle(.secondary)
                } else {
                    Section {
                        ForEach(stops) { s in
                            Button { live.setArrival(s); dismiss() } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: live.arrivalStopName == s.name
                                          ? "bell.badge.fill" : "mappin.circle")
                                        .foregroundStyle(live.arrivalStopName == s.name
                                                         ? Color(hex: "5B8CFF") : .secondary)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(s.name).foregroundStyle(.primary)
                                        Text("arrives \(s.arrival, format: .dateTime.hour().minute())")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(s.minutesUntil()) min")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } footer: {
                        Text("Your phone and Apple Watch will buzz as the service nears your stop.")
                    }

                    if live.arrivalStopName != nil {
                        Button("Turn off arrival buzz", role: .destructive) {
                            live.clearArrival(); dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Alight at…")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                guard let run = context.departure.runRef else { loading = false; return }
                stops = await PtvService.shared.stoppingPattern(
                    runRef: run, routeType: context.departure.routeType, after: context.stop.id)
                loading = false
            }
        }
        .tint(Color(hex: "5B8CFF"))
    }
}
