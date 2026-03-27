import SwiftUI

// MARK: - iOS 26 Liquid Glass Design System
// All cornerRadius, colors, typography, and spacing tokens in one place.

enum Theme {

    // MARK: - Corner Radius (iOS 26 Liquid Glass)
    // Standardised radii — prefer these over hardcoded values.
    enum CornerRadius {
        static let extraSmall: CGFloat = 2   // Subtle bars/dots
        static let small: CGFloat = 4         // Phase bars, rhythm indicators
        static let medium: CGFloat = 10       // Cards, inputs, compact containers
        static let large: CGFloat = 12        // Standard cards, preset cards
        static let extraLarge: CGFloat = 14   // Pattern cards, insight cards
        static let card: CGFloat = 16         // Tier cards, modal sheets
        static let modal: CGFloat = 20        // Dialogs, alerts
        static let sheet: CGFloat = 24        // Bottom sheets, completion cards
        static let capsule: CGFloat = 9999     // Use Capsule() shape directly
    }

    // MARK: - Colors
    enum Colors {
        // Brand palette
        static let cream       = Color(hex: "e8d5c4")
        static let creamMuted  = Color(hex: "c4b5a0")
        static let warmGray    = Color(hex: "a09890")
        static let stone       = Color(hex: "7a7068")
        static let smoke       = Color(hex: "6b6560")
        static let background  = Color(hex: "050508")
        static let card       = Color(hex: "0f0f14")
        static let cardElevated = Color(hex: "141418")
        static let cardHigher  = Color(hex: "1e1e24")
        static let border      = Color(hex: "2a2a30")
        static let gold        = Color(hex: "c4a87a")
        static let borderGold  = Color(hex: "3a3020")

        // Session type orb colors
        static let orbCoreFocus   = Color(hex: "e8d5c4")
        static let orbCoreSleep    = Color(hex: "a0b8d8")
        static let orbCoreRelax    = Color(hex: "c8b8a0")
        static let orbCoreWakeUp   = Color(hex: "e8c890")
    }

    // MARK: - Typography — iOS 26 minimum 11pt body text
    enum Typography {
        // All body/label text minimum 11pt per iOS 26 Liquid Glass HIG
        static let caption2: Font = .system(size: 11, weight: .regular)        // 11pt minimum
        static let caption:   Font = .system(size: 12, weight: .regular)
        static let footnote:  Font = .system(size: 13, weight: .regular)
        static let subheadline: Font = .system(size: 14, weight: .regular)
        static let callout:   Font = .system(size: 16, weight: .regular)

        // Semantic labels
        static let sectionHeader: Font = .system(size: 12, weight: .medium)
        static let secondaryLabel: Font = .system(size: 11, weight: .medium)   // 11pt minimum
        static let tertiaryLabel: Font = .system(size: 11, weight: .regular)    // 11pt minimum

        // Headings
        static let headline:  Font = .system(size: 17, weight: .medium, design: .rounded)
        static let title3:    Font = .system(size: 20, weight: .light, design: .rounded)
        static let title2:    Font = .system(size: 22, weight: .light, design: .rounded)
        static let title1:   Font = .system(size: 28, weight: .ultraLight, design: .rounded)
        static let largeTitle: Font = .system(size: 34, weight: .ultraLight, design: .rounded)

        // Display
        static let display2: Font = .system(size: 40, weight: .ultraLight, design: .rounded)
        static let display1: Font = .system(size: 52, weight: .ultraLight, design: .rounded)
        static let timer:    Font = .system(size: 72, weight: .light, design: .rounded)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs:  CGFloat = 4
        static let xs:   CGFloat = 6
        static let sm:   CGFloat = 8
        static let md:   CGFloat = 12
        static let lg:   CGFloat = 14
        static let xl:   CGFloat = 16
        static let xxl:  CGFloat = 20
        static let xxxl: CGFloat = 24
        static let xxxxl: CGFloat = 32
    }

    // MARK: - Shadows
    enum Shadow {
        static let card = Color.black.opacity(0.3)
        static let glow = Color.black.opacity(0.15)
    }
}

// MARK: - Font Extension Helpers
// Ensure no font falls below 11pt (iOS 26 requirement).
extension Font {
    /// Wraps a font size, enforcing the 11pt minimum for body text.
    static func bodyText(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: max(11, size), weight: weight)
    }

    /// Wraps a font size for labels/captions, enforcing the 11pt minimum.
    static func label(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: max(11, size), weight: weight)
    }
}

// MARK: - View Extension for Consistent Card Styling
extension View {
    func cardStyle(
        cornerRadius: CGFloat = Theme.CornerRadius.large,
        backgroundColor: Color = Theme.Colors.cardElevated,
        borderColor: Color = Theme.Colors.border
    ) -> some View {
        self
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor.opacity(0.5), lineWidth: 0.5)
            )
    }

    func liquidGlassButton() -> some View {
        self
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Theme.Colors.background)
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.vertical, Theme.Spacing.lg)
            .background(Theme.Colors.cream, in: Capsule())
    }

    func ghostButton() -> some View {
        self
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Theme.Colors.smoke)
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.vertical, Theme.Spacing.lg)
            .background(Theme.Colors.cardHigher, in: Capsule())
    }
}
