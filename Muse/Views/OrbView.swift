import SwiftUI

struct OrbView: View {
    let phase: BreathPhase
    let phaseProgress: Double
    var sessionType: SessionType = .focus

    private let minCoreSize: CGFloat = 80
    private let maxCoreSize: CGFloat = 240

    private var orbScale: CGFloat {
        switch phase {
        case .idle:
            return 0.3
        case .inhale:
            return 0.3 + (0.7 * phaseProgress)
        case .holdIn:
            return 1.0
        case .exhale:
            return 1.0 - (0.7 * phaseProgress)
        case .holdOut:
            return 0.3
        case .complete:
            return 0.5
        }
    }

    private var glowOpacity: Double {
        switch phase {
        case .idle:
            return 0.3
        case .inhale:
            return 0.3 + (0.7 * phaseProgress) * 0.8
        case .holdIn:
            return 1.0
        case .exhale:
            return 1.0 - (0.7 * phaseProgress) * 0.7
        case .holdOut:
            return 0.3
        case .complete:
            return 0.6
        }
    }

    private var haloScale: CGFloat {
        orbScale * 1.18
    }

    private var coreColor: Color { Color(hex: sessionType.orbCoreColor) }
    private var glowColor: Color { Color(hex: sessionType.orbGlowColor) }
    private var haloColor: Color { Color(hex: sessionType.orbHaloColor) }
    private var highlightColor: Color { Color(hex: sessionType.orbHighlightColor) }

    var body: some View {
        GeometryReader { geometry in
            let maxDim = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Layer 1: Outer halo — largest, softest
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: haloColor.opacity(glowOpacity * 0.06), location: 0.0),
                                .init(color: haloColor.opacity(glowOpacity * 0.03), location: 0.4),
                                .init(color: haloColor.opacity(0.0), location: 1.0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: maxDim * 0.45 * haloScale
                        )
                    )
                    .frame(width: maxDim * 0.9 * haloScale, height: maxDim * 0.9 * haloScale)

                // Layer 2: Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: glowColor.opacity(glowOpacity * 0.3), location: 0.0),
                                .init(color: glowColor.opacity(glowOpacity * 0.15), location: 0.5),
                                .init(color: glowColor.opacity(0.0), location: 1.0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: maxDim * 0.35 * orbScale
                        )
                    )
                    .frame(width: maxDim * 0.7 * orbScale, height: maxDim * 0.7 * orbScale)

                // Layer 3: Core
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: highlightColor.opacity(glowOpacity), location: 0.0),
                                .init(color: coreColor.opacity(glowOpacity * 0.9), location: 0.4),
                                .init(color: glowColor.opacity(glowOpacity * 0.7), location: 1.0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: maxDim * 0.22 * orbScale
                        )
                    )
                    .frame(width: maxDim * 0.44 * orbScale, height: maxDim * 0.44 * orbScale)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
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

#Preview("Focus") {
    ZStack {
        Color(hex: "050508").ignoresSafeArea()
        OrbView(phase: .inhale, phaseProgress: 0.5, sessionType: .focus)
            .frame(width: 300, height: 300)
    }
}

#Preview("Sleep") {
    ZStack {
        Color(hex: "03040a").ignoresSafeArea()
        OrbView(phase: .holdIn, phaseProgress: 1.0, sessionType: .sleep)
            .frame(width: 300, height: 300)
    }
}

#Preview("Relax") {
    ZStack {
        Color(hex: "080706").ignoresSafeArea()
        OrbView(phase: .exhale, phaseProgress: 0.5, sessionType: .relax)
            .frame(width: 300, height: 300)
    }
}

#Preview("Wake Up") {
    ZStack {
        Color(hex: "0a0805").ignoresSafeArea()
        OrbView(phase: .inhale, phaseProgress: 0.8, sessionType: .wakeUp)
            .frame(width: 300, height: 300)
    }
}
