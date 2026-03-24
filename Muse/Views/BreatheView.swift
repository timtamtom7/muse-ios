import SwiftUI

struct BreatheView: View {
    @State private var sessionManager = BreathingSessionManager()
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var historyManager = SessionHistoryManager.shared
    @State private var showSettings = false
    @State private var showPricing = false
    @State private var showHistory = false
    @State private var showDurationPicker = false
    @State private var selectedMinutes: Int = 10
    @State private var showCompletionCard = false
    @State private var showInterrupted = false
    @State private var showHapticsAlert = false
    @State private var showNoSessions = false
    @State private var completedCycles: Int = 0
    @State private var orbTapped = false

    @State private var displayDuration: Int = 10
    @State private var sessionStartTime: Date?
    @State private var timer: Timer?
    @State private var previousPhase: BreathPhase = .idle
    @State private var wasActive = false

    private let hapticService = HapticService.shared

    var body: some View {
        ZStack {
            Color(hex: "050508")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color(hex: "6b6560"))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Spacer()

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color(hex: "6b6560"))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Orb
                Button {
                    handleOrbTap()
                } label: {
                    OrbView(
                        phase: sessionManager.session.phase,
                        phaseProgress: sessionManager.session.phaseProgress
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 360)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(sessionManager.session.phase == .complete)

                Spacer()

                // Duration / Timer display
                VStack(spacing: 8) {
                    if sessionManager.session.isActive {
                        Text(sessionManager.formattedRemainingTime)
                            .font(.system(size: 72, weight: .light, design: .rounded))
                            .foregroundStyle(Color(hex: "e8d5c4"))
                            .monospacedDigit()
                    } else {
                        Text("\(displayDuration)")
                            .font(.system(size: 72, weight: .light, design: .rounded))
                            .foregroundStyle(Color(hex: "e8d5c4"))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !sessionManager.session.isActive {
                                    showDurationPicker = true
                                }
                            }
                    }

                    if !sessionManager.session.isActive {
                        Text("Tap time to adjust · tap orb to begin")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6b6560"))
                    } else {
                        Text(phaseLabel)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "6b6560").opacity(0.8))
                            .animation(.easeInOut(duration: 0.3), value: sessionManager.session.phase)
                    }
                }
                .padding(.bottom, 60)
            }

            // Session complete card
            if showCompletionCard {
                SessionCompleteCard(
                    minutes: selectedMinutes,
                    cyclesCompleted: completedCycles,
                    onDismiss: resetSession
                )
            }

            // Haptics unavailable alert
            if showHapticsAlert {
                HapticsUnavailableAlert(
                    isPresented: $showHapticsAlert,
                    onDismiss: {}
                )
            }

            // Session interrupted
            if showInterrupted {
                SessionInterruptedView(
                    elapsedMinutes: Int(sessionManager.session.elapsedTime / 60),
                    onResume: resumeSession,
                    onDiscard: discardInterrupted
                )
            }

            // No sessions remaining
            if showNoSessions {
                NoSessionsRemainingView(onViewPlans: {
                    showNoSessions = false
                    showPricing = true
                })
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onShowPricing: { showPricing = true })
        }
        .sheet(isPresented: $showPricing) {
            PricingView()
        }
        .sheet(isPresented: $showHistory) {
            SessionHistoryView()
        }
        .confirmationDialog("Select Duration", isPresented: $showDurationPicker, titleVisibility: .visible) {
            ForEach(subscriptionManager.availableDurations, id: \.self) { duration in
                Button("\(duration) min") {
                    displayDuration = duration
                    selectedMinutes = duration
                    sessionManager.session.totalDuration = TimeInterval(duration * 60)
                    UserDefaults.standard.set(duration, forKey: "defaultDuration")
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            loadDefaults()
            checkHapticsAvailability()
        }
        .onChange(of: showCompletionCard) { _, newValue in
            if !newValue {
                resetSession()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            handleAppBackground()
        }
    }

    // MARK: - Computed

    private var phaseLabel: String {
        switch sessionManager.session.phase {
        case .inhale: return "breathe in"
        case .holdIn: return "hold"
        case .exhale: return "breathe out"
        case .holdOut: return "hold"
        default: return ""
        }
    }

    // MARK: - Session Control

    private func handleOrbTap() {
        if sessionManager.session.isActive {
            stopSession()
        } else {
            startSession()
        }
    }

    private func startSession() {
        // Check subscription limits
        if !subscriptionManager.canStartSession {
            showNoSessions = true
            return
        }

        // Check duration limit
        if !subscriptionManager.canUseDuration(displayDuration) {
            // Duration not available for tier — silently cap to max
            displayDuration = subscriptionManager.currentTier.maxDurationMinutes
        }

        sessionManager.session.totalDuration = TimeInterval(displayDuration * 60)
        sessionManager.session.elapsedTime = 0
        sessionManager.session.phase = .inhale
        sessionManager.session.isActive = true
        sessionStartTime = Date()
        previousPhase = .inhale
        completedCycles = 0
        hapticService.playInhale()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard let start = sessionStartTime else { return }
            let elapsed = Date().timeIntervalSince(start)
            let prevPhase = sessionManager.session.phase
            sessionManager.tick(elapsed: elapsed)

            // Count cycles
            if sessionManager.session.phase == .inhale && prevPhase == .holdOut {
                completedCycles += 1
            }

            // Detect phase changes for haptics
            if sessionManager.session.phase != previousPhase {
                switch sessionManager.session.phase {
                case .exhale:
                    hapticService.playExhale()
                case .inhale:
                    hapticService.playInhale()
                default:
                    break
                }
                previousPhase = sessionManager.session.phase
            }

            // Check completion
            if sessionManager.session.phase == .complete {
                timer?.invalidate()
                timer = nil
                hapticService.playSessionComplete()

                // Record in history if tier supports it
                if subscriptionManager.currentTier.hasSessionHistory {
                    historyManager.recordSession(
                        durationMinutes: selectedMinutes,
                        completedCycles: completedCycles
                    )
                }

                subscriptionManager.recordSession()
                showCompletionCard = true
            }
        }
    }

    private func stopSession() {
        timer?.invalidate()
        timer = nil
        sessionManager.stop()
        sessionStartTime = nil
        previousPhase = .idle
    }

    private func resumeSession() {
        showInterrupted = false
        // Don't auto-resume — user taps orb to resume
    }

    private func discardInterrupted() {
        showInterrupted = false
        resetSession()
    }

    private func resetSession() {
        showCompletionCard = false
        sessionManager.session.phase = .idle
        sessionManager.session.elapsedTime = 0
        sessionStartTime = nil
        previousPhase = .idle
        completedCycles = 0
    }

    private func handleAppBackground() {
        if sessionManager.session.isActive {
            wasActive = true
            stopSession()
            showInterrupted = true
        }
    }

    private func checkHapticsAvailability() {
        if !hapticService.supportsHaptics {
            showHapticsAlert = true
        }
    }

    private func loadDefaults() {
        let saved = UserDefaults.standard.integer(forKey: "defaultDuration")
        if saved > 0 {
            displayDuration = saved
            selectedMinutes = saved
            sessionManager.session.totalDuration = TimeInterval(saved * 60)
        }
    }
}

#Preview {
    BreatheView()
}
