import SwiftUI

/// The whole-screen ambient backdrop. A light "day" sky or dark "night" base,
/// plus the animated weather layer (rain, snow, sun glow, stars, wind) blended
/// behind the glass cards — the weather is *felt*, not boxed in a card.
struct WeatherBackground: View {
    let condition: WeatherCondition?
    let isDay: Bool
    var windy: Bool = false

    @Environment(\.colorScheme) private var scheme
    private var dark: Bool { scheme == .dark }

    var body: some View {
        ZStack {
            base
            Blobs(accent: accent, dim: dark ? 1.0 : 0.55)
            overlay
            if windy {
                WindLayer(tint: dark ? Color.white.opacity(0.10) : Color(hex: "2C5AA8").opacity(0.12))
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder private var base: some View {
        if dark {
            Color(hex: "0A1020")
        } else {
            LinearGradient(colors: [Color(hex: "CDE0FA"), Color(hex: "ECF3FD")],
                           startPoint: .top, endPoint: .bottom)
        }
    }

    private var accent: (Color, Color, Color) {
        switch condition {
        case .clear where isDay: return (Color(hex: "3F7BFF"), Color(hex: "FFB23E"), Color(hex: "35C07A"))
        case .clear:             return (Color(hex: "2A3A86"), Color(hex: "6E5BD0"), Color(hex: "1C2A66"))
        case .rain, .drizzle, .thunderstorm:
                                 return (Color(hex: "2C5AA8"), Color(hex: "3F7BFF"), Color(hex: "203a72"))
        case .snow:              return (Color(hex: "4A6FB5"), Color(hex: "9FB6E8"), Color(hex: "2C3E6E"))
        default:                 return (Color(hex: "3F7BFF"), Color(hex: "A06CFF"), Color(hex: "35C07A"))
        }
    }

    @ViewBuilder private var overlay: some View {
        let rainTint = dark ? Color.white.opacity(0.16) : Color(hex: "3F6FCB").opacity(0.32)
        let snowTint = dark ? Color.white.opacity(0.5) : Color(hex: "7E97C6").opacity(0.8)
        switch condition {
        case .rain, .drizzle:
            RainLayer(count: condition == .rain ? 22 : 13, tint: rainTint)
        case .thunderstorm:
            ZStack { RainLayer(count: 20, tint: rainTint); LightningLayer() }
        case .snow:
            SnowLayer(count: 26, tint: snowTint)
        case .clear:
            isDay ? AnyView(SunGlow(strong: !dark)) : AnyView(StarLayer(dark: dark))
        default:
            EmptyView()
        }
    }
}

private struct Blobs: View {
    let accent: (Color, Color, Color)
    let dim: Double
    @State private var animate = false
    var body: some View {
        ZStack {
            blob(accent.0, size: 440, opacity: 0.40 * dim, from: CGSize(width: 130, height: -220), to: CGSize(width: -120, height: -120))
            blob(accent.1, size: 380, opacity: 0.28 * dim, from: CGSize(width: -130, height: 120), to: CGSize(width: 150, height: 240))
            blob(accent.2, size: 340, opacity: 0.20 * dim, from: CGSize(width: 110, height: 380), to: CGSize(width: -90, height: 480))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) { animate = true }
        }
    }
    private func blob(_ c: Color, size: CGFloat, opacity: Double, from: CGSize, to: CGSize) -> some View {
        Circle().fill(c).frame(width: size, height: size).blur(radius: 100)
            .opacity(opacity).offset(animate ? to : from)
    }
}

// MARK: - Rain

private struct RainLayer: View {
    let count: Int
    let tint: Color
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let f = Double((i * 53) % 100) / 100.0
                    RainStreak(
                        x: geo.size.width * CGFloat(f),
                        travel: geo.size.height,
                        length: CGFloat(14 + (i % 4) * 6),
                        duration: 0.75 + Double((i * 7) % 5) * 0.12,
                        delay: Double((i * 13) % 10) * 0.12,
                        tint: tint
                    )
                }
            }
        }
    }
}

private struct RainStreak: View {
    let x: CGFloat; let travel: CGFloat; let length: CGFloat
    let duration: Double; let delay: Double; let tint: Color
    @State private var fall = false
    var body: some View {
        Capsule().fill(tint)
            .frame(width: 1.5, height: length)
            .position(x: x, y: fall ? travel + length : -length)
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false).delay(delay)) {
                    fall = true
                }
            }
    }
}

// MARK: - Snow

private struct SnowLayer: View {
    let count: Int
    let tint: Color
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let f = Double((i * 47) % 100) / 100.0
                    SnowFlake(
                        x: geo.size.width * CGFloat(f),
                        travel: geo.size.height,
                        size: CGFloat(3 + (i % 3)),
                        duration: 4.0 + Double((i * 11) % 6) * 0.5,
                        delay: Double((i * 17) % 12) * 0.4,
                        tint: tint
                    )
                }
            }
        }
    }
}

private struct SnowFlake: View {
    let x: CGFloat; let travel: CGFloat; let size: CGFloat
    let duration: Double; let delay: Double; let tint: Color
    @State private var fall = false
    var body: some View {
        Circle().fill(tint)
            .frame(width: size, height: size)
            .position(x: x + (fall ? 10 : -10), y: fall ? travel + size : -size)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: false).delay(delay)) {
                    fall = true
                }
            }
    }
}

// MARK: - Sun glow / stars / wind / lightning

private struct SunGlow: View {
    let strong: Bool
    @State private var pulse = false
    var body: some View {
        Circle()
            .fill(Color(hex: "FFCB52"))
            .frame(width: 260, height: 260)
            .blur(radius: 90)
            .opacity(pulse ? (strong ? 0.5 : 0.30) : (strong ? 0.34 : 0.18))
            .offset(x: 120, y: -260)
            .onAppear {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) { pulse = true }
            }
    }
}

private struct StarLayer: View {
    let dark: Bool
    @State private var twinkle = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<24, id: \.self) { i in
                    let fx = Double((i * 37) % 100) / 100.0
                    let fy = Double((i * 61) % 100) / 100.0
                    Circle().fill(dark ? Color.white : Color(hex: "4A6FB5"))
                        .frame(width: CGFloat(1 + i % 2), height: CGFloat(1 + i % 2))
                        .position(x: geo.size.width * CGFloat(fx), y: geo.size.height * CGFloat(fy) * 0.7)
                        .opacity(twinkle ? 0.8 : 0.2)
                        .animation(.easeInOut(duration: 1.6).repeatForever().delay(Double(i % 5) * 0.3), value: twinkle)
                }
            }
        }
        .onAppear { twinkle = true }
    }
}

private struct WindLayer: View {
    let tint: Color
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<10, id: \.self) { i in
                    let fy = Double((i * 41) % 100) / 100.0
                    WindStreak(
                        y: geo.size.height * CGFloat(fy),
                        width: geo.size.width,
                        length: CGFloat(40 + (i % 3) * 30),
                        duration: 1.6 + Double((i * 7) % 4) * 0.4,
                        delay: Double((i * 5) % 8) * 0.3,
                        tint: tint
                    )
                }
            }
        }
    }
}

private struct WindStreak: View {
    let y: CGFloat; let width: CGFloat; let length: CGFloat
    let duration: Double; let delay: Double; let tint: Color
    @State private var blow = false
    var body: some View {
        Capsule().fill(tint)
            .frame(width: length, height: 2)
            .position(x: blow ? width + length : -length, y: y)
            .onAppear {
                withAnimation(.easeIn(duration: duration).repeatForever(autoreverses: false).delay(delay)) {
                    blow = true
                }
            }
    }
}

private struct LightningLayer: View {
    @State private var flash = false
    var body: some View {
        Color.white
            .opacity(flash ? 0.10 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true).delay(2.4)) {
                    flash = true
                }
            }
    }
}
