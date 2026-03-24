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
                HStack {
                    StatItem(value: "\(historyManager.totalSessions)", label: "Sessions")
                    Spacer()
                    StatItem(value: "\(historyManager.totalMinutes)", label: "Minutes")
                    Spacer()
                    StatItem(value: "\(historyManager.sessionsThisWeek)", label: "This week")
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
                Text("\(session.durationMinutes) min session")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text(session.formattedDate)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6b6560"))
            }

            Spacer()

            Text(session.relativeDate)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "6b6560").opacity(0.6))
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
