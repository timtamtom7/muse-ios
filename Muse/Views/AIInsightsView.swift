import SwiftUI

struct AIInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var insightsService = AIInsightsService.shared
    @State private var patternManager = BreathingPatternManager.shared
    @State private var showAdaptivePatternApplied = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "050508")
                    .ignoresSafeArea()

                if insightsService.insights.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Adaptive pattern suggestion card
                            if let suggested = insightsService.suggestedPattern {
                                adaptivePatternCard(pattern: suggested, reason: insightsService.suggestedPatternReason ?? "")
                            }

                            // Insights list
                            VStack(spacing: 12) {
                                ForEach(insightsService.insights) { insight in
                                    InsightCard(insight: insight)
                                }
                            }

                            // Refresh button
                            Button {
                                insightsService.refreshInsights()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12))
                                    Text("Refresh insights")
                                        .font(.system(size: 13))
                                }
                                .foregroundStyle(Color(hex: "6b6560"))
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "6b6560"))
                    .font(.system(size: 15, weight: .medium))
                }
            }
            .alert("Adaptive pattern applied", isPresented: $showAdaptivePatternApplied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your breathing pattern has been adjusted based on the time of day.")
            }
        }
        .tint(Color(hex: "e8d5c4"))
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "6b6560").opacity(0.4))

            Text("Not enough data yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: "e8d5c4"))

            Text("Complete a few breathing sessions and I'll generate personalized insights about your practice.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6b6560"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func adaptivePatternCard(pattern: BreathingPattern, reason: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "c4a87a"))

                        Text("Adaptive Pattern")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "c4a87a"))
                    }

                    Text(pattern.name)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "e8d5c4"))
                }

                Spacer()

                // Mini rhythm display
                HStack(spacing: 4) {
                    MiniRhythmDot(seconds: Int(pattern.inhaleSeconds))
                    MiniRhythmDot(seconds: Int(pattern.holdInSeconds))
                    MiniRhythmDot(seconds: Int(pattern.exhaleSeconds))
                    MiniRhythmDot(seconds: Int(pattern.holdOutSeconds))
                }
            }

            Text(reason)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "6b6560"))
                .lineLimit(3)

            // Pattern bars
            HStack(spacing: 8) {
                PatternBar(label: "In", seconds: Int(pattern.inhaleSeconds), maxSeconds: 8, color: Color(hex: "e8d5c4"))
                PatternBar(label: "Hold", seconds: Int(pattern.holdInSeconds), maxSeconds: 8, color: Color(hex: "c4b5a0"))
                PatternBar(label: "Out", seconds: Int(pattern.exhaleSeconds), maxSeconds: 8, color: Color(hex: "a09890"))
                PatternBar(label: "Hold", seconds: Int(pattern.holdOutSeconds), maxSeconds: 8, color: Color(hex: "7a7068"))
                Spacer()
            }

            Button {
                patternManager.saveSelectedPattern(pattern)
                showAdaptivePatternApplied = true
            } label: {
                Text("Apply this pattern")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "050508"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "e8d5c4"), in: Capsule())
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "1e1a14"), Color(hex: "141210")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "3a3020"), lineWidth: 0.5)
        )
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: AIInsight

    private var iconColor: Color {
        switch insight.category {
        case .timePattern: return Color(hex: "b8c5d6")
        case .durationPattern: return Color(hex: "e8d5c4")
        case .patternPreference: return Color(hex: "c4a87a")
        case .streakMotivation: return Color(hex: "e8b87a")
        case .adaptive: return Color(hex: "9fb3cc")
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: insight.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text(insight.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .lineLimit(3)

                // Confidence indicator
                HStack(spacing: 4) {
                    Text(confidenceLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(iconColor.opacity(0.7))

                    ConfidenceBar(confidence: insight.confidence)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(hex: "141418"), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "2a2a30"), lineWidth: 0.5)
        )
    }

    private var confidenceLabel: String {
        if insight.confidence >= 0.8 {
            return "High confidence"
        } else if insight.confidence >= 0.5 {
            return "Moderate confidence"
        } else {
            return "Based on limited data"
        }
    }
}

// MARK: - Supporting Views

struct MiniRhythmDot: View {
    let seconds: Int

    var body: some View {
        Circle()
            .fill(Color(hex: "6b6560").opacity(seconds == 0 ? 0.3 : 0.8))
            .frame(width: 6, height: 6)
    }
}

struct PatternBar: View {
    let label: String
    let seconds: Int
    let maxSeconds: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(seconds == 0 ? 0.15 : 0.6))
                .frame(width: 32, height: max(4, CGFloat(seconds) / CGFloat(maxSeconds) * 24))

            Text(seconds == 0 ? "—" : "\(seconds)s")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(color.opacity(seconds == 0 ? 0.4 : 0.8))
        }
    }
}

struct ConfidenceBar: View {
    let confidence: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "2a2a30"))
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "c4a87a").opacity(0.6))
                    .frame(width: geometry.size.width * confidence, height: 3)
            }
        }
        .frame(height: 3)
    }
}

#Preview {
    AIInsightsView()
}
