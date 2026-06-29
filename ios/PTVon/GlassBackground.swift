import SwiftUI

/// Liquid Glass card on iOS 26, frosted material on earlier systems.
extension View {
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 24, tint: Color = .clear) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.pHairline, lineWidth: 1)
                )
        }
    }
}

/// Soft, slowly drifting colour blobs behind the glass — calm and alive.
struct AuroraBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(hex: "0A1020")
            blob(Color(hex: "3F7BFF"), size: 440, opacity: 0.42,
                 from: CGSize(width: 130, height: -220), to: CGSize(width: -120, height: -120))
            blob(Color(hex: "A06CFF"), size: 380, opacity: 0.30,
                 from: CGSize(width: -130, height: 120), to: CGSize(width: 150, height: 240))
            blob(Color(hex: "35C07A"), size: 340, opacity: 0.22,
                 from: CGSize(width: 110, height: 380), to: CGSize(width: -90, height: 480))
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private func blob(_ color: Color, size: CGFloat, opacity: Double,
                      from: CGSize, to: CGSize) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 100)
            .opacity(opacity)
            .offset(animate ? to : from)
    }
}

/// A small "live" dot that gently pulses.
struct PulsingDot: View {
    var color: Color = .green
    var size: CGFloat = 7
    @State private var on = false
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle().stroke(color, lineWidth: 1)
                    .scaleEffect(on ? 2.4 : 1)
                    .opacity(on ? 0 : 0.7)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    on = true
                }
            }
    }
}
