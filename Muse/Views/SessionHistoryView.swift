import SwiftUI

struct SessionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var historyManager = SessionHistoryManager.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "050508")
                    .ignoresSafeArea()

                if !subscriptionManager.currentTier.hasSessionHistory {
                    EmptyHistoryState(
                        message: subscriptionManager.upgradePrompt(for: "history"),
                        showUpgrade: true,
                        onUpgrade: { dismiss() }
                    )
                } else if historyManager.sessions.isEmpty {
                    EmptyHistoryState(
                        message: "Your completed sessions will appear here.",
                        showUpgrade: false,
                        onUpgrade: {}
                    )
                } else {
                    sessionList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "6b6560"))
                    }
                }

                if !historyManager.sessions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color(hex: "6b6560"))
                        }
                    }
                }
            }
            .confirmationDialog("Clear History", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) {
                    historyManager.clearHistory()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
        .tint(Color(hex: "e8d5c4"))
    }

    private var sessionList: some View {
        List {
            // Stats section
            Section {
                // Weekly stats row
                HStack {
                    WeeklyStatItem(
                        value: "\(historyManager.sessionsThisWeek)",
                        label: "Sessions\nthis week",
                        icon: "flame"
                    )
                    Spacer()
                    WeeklyStatItem(
                        value: "\(historyManager.minutesThisWeek)",
                        label: "Minutes\nthis week",
                        icon: "clock"
                    )
                    Spacer()
                    WeeklyStatItem(
                        value: "\(historyManager.averageDurationMinutes)",
                        label: "Avg min\nper session",
                        icon: "chart.bar"
                    )
                }
                .padding(.vertical, 8)

                // Streak row
                HStack(spacing: 16) {
                    StreakBadge(
                        streak: historyManager.currentStreak,
                        isAtRisk: historyManager.isStreakAtRisk,
                        isBroken: historyManager.isStreakBroken
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        if historyManager.isStreakBroken {
                            Text("Streak broken")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "6b6560"))
                            Text("Start a new streak today")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "6b6560").opacity(0.6))
                        } else if historyManager.isStreakAtRisk {
                            Text("Streak at risk")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "c4a87a"))
                            Text("Breathe today to keep it alive")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "6b6560").opacity(0.6))
                        } else {
                            Text("\(historyManager.currentStreak)-day streak")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "e8d5c4"))
                            Text("Longest: \(historyManager.longestStreak) days")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "6b6560").opacity(0.6))
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color(hex: "1a1a1f"))

            // All-time stats
            Section {
                HStack {
                    StatItem(value: "\(historyManager.totalSessions)", label: "Total Sessions")
                    Spacer()
                    StatItem(value: "\(historyManager.totalMinutes)", label: "Total Minutes")
                    Spacer()
                    StatItem(value: formattedTotalHours, label: "Total Hours")
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color(hex: "1a1a1f"))

            // Sessions section
            Section {
                ForEach(historyManager.sessions) { session in
                    SessionRowView(session: session)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        if index < historyManager.sessions.count {
                            historyManager.deleteSession(historyManager.sessions[index])
                        }
                    }
                }
            } header: {
                Text("Recent Sessions")
                    .foregroundStyle(Color(hex: "6b6560"))
            }
            .listRowBackground(Color(hex: "1a1a1f"))
        }
        .scrollContentBackground(.hidden)
    }

    private var formattedTotalHours: String {
        let hours = Double(historyManager.totalMinutes) / 60.0
        return String(format: "%.1f", hours)
    }
}

struct WeeklyStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "c4b5a0").opacity(0.7))

            Text(value)
                .font(.system(size: 20, weight: .light, design: .rounded))
                .foregroundStyle(Color(hex: "e8d5c4"))

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "6b6560"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StreakBadge: View {
    let streak: Int
    let isAtRisk: Bool
    let isBroken: Bool

    private var badgeColor: Color {
        if isBroken { return Color(hex: "4a4540") }
        if isAtRisk { return Color(hex: "c4a87a") }
        return Color(hex: "e8d5c4")
    }

    private var iconName: String {
        if isBroken { return "bolt.slash" }
        if isAtRisk { return "bolt.badge.a" }
        return "flame.fill"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(badgeColor.opacity(0.12))
                .frame(width: 52, height: 52)

            Circle()
                .fill(badgeColor.opacity(0.08))
                .frame(width: 44, height: 44)

            VStack(spacing: 1) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(badgeColor)

                Text("\(streak)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(badgeColor)
            }
        }
        .overlay(
            Circle()
                .stroke(badgeColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .light, design: .rounded))
                .foregroundStyle(Color(hex: "e8d5c4"))

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "6b6560"))
        }
    }
}

struct SessionRowView: View {
    let session: SessionRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(session.durationMinutes) min")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "e8d5c4"))

                    if let pattern = session.patternName {
                        Text("·")
                            .foregroundStyle(Color(hex: "6b6560"))
                        Text(pattern)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "c4b5a0"))
                    }
                }

                Text(session.formattedDate)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6b6560"))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.relativeDate)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6b6560").opacity(0.6))

                if session.completedCycles > 0 {
                    Text("\(session.completedCycles) cycles")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "6b6560").opacity(0.4))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyHistoryState: View {
    let message: String
    let showUpgrade: Bool
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "6b6560").opacity(0.4))

            Text(message)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Color(hex: "6b6560"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if showUpgrade {
                Button {
                    onUpgrade()
                } label: {
                    Text("See plans")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "050508"))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color(hex: "e8d5c4"), in: Capsule())
                }
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    SessionHistoryView()
}
