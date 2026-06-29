import SwiftUI

/// Search PTV for stops across train / tram / bus and pick up to 4.
struct StopSearchView: View {
    @ObservedObject var store = StopStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [Stop] = []
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if store.stops.isEmpty {
                        Text("No stops yet — use the search bar above to add up to \(StopStore.maxStops).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.stops) { stop in
                        StopRow(stop: stop, trailing: .added) { store.remove(stop) }
                    }
                    .onMove { store.move(from: $0, to: $1) }
                    .onDelete { idx in idx.map { store.stops[$0] }.forEach(store.remove) }
                } header: {
                    HStack {
                        Text("Your stops")
                        Spacer()
                        Text("\(store.stops.count)/\(StopStore.maxStops)")
                            .foregroundStyle(store.isFull ? .orange : .secondary)
                    }
                }

                if !results.isEmpty {
                    Section("Results") {
                        ForEach(results) { stop in
                            let isAdded = store.contains(stop)
                            StopRow(stop: stop, trailing: isAdded ? .added : (store.isFull ? .full : .add)) {
                                if !isAdded { withAnimation(.snappy) { store.add(stop) } }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stops")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search station, tram or bus stop")
            .onChange(of: query) { _, newValue in scheduleSearch(newValue) }
            .overlay {
                if searching && results.isEmpty {
                    ProgressView().controlSize(.large)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarLeading) { EditButton() }
            }
        }
        .tint(Color(hex: "3F7BFF"))
    }

    private func scheduleSearch(_ term: String) {
        searchTask?.cancel()
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            results = []; searching = false; return
        }
        searching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)   // debounce
            if Task.isCancelled { return }
            let found = await PtvService.shared.searchStops(trimmed)
            if Task.isCancelled { return }
            await MainActor.run {
                results = found
                searching = false
            }
        }
    }
}

private enum RowTrailing { case add, added, full }

private struct StopRow: View {
    let stop: Stop
    let trailing: RowTrailing
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(stop.routeType.color.opacity(0.18))
                    Image(systemName: stop.routeType.symbol)
                        .font(.callout)
                        .foregroundStyle(stop.routeType.color)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 1) {
                    Text(stop.name).font(.body.weight(.medium)).foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(stop.routeType.displayName)\(stop.suburb.isEmpty ? "" : " · \(stop.suburb)")")
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }

                Spacer(minLength: 6)

                switch trailing {
                case .add:
                    Image(systemName: "plus.circle.fill")
                        .font(.title2).foregroundStyle(Color(hex: "3F7BFF"))
                case .added:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2).foregroundStyle(.green)
                case .full:
                    Image(systemName: "plus.circle")
                        .font(.title2).foregroundStyle(.quaternary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(trailing == .full)
    }
}
