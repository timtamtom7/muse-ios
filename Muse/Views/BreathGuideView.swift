import SwiftUI

struct BreathGuideView: View {
    let phase: BreathPhase
    let phaseProgress: Double
    var sessionType: SessionType = .focus

    @State private var breathCountdown: Int = 0
    @State private var showCountdown: Bool = false

    private var messages: (inhale: String, holdIn: String, exhale: String, holdOut: String) {
        sessionType.guidanceMessages
    }

    private var phaseLabel: String {
        switch phase {
        case .inhale: return messages.inhale
        case .holdIn: return messages.holdIn
        case .exhale: return messages.exhale
        case .holdOut: return messages.holdOut
        default: return ""
        }
    }

    private var countdownText: String? {
        guard phase == .inhale || phase == .exhale else { return nil }
        guard phaseProgress > 0 && phaseProgress < 1 else { return nil }

        // Show "3... 2... 1..." during inhale/exhale
        let totalDuration: Double
        switch phase {
        case .inhale: totalDuration = 4.0  // Will be overridden
        case .exhale: totalDuration = 4.0
        default: return nil
        }

        // Countdown based on remaining progress
        let remaining = 1.0 - phaseProgress
        let remainingSeconds = Int(remaining * totalDuration)
        if remainingSeconds > 0 && remainingSeconds <= 3 {
            return "\(remainingSeconds)"
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 8) {
            // Main phase label
            Text(phaseLabel)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: sessionType.orbCoreColor).opacity(0.85))
                .animation(.easeInOut(duration: 0.4), value: phase)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            // Countdown number (3, 2, 1)
            if let countdown = countdownText {
                Text(countdown)
                    .font(.system(size: 52, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(Color(hex: sessionType.orbCoreColor).opacity(0.4))
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.15), value: countdown)
                    .id("countdown-\(countdown)")
            }

            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(phaseDotColor(for: index))
                        .frame(width: 5, height: 5)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: phase)
        }
    }

    private func phaseDotColor(for index: Int) -> Color {
        let phaseOrder: [BreathPhase] = [.inhale, .holdIn, .exhale, .holdOut]
        guard let currentIndex = phaseOrder.firstIndex(of: phase) else {
            return Color(hex: sessionType.orbHaloColor).opacity(0.2)
        }
        if index == currentIndex {
            return Color(hex: sessionType.orbCoreColor).opacity(0.6)
        } else if index < currentIndex {
            return Color(hex: sessionType.orbCoreColor).opacity(0.3)
        } else {
            return Color(hex: sessionType.orbHaloColor).opacity(0.2)
        }
    }
}

struct SessionTypePicker: View {
    @Binding var selectedType: SessionType
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SessionType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = type
                    }
                } label: {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: type.orbCoreColor).opacity(selectedType == type ? 1.0 : 0.3))
                            .frame(width: isCompact ? 6 : 8, height: isCompact ? 6 : 8)

                        Text(type.shortName)
                            .font(.system(size: isCompact ? 9 : 11, weight: .medium))
                            .foregroundStyle(selectedType == type
                                ? Color(hex: type.orbCoreColor)
                                : Color(hex: "6b6560"))
                    }
                    .padding(.horizontal, isCompact ? 8 : 10)
                    .padding(.vertical, isCompact ? 6 : 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(selectedType == type
                                ? Color(hex: type.orbHaloColor).opacity(0.1)
                                : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                selectedType == type
                                    ? Color(hex: type.orbHaloColor).opacity(0.3)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview("Breath Guide") {
    ZStack {
        Color(hex: "050508").ignoresSafeArea()

        VStack(spacing: 40) {
            BreathGuideView(phase: .inhale, phaseProgress: 0.5, sessionType: .focus)
            BreathGuideView(phase: .holdIn, phaseProgress: 1.0, sessionType: .sleep)
            BreathGuideView(phase: .exhale, phaseProgress: 0.7, sessionType: .relax)
            BreathGuideView(phase: .holdOut, phaseProgress: 0.3, sessionType: .wakeUp)
        }
    }
}

#Preview("Session Type Picker") {
    ZStack {
        Color(hex: "050508").ignoresSafeArea()
        SessionTypePicker(selectedType: .constant(.focus))
    }
}
