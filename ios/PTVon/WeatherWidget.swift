import SwiftUI

/// Compact weather readout that sits beside the wordmark. Tap for full detail.
struct WeatherChip: View {
    let snapshot: WeatherSnapshot
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: snapshot.condition.symbol(isDay: snapshot.isDay))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 17))
                Text(snapshot.tempText)
                    .font(.title3.weight(.semibold)).foregroundStyle(.white)
                if snapshot.needsUmbrella {
                    Image(systemName: "umbrella.fill")
                        .font(.caption).foregroundStyle(Color(hex: "5B8CFF"))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Full weather detail, shown as a sheet from the chip — keeps the rich scene,
/// RealFeel, what-to-wear and umbrella advice, and the hourly strip.
struct WeatherDetailSheet: View {
    let snapshot: WeatherSnapshot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(.white.opacity(0.3)).frame(width: 38, height: 5).padding(.top, 10)

            WeatherScene(condition: snapshot.condition, isDay: snapshot.isDay)
                .frame(width: 110, height: 110)

            VStack(spacing: 2) {
                Text(snapshot.tempText)
                    .font(.system(size: 60, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(snapshot.condition.title(isDay: snapshot.isDay))
                    .font(.headline).foregroundStyle(.white)
                Text("\(snapshot.feelsText)  ·  \(snapshot.placeName)")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: 8) {
                AdvicePill(icon: snapshot.needsUmbrella ? "umbrella.fill" : "umbrella",
                           text: snapshot.umbrellaAdvice,
                           tint: snapshot.needsUmbrella ? Color(hex: "5B8CFF") : .white.opacity(0.7))
                AdvicePill(icon: snapshot.clothingSymbol,
                           text: snapshot.clothingAdvice, tint: .white.opacity(0.7))
            }
            .padding(.horizontal, 20)

            if !snapshot.hourly.isEmpty {
                HStack(spacing: 0) {
                    ForEach(snapshot.hourly) { hour in
                        VStack(spacing: 6) {
                            Text(hour.date, format: .dateTime.hour())
                                .font(.caption2).foregroundStyle(.white.opacity(0.55))
                            Image(systemName: hour.condition.symbol(isDay: snapshot.isDay))
                                .symbolRenderingMode(.multicolor).font(.system(size: 16)).frame(height: 20)
                            Text("\(Int(hour.temperature.rounded()))°")
                                .font(.caption.weight(.medium)).foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(WeatherBackground(condition: snapshot.condition, isDay: snapshot.isDay))
        .presentationDetents([.medium])
        .presentationBackground(.clear)
    }
}

/// The restored richer weather card: temperature + RealFeel + the animated
/// character as the hero, plus umbrella/clothing advice and the hourly strip.
struct WeatherCard: View {
    let snapshot: WeatherSnapshot
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.tempText)
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(snapshot.condition.title(isDay: snapshot.isDay))
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Text(snapshot.feelsText)
                        if snapshot.isWindy {
                            HStack(spacing: 3) {
                                Image(systemName: "wind"); Text(snapshot.windText)
                            }
                            .foregroundStyle(Color(hex: "9FD0FF"))
                        }
                    }
                    .font(.caption).foregroundStyle(.white.opacity(0.65))
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill").font(.system(size: 9))
                        Text(snapshot.placeName)
                    }
                    .font(.caption2).foregroundStyle(.white.opacity(0.5)).padding(.top, 1)
                }
                Spacer(minLength: 4)
                WeatherCharacter(condition: snapshot.condition, apparent: snapshot.apparent,
                                 isDay: snapshot.isDay, windy: snapshot.isWindy)
                    .frame(width: 92, height: 108)
            }

            HStack(spacing: 8) {
                AdvicePill(icon: snapshot.needsUmbrella ? "umbrella.fill" : "umbrella",
                           text: snapshot.umbrellaAdvice,
                           tint: snapshot.needsUmbrella ? Color(hex: "5B8CFF") : .white.opacity(0.7))
                AdvicePill(icon: snapshot.clothingSymbol,
                           text: snapshot.clothingAdvice, tint: .white.opacity(0.7))
            }

            if !snapshot.hourly.isEmpty {
                HStack(spacing: 0) {
                    ForEach(snapshot.hourly) { hour in
                        VStack(spacing: 5) {
                            Text(hour.date, format: .dateTime.hour())
                                .font(.caption2).foregroundStyle(.white.opacity(0.55))
                            Image(systemName: hour.condition.symbol(isDay: snapshot.isDay))
                                .symbolRenderingMode(.multicolor).font(.system(size: 15)).frame(height: 18)
                            Text("\(Int(hour.temperature.rounded()))°")
                                .font(.caption.weight(.medium)).foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

private struct AdvicePill: View {
    let icon: String
    let text: String
    let tint: Color
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundStyle(tint)
            Text(text).font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.9))
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 11).padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.10), in: Capsule())
    }
}

// MARK: - Animated scene

struct WeatherScene: View {
    let condition: WeatherCondition
    let isDay: Bool

    var body: some View {
        ZStack {
            switch condition {
            case .clear:
                if isDay { SunView() } else { MoonView() }
            case .partlyCloudy:
                if isDay { SunView().scaleEffect(0.7).offset(x: -10, y: -10) }
                else { MoonView().scaleEffect(0.7).offset(x: -10, y: -10) }
                CloudView(tint: .white).offset(x: 8, y: 10)
            case .cloudy:
                CloudView(tint: .white).offset(x: -6)
                CloudView(tint: .white.opacity(0.7)).scaleEffect(0.8).offset(x: 12, y: 14)
            case .fog:
                CloudView(tint: .white.opacity(0.85))
                FogView().offset(y: 18)
            case .drizzle, .rain:
                CloudView(tint: .white.opacity(0.9)).offset(y: -8)
                PrecipView(isSnow: false, count: condition == .rain ? 7 : 4)
            case .snow:
                CloudView(tint: .white.opacity(0.9)).offset(y: -8)
                PrecipView(isSnow: true, count: 7)
            case .thunderstorm:
                CloudView(tint: Color(hex: "C7CEDA")).offset(y: -8)
                PrecipView(isSnow: false, count: 5)
                BoltView()
            }
        }
    }
}

private struct SunView: View {
    @State private var spin = false
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Capsule()
                    .fill(Color(hex: "FFCB52"))
                    .frame(width: 3.5, height: 11)
                    .offset(y: -25)
                    .rotationEffect(.degrees(Double(i) / 8 * 360))
            }
            .rotationEffect(.degrees(spin ? 360 : 0))
            Circle()
                .fill(Color(hex: "FFD66B"))
                .frame(width: 34, height: 34)
                .overlay(Circle().fill(Color(hex: "FFE39A")).frame(width: 22, height: 22))
        }
        .onAppear {
            withAnimation(.linear(duration: 22).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}

private struct MoonView: View {
    @State private var twinkle = false
    var body: some View {
        ZStack {
            ZStack {
                Circle().fill(Color(hex: "E7ECFF")).frame(width: 34, height: 34)
                Circle().fill(Color(hex: "13204A")).frame(width: 28, height: 28).offset(x: 9, y: -7)
            }
            ForEach(0..<3) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: [9.0, 7.0, 6.0][i]))
                    .foregroundStyle(.white)
                    .opacity(twinkle ? 0.9 : 0.3)
                    .offset(x: [20.0, -22.0, 14.0][i], y: [-20.0, 12.0, 22.0][i])
                    .animation(.easeInOut(duration: 1.3).repeatForever().delay(Double(i) * 0.4), value: twinkle)
            }
        }
        .onAppear { twinkle = true }
    }
}

private struct CloudView: View {
    let tint: Color
    @State private var drift = false
    var body: some View {
        Image(systemName: "cloud.fill")
            .font(.system(size: 38))
            .foregroundStyle(tint)
            .offset(x: drift ? 4 : -4)
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { drift = true }
            }
    }
}

private struct PrecipView: View {
    let isSnow: Bool
    let count: Int
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                FallingParticle(
                    isSnow: isSnow,
                    delay: Double(i) * (isSnow ? 0.28 : 0.13),
                    xOffset: CGFloat(i - count / 2) * 7
                )
            }
        }
        .offset(y: 14)
    }
}

private struct FallingParticle: View {
    let isSnow: Bool
    let delay: Double
    let xOffset: CGFloat
    @State private var fall = false
    var body: some View {
        Group {
            if isSnow {
                Circle().fill(.white).frame(width: 4, height: 4)
            } else {
                Capsule().fill(Color(hex: "9CC0FF")).frame(width: 2.2, height: 9)
            }
        }
        .offset(x: xOffset, y: fall ? 20 : -16)
        .opacity(fall ? 0 : 1)
        .onAppear {
            withAnimation(.easeIn(duration: isSnow ? 2.2 : 0.9)
                .repeatForever(autoreverses: false).delay(delay)) { fall = true }
        }
    }
}

private struct FogView: View {
    @State private var slide = false
    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<3) { i in
                Capsule().fill(.white.opacity(0.45))
                    .frame(width: 40, height: 3)
                    .offset(x: slide ? CGFloat(6 - i * 4) : CGFloat(-6 + i * 4))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { slide = true }
        }
    }
}

private struct BoltView: View {
    @State private var flash = false
    var body: some View {
        Image(systemName: "bolt.fill")
            .font(.system(size: 20))
            .foregroundStyle(Color(hex: "FFD23E"))
            .opacity(flash ? 1 : 0.15)
            .offset(y: 16)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.6)) {
                    flash = true
                }
            }
    }
}
