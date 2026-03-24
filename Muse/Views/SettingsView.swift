import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showHistory = false

    var onShowPricing: () -> Void

    var body: some View {
        NavigationStack {
            List {
                // Subscription status
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(subscriptionManager.currentTier.displayName)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(hex: "e8d5c4"))

                            Text(subscriptionManager.currentTier.tagline)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6b6560"))
                        }

                        Spacer()

                        if subscriptionManager.currentTier == .free {
                            Button {
                                onShowPricing()
                            } label: {
                                Text("Upgrade")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color(hex: "050508"))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "e8d5c4"), in: Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color(hex: "1a1a1f"))

                // Session settings
                Section {
                    ForEach(subscriptionManager.availableDurations, id: \.self) { duration in
                        Button {
                            UserDefaults.standard.set(duration, forKey: "defaultDuration")
                        } label: {
                            HStack {
                                Text("\(duration) min")
                                    .foregroundStyle(Color(hex: "e8d5c4"))
                                Spacer()
                                if UserDefaults.standard.integer(forKey: "defaultDuration") == duration {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color(hex: "6b6560"))
                                }
                            }
                        }
                    }
                } header: {
                    Text("Default Duration")
                        .foregroundStyle(Color(hex: "6b6560"))
                }
                .listRowBackground(Color(hex: "1a1a1f"))

                // Feedback
                Section {
                    Toggle(isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "hapticEnabled") },
                        set: { UserDefaults.standard.set($0, forKey: "hapticEnabled") }
                    )) {
                        HStack {
                            Text("Haptic Feedback")
                                .foregroundStyle(Color(hex: "e8d5c4"))
                            Spacer()
                        }
                    }
                    .tint(Color(hex: "e8d5c4"))
                } header: {
                    Text("Feedback")
                        .foregroundStyle(Color(hex: "6b6560"))
                }
                .listRowBackground(Color(hex: "1a1a1f"))

                // Quick actions
                Section {
                    Button {
                        showHistory = true
                    } label: {
                        HStack {
                            Text("Session History")
                                .foregroundStyle(Color(hex: "e8d5c4"))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "6b6560").opacity(0.5))
                        }
                    }
                    .disabled(!subscriptionManager.currentTier.hasSessionHistory)
                    .opacity(subscriptionManager.currentTier.hasSessionHistory ? 1 : 0.4)
                } header: {
                    Text("Library")
                        .foregroundStyle(Color(hex: "6b6560"))
                }
                .listRowBackground(Color(hex: "1a1a1f"))

                // How it works
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How it works")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "e8d5c4"))

                        Text("Open the app, choose your duration, then tap the orb to begin. Breathe in as the orb expands, breathe out as it contracts. Each cycle is 12 seconds: 4s inhale, 2s hold, 4s exhale, 2s hold. When time is up, the orb fades and a gentle haptic marks the end.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6b6560"))
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About")
                        .foregroundStyle(Color(hex: "6b6560"))
                }
                .listRowBackground(Color(hex: "1a1a1f"))

                // Subscription info for paid tiers
                if subscriptionManager.isSubscribed {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Manage Subscription")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(hex: "e8d5c4"))

                            Text("Subscription management is available through your Apple ID settings.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6b6560"))
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Subscription")
                            .foregroundStyle(Color(hex: "6b6560"))
                    }
                    .listRowBackground(Color(hex: "1a1a1f"))
                }

                // App info
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Text("Muse")
                                .font(.system(size: 17, weight: .light, design: .rounded))
                                .foregroundStyle(Color(hex: "e8d5c4"))
                            Text("Version 1.0")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6b6560"))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "050508"))
            .navigationTitle("Settings")
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
        }
        .sheet(isPresented: $showHistory) {
            SessionHistoryView()
        }
        .tint(Color(hex: "e8d5c4"))
    }
}

#Preview {
    SettingsView(onShowPricing: {})
}
