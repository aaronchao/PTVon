import SwiftUI

/// The top-section weather: temperature + the animated character, tappable.
struct WeatherHeaderView: View {
    let snapshot: WeatherSnapshot
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(snapshot.tempText)
                        .font(.title2.weight(.bold)).foregroundStyle(.white)
                    Text(snapshot.condition.title(isDay: snapshot.isDay))
                        .font(.caption2).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                    if snapshot.needsUmbrella {
                        Image(systemName: "umbrella.fill")
                            .font(.caption2).foregroundStyle(Color(hex: "5B8CFF"))
                    }
                }
                WeatherCharacter(condition: snapshot.condition,
                                 apparent: snapshot.apparent, isDay: snapshot.isDay)
                    .frame(width: 80, height: 96)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A small, friendly character whose outfit reacts to the weather — umbrella in
/// the rain, coat and beanie when it's cold, sunglasses when it's hot or sunny.
/// Drawn with soft rounded shapes; gentle idle bob.
struct WeatherCharacter: View {
    let condition: WeatherCondition
    let apparent: Double
    let isDay: Bool
    var windy: Bool = false

    @State private var bob = false
    @State private var sway = false
    @State private var gust = false

    private var isRaining: Bool {
        switch condition { case .rain, .drizzle, .thunderstorm: return true; default: return false }
    }
    private var isSnowing: Bool { condition == .snow }
    private var cold: Bool { apparent < 11 }
    private var hot: Bool { apparent >= 26 }
    private var sunnyDay: Bool { condition == .clear && isDay }
    private var wearsShades: Bool { hot || sunnyDay }
    private var wearsWinter: Bool { cold || isSnowing }

    private var coatColor: Color {
        if isRaining { return Color(hex: "FFC83D") }      // yellow raincoat
        if wearsWinter { return Color(hex: "2C5AA8") }    // navy puffer
        if hot { return Color(hex: "FF8A5B") }            // warm tee
        return Color(hex: "5BBDEC")                        // light blue tee/jacket
    }

    var body: some View {
        ZStack {
            if windy { windLines }

            if isRaining {
                umbrella
                    .offset(x: 14, y: -34)
                    .rotationEffect(.degrees(sway ? (windy ? 11 : 4) : (windy ? 3 : -4)), anchor: .bottom)
            }

            VStack(spacing: -6) {
                head
                torso
            }
            .offset(y: bob ? -3 : 3)
            // lean into the wind
            .rotationEffect(.degrees(windy ? (gust ? 5 : 2) : 0), anchor: .bottom)
        }
        .frame(width: 104, height: 124)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { bob = true }
            withAnimation(.easeInOut(duration: windy ? 1.2 : 2.4).repeatForever(autoreverses: true)) { sway = true }
            if windy {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { gust = true }
            }
        }
    }

    private var windLines: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(0..<3) { i in
                Capsule().fill(.white.opacity(0.35))
                    .frame(width: gust ? 26 : 14, height: 2.5)
                    .offset(x: gust ? 8 : -8)
                    .opacity(gust ? 0.1 : 0.5)
            }
        }
        .offset(x: -38, y: -6)
    }

    // MARK: head

    private var head: some View {
        ZStack {
            Circle().fill(Color(hex: "F2C9A0")).frame(width: 50, height: 50)   // face

            // hair / hat
            if wearsWinter {
                Beanie()
            } else {
                Capsule().fill(Color(hex: "3A2E2A"))
                    .frame(width: 52, height: 26).offset(y: -16)
            }

            // eyes / sunglasses
            if wearsShades {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: "23262E")).frame(width: 14, height: 10)
                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: "23262E")).frame(width: 14, height: 10)
                }
                .overlay(Rectangle().fill(Color(hex: "23262E")).frame(width: 6, height: 2))
                .offset(y: -1)
            } else {
                HStack(spacing: 12) {
                    Capsule().fill(Color(hex: "33271F")).frame(width: 4, height: isDay ? 6 : 2)
                    Capsule().fill(Color(hex: "33271F")).frame(width: 4, height: isDay ? 6 : 2)
                }
                .offset(y: -2)
            }

            // smile
            Smile().stroke(Color(hex: "B5663C"), style: .init(lineWidth: 2.4, lineCap: .round))
                .frame(width: 16, height: 8).offset(y: 9)

            // rosy cheeks when cold
            if cold {
                HStack(spacing: 22) {
                    Circle().fill(Color(hex: "FF9D8A").opacity(0.6)).frame(width: 8, height: 8)
                    Circle().fill(Color(hex: "FF9D8A").opacity(0.6)).frame(width: 8, height: 8)
                }
                .offset(y: 6)
            }

            if hot {   // sweat drop
                Drop().fill(Color(hex: "8FD3FF")).frame(width: 7, height: 10).offset(x: 22, y: -4)
            }
        }
        .zIndex(1)
    }

    private var torso: some View {
        ZStack {
            // scarf sits at the neck, behind the body top
            if wearsWinter {
                Capsule().fill(Color(hex: "E8623D")).frame(width: 34, height: 11).offset(y: -3)
            }
            // single soft rounded body (peg shape) — cleaner than stick arms
            UnevenRoundedRectangle(
                topLeadingRadius: 22, bottomLeadingRadius: 14,
                bottomTrailingRadius: 14, topTrailingRadius: 22
            )
            .fill(coatColor)
            .frame(width: 52, height: 44)
            // collar / zip detail
            if wearsWinter || isRaining {
                Capsule().fill(.white.opacity(0.18)).frame(width: 3, height: 26).offset(y: 4)
            }
        }
    }

    private var umbrella: some View {
        ZStack(alignment: .top) {
            Rectangle().fill(Color(hex: "6B7280")).frame(width: 2.4, height: 60).offset(y: 6)
            UmbrellaCanopy()
                .fill(isRaining && condition == .thunderstorm ? Color(hex: "6E5BD0") : Color(hex: "E24B4A"))
                .frame(width: 70, height: 34)
            UmbrellaCanopy().stroke(.white.opacity(0.25), lineWidth: 1).frame(width: 70, height: 34)
        }
        .frame(width: 70, height: 70)
    }
}

// MARK: - Shapes

private struct Beanie: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: "35C07A")).frame(width: 12, height: 12).offset(y: -28)   // pom
            UmbrellaCanopy().fill(Color(hex: "1D9E75")).frame(width: 54, height: 24).offset(y: -16)
            Capsule().fill(Color(hex: "27B083")).frame(width: 54, height: 10).offset(y: -8)    // brim
        }
    }
}

private struct Smile: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.maxY * 1.6))
        return p
    }
}

private struct Drop: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY * 0.75), control: CGPoint(x: r.maxX, y: r.midY))
        p.addArc(center: CGPoint(x: r.midX, y: r.maxY * 0.72), radius: r.width / 2,
                 startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.minX, y: r.midY))
        return p
    }
}

/// A half-dome (flat side down) used for the umbrella canopy and beanie.
struct UmbrellaCanopy: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addArc(center: CGPoint(x: r.midX, y: r.maxY),
                 radius: r.width / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.closeSubpath()
        return p
    }
}
