import SwiftUI

/// Animated timeline showing the four phases of a breathing pattern
struct BreathingPatternVisualizerView: View {
    let pattern: BreathingPattern
    let isActive: Bool
    let currentPhase: BreathPhase
    let phaseProgress: Double

    @State private var animationPhase: BreathPhase = .idle
    @State private var animProgress: Double = 0

    private let totalHeight: CGFloat = 80

    private var totalCycle: Double {
        pattern.totalCycleDuration
    }

    private var phaseWidths: [Double] {
        let total = max(totalCycle, 1)
        return [
            pattern.inhaleSeconds / total,
            pattern.holdInSeconds / total,
            pattern.exhaleSeconds / total,
            pattern.holdOutSeconds / total
        ]
    }

    private var phases: [(name: String, color: Color, isHold: Bool)] {
        [
            ("Inhale", Color(hex: "e8d5c4"), false),
            ("Hold", Color(hex: "c4b5a0"), true),
            ("Exhale", Color(hex: "a09890"), false),
            ("Hold", Color(hex: "7a7068"), true)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Phase labels
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { i in
                        if phaseWidths[i] > 0 {
                            Text(phases[i].name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(phases[i].color.opacity(0.7))
                                .frame(width: max(20, CGFloat(phaseWidths[i]) * (geo.size.width - 8)), alignment: .leading)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(height: 16)
            .padding(.horizontal, 4)

            // Timeline bar
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { i in
                        if phaseWidths[i] > 0 {
                            let isCurrentPhase = isActive && currentPhase == phaseForIndex(i)
                            let progress = isCurrentPhase ? phaseProgress : 0.0

                            RoundedRectangle(cornerRadius: 4)
                                .fill(phases[i].color.opacity(isCurrentPhase ? 0.3 : 0.15))
                                .frame(width: max(4, CGFloat(phaseWidths[i]) * totalWidth - 2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(phases[i].color.opacity(isCurrentPhase ? 0.8 : 0.0))
                                        .frame(width: max(4, CGFloat(phaseWidths[i]) * totalWidth - 2))
                                        .mask(
                                            HStack(spacing: 0) {
                                                Rectangle()
                                                    .frame(width: max(4, CGFloat(phaseWidths[i]) * totalWidth * CGFloat(progress) - 2))
                                                Spacer(minLength: 0)
                                            }
                                        )
                                )
                        }
                    }
                }
                .frame(height: 24)
            }
            .frame(height: 24)

            // Duration labels
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { i in
                        if phaseWidths[i] > 0 {
                            Text(phaseDurationLabel(i))
                                .font(.system(size: 9, weight: .light))
                                .foregroundStyle(phases[i].color.opacity(0.5))
                                .frame(width: max(20, CGFloat(phaseWidths[i]) * (geo.size.width - 8)), alignment: .leading)
                        }
                    }
                }
            }
            .frame(height: 14)
            .padding(.horizontal, 4)
        }
    }

    private func phaseForIndex(_ index: Int) -> BreathPhase {
        switch index {
        case 0: return .inhale
        case 1: return .holdIn
        case 2: return .exhale
        case 3: return .holdOut
        default: return .idle
        }
    }

    private func phaseDurationLabel(_ index: Int) -> String {
        switch index {
        case 0: return "\(Int(pattern.inhaleSeconds))s"
        case 1: return pattern.holdInSeconds > 0 ? "\(Int(pattern.holdInSeconds))s" : "skip"
        case 2: return "\(Int(pattern.exhaleSeconds))s"
        case 3: return pattern.holdOutSeconds > 0 ? "\(Int(pattern.holdOutSeconds))s" : "skip"
        default: return ""
        }
    }
}

/// Preview card for a breathing pattern preset
struct PatternPresetCard: View {
    let pattern: BreathingPattern
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(pattern.name)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "e8d5c4"))

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "e8d5c4"))
                    }
                }

                // Mini visualizer
                HStack(spacing: 2) {
                    phaseBar(phase: .inhale, duration: pattern.inhaleSeconds)
                    phaseBar(phase: .holdIn, duration: pattern.holdInSeconds)
                    phaseBar(phase: .exhale, duration: pattern.exhaleSeconds)
                    phaseBar(phase: .holdOut, duration: pattern.holdOutSeconds)
                }
                .frame(height: 6)

                HStack(spacing: 8) {
                    Text("\(Int(pattern.inhaleSeconds))s in")
                    Text("\(Int(pattern.holdInSeconds))s hold")
                    Text("\(Int(pattern.exhaleSeconds))s out")
                    if pattern.holdOutSeconds > 0 {
                        Text("\(Int(pattern.holdOutSeconds))s hold")
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "6b6560"))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: isSelected ? "1e1e24" : "141418"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color(hex: isSelected ? "e8d5c4" : "2a2a30").opacity(isSelected ? 0.4 : 0.3),
                                lineWidth: isSelected ? 1 : 0.5
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func phaseBar(phase: BreathPhase, duration: Double) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(phaseColor(phase).opacity(duration > 0 ? 0.7 : 0.2))
            .frame(minWidth: 4)
    }

    private func phaseColor(_ phase: BreathPhase) -> Color {
        switch phase {
        case .inhale: return Color(hex: "e8d5c4")
        case .holdIn, .holdOut: return Color(hex: "c4b5a0")
        case .exhale: return Color(hex: "a09890")
        default: return Color(hex: "6b6560")
        }
    }
}

#Preview("Visualizer") {
    ZStack {
        Color(hex: "050508")
            .ignoresSafeArea()
        VStack(spacing: 24) {
            BreathingPatternVisualizerView(
                pattern: .boxBreathing,
                isActive: true,
                currentPhase: .inhale,
                phaseProgress: 0.6
            )

            BreathingPatternVisualizerView(
                pattern: .relaxing,
                isActive: false,
                currentPhase: .idle,
                phaseProgress: 0
            )

            PatternPresetCard(
                pattern: .boxBreathing,
                isSelected: true,
                onTap: {}
            )

            PatternPresetCard(
                pattern: .energizing,
                isSelected: false,
                onTap: {}
            )
        }
        .padding()
    }
}
