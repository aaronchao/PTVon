import SwiftUI

/// Drives the disruptions sheet for one stop.
struct DisruptionContext: Identifiable {
    let id = UUID()
    let stopName: String
    let items: [Disruption]
}

struct DisruptionsSheet: View {
    let context: DisruptionContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(context.items) { d in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Image(systemName: d.symbol)
                                .foregroundStyle(d.isPlanned ? .orange : .yellow)
                            Text(d.type.isEmpty ? "Disruption" : d.type)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        Text(d.title).font(.callout.weight(.semibold))
                        if !d.description.isEmpty, d.description != d.title {
                            Text(d.description).font(.footnote).foregroundStyle(.secondary)
                        }
                        if let urlString = d.url, let url = URL(string: urlString) {
                            Link(destination: url) {
                                Label("More on PTV", systemImage: "arrow.up.right.square")
                                    .font(.caption)
                            }
                            .padding(.top, 1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(context.stopName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .tint(Color(hex: "5B8CFF"))
    }
}
