import SwiftUI

/// Manage the time windows that auto-surface departures to the Lock Screen.
struct ScheduleSettingsView: View {
    @ObservedObject var schedule = SchedulePreferences.shared
    @ObservedObject var stops = StopStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var editing: DepartureWindow?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if schedule.windows.isEmpty {
                        ContentUnavailableView {
                            Label("No auto-windows", systemImage: "clock.badge")
                        } description: {
                            Text("Add a time range and PTVon will surface that stop's next departure on your Lock Screen automatically.")
                        }
                    }
                    ForEach(schedule.windows) { window in
                        Button { edit(window) } label: { WindowRow(window: window) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { schedule.remove(at: $0); BackgroundScheduler.shared.reschedule() }
                } header: {
                    HStack {
                        Text("Time windows")
                        Spacer()
                        Text("\(schedule.windows.count)/\(SchedulePreferences.maxWindows)")
                            .foregroundStyle(schedule.isFull ? .orange : .secondary)
                    }
                } footer: {
                    Text("Add up to \(SchedulePreferences.maxWindows) windows. During a window, the departure appears on the Lock Screen & Dynamic Island. Fully hands-free arrival depends on iOS background timing and that Background App Refresh + Notifications are enabled for PTVon.")
                }
            }
            .navigationTitle("Auto Live Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addNew() } label: { Image(systemName: "plus") }
                        .disabled(stops.stops.isEmpty || schedule.isFull)
                }
            }
            .sheet(item: $editing) { window in
                WindowEditor(window: window, stops: stops.stops) { saved in
                    schedule.upsert(saved)
                    BackgroundScheduler.shared.reschedule()
                }
            }
        }
        .tint(Color(hex: "3F7BFF"))
    }

    private func addNew() {
        guard let stop = stops.stops.first else { return }
        editing = DepartureWindow(stop: stop, startMinutes: 8 * 60, endMinutes: 9 * 60)
    }

    private func edit(_ window: DepartureWindow) {
        editing = window
    }
}

private struct WindowRow: View {
    let window: DepartureWindow
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(window.stop.routeType.color.opacity(0.18))
                Image(systemName: window.stop.routeType.symbol)
                    .foregroundStyle(window.stop.routeType.color)
            }
            .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(window.stop.name).font(.body.weight(.medium)).lineLimit(1)
                Text("\(window.rangeLabel) · \(daysLabel(window.weekdays))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !window.isEnabled {
                Text("Off").font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
    }
}

private func daysLabel(_ weekdays: Set<Int>) -> String {
    if weekdays.isEmpty { return "Every day" }
    if weekdays == [2, 3, 4, 5, 6] { return "Weekdays" }
    if weekdays == [1, 7] { return "Weekends" }
    let symbols = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    return weekdays.sorted().map { symbols[$0] }.joined(separator: " ")
}

// MARK: - Editor

private struct WindowEditor: View {
    @State var window: DepartureWindow
    let stops: [Stop]
    let onSave: (DepartureWindow) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var start = Date()
    @State private var end = Date()

    private let weekdaySymbols = [(1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Stop") {
                    Picker("Stop", selection: $window.stop) {
                        ForEach(stops) { stop in
                            Label(stop.name, systemImage: stop.routeType.symbol).tag(stop)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Time range") {
                    DatePicker("From", selection: $start, displayedComponents: .hourAndMinute)
                    DatePicker("To", selection: $end, displayedComponents: .hourAndMinute)
                }

                Section("Repeat") {
                    HStack(spacing: 8) {
                        ForEach(weekdaySymbols, id: \.0) { day in
                            let on = window.weekdays.contains(day.0)
                            Button {
                                if on { window.weekdays.remove(day.0) }
                                else { window.weekdays.insert(day.0) }
                            } label: {
                                Text(day.1)
                                    .font(.subheadline.weight(.semibold))
                                    .frame(width: 34, height: 34)
                                    .background(on ? Color(hex: "3F7BFF") : Color.gray.opacity(0.18),
                                                in: Circle())
                                    .foregroundStyle(on ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    Text(window.weekdays.isEmpty ? "Every day" : "Selected days only")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section {
                    Toggle("Enabled", isOn: $window.isEnabled)
                }
            }
            .navigationTitle("Time Window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        window.startMinutes = minutes(from: start)
                        window.endMinutes = minutes(from: end)
                        onSave(window)
                        dismiss()
                    }.fontWeight(.semibold)
                }
            }
            .onAppear {
                start = date(fromMinutes: window.startMinutes)
                end = date(fromMinutes: window.endMinutes)
            }
        }
    }

    private func minutes(from date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
    private func date(fromMinutes m: Int) -> Date {
        Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: .now) ?? .now
    }
}
