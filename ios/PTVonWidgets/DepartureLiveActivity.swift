import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Helpers

/// Live, OS-driven countdown to the departure — ticks without the app running.
private struct CountdownText: View {
    let state: DepartureAttributes.ContentState
    var body: some View {
        Text(timerInterval: clampedRange(state), countsDown: true)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}

private func clampedRange(_ state: DepartureAttributes.ContentState) -> ClosedRange<Date> {
    let end = state.departureDate
    let start = min(state.startDate, end.addingTimeInterval(-1))
    return start...end
}

private func clock(_ date: Date) -> String {
    date.formatted(.dateTime.hour().minute())
}

/// A small pill, e.g. the route badge or "Plat 3".
private struct Pill<Content: View>: View {
    var fill: Color
    var textColor: Color = .white
    @ViewBuilder var content: Content
    var body: some View {
        content
            .font(.caption2.weight(.bold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(fill, in: Capsule())
    }
}

private struct LiveStatus: View {
    let state: DepartureAttributes.ContentState
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(state.isLive ? .green : .orange)
                .frame(width: 6, height: 6)
            Text(state.status)
        }
    }
}

// MARK: - Lock Screen / banner

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<DepartureAttributes>
    private var color: Color { Color(hex: context.attributes.modeColorHex) }
    private var state: DepartureAttributes.ContentState { context.state }

    var body: some View {
        VStack(spacing: 11) {
            // Top: mode + route + destination ............ countdown
            HStack(alignment: .top, spacing: 13) {
                ZStack {
                    Circle().fill(color.opacity(0.22))
                    Image(systemName: context.attributes.modeSymbol)
                        .font(.title3).foregroundStyle(color)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Pill(fill: color) { Text(context.attributes.routeLabel) }
                        if let platform = state.platform, !platform.isEmpty {
                            Pill(fill: color.opacity(0.18), textColor: color) {
                                Text("Plat \(platform)")
                            }
                        }
                    }
                    Text(context.attributes.destination)
                        .font(.headline).lineLimit(1).foregroundStyle(.white)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 0) {
                    CountdownText(state: state)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text("to go").font(.caption2).foregroundStyle(.secondary)
                }
            }

            ProgressView(timerInterval: clampedRange(state), countsDown: true) {
                EmptyView()
            } currentValueLabel: { EmptyView() }
                .tint(color)

            // Bottom: from-stop + status ............ departs + then
            HStack(spacing: 8) {
                Label("from \(context.attributes.stopName)", systemImage: "mappin.and.ellipse")
                    .lineLimit(1)
                LiveStatus(state: state)
                Spacer(minLength: 4)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(clock(state.departureDate))
                    if let next = state.nextDepartureDate {
                        Text("· then \(clock(next))").foregroundStyle(.tertiary)
                    }
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(15)
    }
}

// MARK: - Widget (Lock Screen + Dynamic Island)

struct DepartureLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DepartureAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.5))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let color = Color(hex: context.attributes.modeColorHex)
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 7) {
                        ZStack {
                            Circle().fill(color.opacity(0.22))
                            Image(systemName: context.attributes.modeSymbol)
                                .font(.footnote).foregroundStyle(color)
                        }
                        .frame(width: 30, height: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(context.attributes.routeLabel)
                                .font(.subheadline.weight(.bold)).lineLimit(1)
                            Text(context.attributes.modeName)
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        CountdownText(state: state)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(color)
                            .frame(maxWidth: 78)
                        Text("to go").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 6) {
                        Text(context.attributes.destination)
                            .font(.subheadline.weight(.semibold)).lineLimit(1)
                        if let platform = state.platform, !platform.isEmpty {
                            Pill(fill: color.opacity(0.20), textColor: color) {
                                Text("Plat \(platform)")
                            }
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ProgressView(timerInterval: clampedRange(state), countsDown: true) {
                            EmptyView()
                        } currentValueLabel: { EmptyView() }
                            .tint(color)
                        HStack {
                            Label("from \(context.attributes.stopName)", systemImage: "mappin.and.ellipse")
                                .lineLimit(1)
                            Spacer()
                            LiveStatus(state: state)
                            Text("· \(clock(state.departureDate))")
                        }
                        .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.attributes.modeSymbol)
                    .foregroundStyle(color)
            } compactTrailing: {
                CountdownText(state: state)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(color)
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: context.attributes.modeSymbol)
                    .foregroundStyle(color)
            }
            .keylineTint(color)
        }
    }
}
