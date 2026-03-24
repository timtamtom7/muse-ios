import SwiftUI

struct WatchOrbView: View {
    let phase: WatchBreathPhase
    let progress: Double
    var sessionType: WatchSessionType = .focus

    private var orbScale: CGFloat {
        switch phase {
        case .idle: return 0.3
        case .inhale: return 0.3 + (0.7 * progress)
        case .holdIn: return 1.0
        case .exhale: return 1.0 - (0.7 * progress)
        case .holdOut: return 0.3
        case .complete: return 0.5
        }
    }

    private var glowOpacity: Double {
        switch phase {
        case .idle: return 0.3
        case .inhale: return 0.3 + (0.7 * progress) * 0.8
        case .holdIn: return 1.0
        case .exhale: return 1.0 - (0.7 * progress) * 0.7
        case .holdOut: return 0.3
        case .complete: return 0.6
        }
    }

    private var coreColor: Color { Color(hex: sessionType.orbCoreColor) }
    private var haloColor: Color { Color(hex: sessionType.orbCoreColor).opacity(0.6) }

    var body: some View {
        ZStack {
            // Outer halo
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: haloColor.opacity(glowOpacity * 0.1), location: 0.0),
                            .init(color: haloColor.opacity(0.0), location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 45 * orbScale
                    )
                )
                .frame(width: 90, height: 90)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: coreColor.opacity(glowOpacity * 0.5), location: 0.0),
                            .init(color: coreColor.opacity(glowOpacity * 0.2), location: 0.6),
                            .init(color: coreColor.opacity(0.0), location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 35 * orbScale
                    )
                )
                .frame(width: 70, height: 70)

            // Core
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: coreColor.opacity(glowOpacity), location: 0.0),
                            .init(color: coreColor.opacity(glowOpacity * 0.7), location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 20 * orbScale
                    )
                )
                .frame(width: 40, height: 40)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

#Preview("Watch Orb - Focus") {
    ZStack {
        Color(hex: "050508").ignoresSafeArea()
        WatchOrbView(phase: .inhale, progress: 0.5, sessionType: .focus)
    }
}
