import SwiftUI
import UIKit

/// Adaptive colours that flip between day (light) and night (dark) automatically,
/// so the dashboard stays legible in bright sun and at night.
extension Color {
    static let pText = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor.white : UIColor(white: 0.08, alpha: 1) })
    static let pSecondary = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.62) : UIColor(white: 0.10, alpha: 0.62) })
    static let pTertiary = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.40) : UIColor(white: 0.10, alpha: 0.42) })
    static let pHairline = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.08) : UIColor(white: 0, alpha: 0.10) })
    /// Subtle fill behind glass cards in light mode (clear in dark — glass shows).
    static let pCardTint = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.0) : UIColor(white: 1, alpha: 0.55) })
}

/// Lets the `.foregroundStyle(.pText)` shorthand resolve to our adaptive colours.
extension ShapeStyle where Self == Color {
    static var pText: Color { .pText }
    static var pSecondary: Color { .pSecondary }
    static var pTertiary: Color { .pTertiary }
    static var pHairline: Color { .pHairline }
    static var pCardTint: Color { .pCardTint }
}

/// User's appearance preference, cycled from the toolbar.
enum Appearance: String, CaseIterable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
    var next: Appearance {
        switch self {
        case .system: return .light
        case .light:  return .dark
        case .dark:   return .system
        }
    }
}
