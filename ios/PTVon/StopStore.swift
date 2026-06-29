import Foundation
import Combine

/// The user's chosen stops (up to 4), persisted across launches.
@MainActor
final class StopStore: ObservableObject {
    static let shared = StopStore()
    static let maxStops = 4

    @Published private(set) var stops: [Stop]

    private let key = "ptvon.selectedStops.v1"
    private let defaults = UserDefaults.standard

    private init() {
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode([Stop].self, from: data),
           !saved.isEmpty {
            stops = saved
        } else {
            stops = KnownStops.all   // sensible first-run defaults
        }
    }

    var isFull: Bool { stops.count >= Self.maxStops }

    func contains(_ stop: Stop) -> Bool { stops.contains { $0.id == stop.id } }

    @discardableResult
    func add(_ stop: Stop) -> Bool {
        guard !isFull, !contains(stop) else { return false }
        stops.append(stop)
        persist()
        return true
    }

    func remove(_ stop: Stop) {
        stops.removeAll { $0.id == stop.id }
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        stops.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    /// Drag-and-drop reorder: place `dragged` immediately before `target`.
    func move(_ dragged: Stop, before target: Stop) {
        guard dragged.id != target.id else { return }
        var arr = stops
        guard let from = arr.firstIndex(where: { $0.id == dragged.id }) else { return }
        let item = arr.remove(at: from)
        let insertAt = arr.firstIndex(where: { $0.id == target.id }) ?? arr.endIndex
        arr.insert(item, at: insertAt)
        stops = arr
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(stops) {
            defaults.set(data, forKey: key)
        }
    }
}
