import SwiftUI
import WatchConnectivity

struct BreatheView: View {
    @State private var sessionManager = BreathingSessionManager()
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var historyManager = SessionHistoryManager.shared
    @State private var patternManager = BreathingPatternManager.shared
    @State private var sessionTypeManager = SessionTypeManager.shared
    @State private var soundscapeManager = SoundscapeManager.shared

    @State private var showSettings = false
    @State private var showPricing = false
    @State private var showHistory = false
    @State private var showDurationPicker = false
    @State private var showPatternSelection = false
    @State private var showSoundMixer = false
    @State private var selectedMinutes: Int = 10
    @State private var showCompletionCard = false
    @State private var showInterrupted = false
    @State private var showHapticsAlert = false
    @State private var showNoSessions = false
    @State private var completedCycles: Int = 0

    @State private var displayDuration: Int = 10
    @State private var watchSessionManager = iPhoneWatchSessionManager.shared
    @State private var sessionStartTime: Date?
    @State private var timer: Timer?
    @State private var previousPhase: BreathPhase = .idle
    @State private var wasActive = false

    private let hapticService = HapticService.shared

    private var sessionType: SessionType {
        sessionTypeManager.selectedType
    }

    var body: some View {
        ZStack {
            Color(hex: sessionType.backgroundHex)
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
                    .accessibilityLabel("View session history")

                    Spacer()

                    // Session type indicator (tappable to switch)
                    Button {
                        cycleSessionType()
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: sessionType.orbCoreColor))
                                .frame(width: 6, height: 6)
                            Text(sessionType.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color(hex: "6b6560"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .accessibilityLabel("Cycle session type. Currently \(sessionType.displayName)")

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
                    .accessibilityLabel("Open settings")
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
                        phaseProgress: sessionManager.session.phaseProgress,
                        sessionType: sessionType
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 360)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(sessionManager.session.phase == .complete)
                .accessibilityLabel(sessionManager.session.isActive ? "Stop breathing session" : "Start breathing session. Tap to begin.")

                // Breath guide (shown during active session)
                if sessionManager.session.isActive {
                    BreathGuideView(
                        phase: sessionManager.session.phase,
                        phaseProgress: sessionManager.session.phaseProgress,
                        sessionType: sessionType
                    )
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    // Session type picker (shown when idle)
                    SessionTypePicker(selectedType: $sessionTypeManager.selectedType, isCompact: false)
                        .padding(.top, 16)
                }

                Spacer()

                // Duration / Timer display
                VStack(spacing: 8) {
                    if sessionManager.session.isActive {
                        Text(sessionManager.formattedRemainingTime)
                            .font(.system(size: 72, weight: .light, design: .rounded))
                            .foregroundStyle(Color(hex: sessionType.orbCoreColor).opacity(0.85))
                            .monospacedDigit()
                    } else {
                        Text("\(displayDuration)")
                            .font(.system(size: 72, weight: .light, design: .rounded))
                            .foregroundStyle(Color(hex: sessionType.orbCoreColor).opacity(0.85))
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
                        Text(patternManager.selectedPattern.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "6b6560").opacity(0.6))
                            .animation(.easeInOut(duration: 0.3), value: sessionManager.session.phase)
                    }

                    // Sound mixer button (Master tier)
                    if !sessionManager.session.isActive && subscriptionManager.currentTier.hasSoundscapes {
                        Button {
                            showSoundMixer = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: soundscapeManager.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                                    .font(.system(size: 11))
                                Text(soundscapeManager.isPlaying ? soundscapeManager.activeSoundscape?.displayName ?? "Soundscape" : "Add sound")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(Color(hex: "6b6560").opacity(0.6))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.bottom, 60)
            }

            // Session complete card
            if showCompletionCard {
                SessionCompleteCard(
                    minutes: selectedMinutes,
                    cyclesCompleted: completedCycles,
                    sessionType: sessionType,
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
        .sheet(isPresented: $showPatternSelection) {
            PatternSelectionView()
        }
        .sheet(isPresented: $showSoundMixer) {
            SoundMixerView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
            applySelectedPattern()
        }
        .onChange(of: showCompletionCard) { _, newValue in
            if !newValue {
                resetSession()
            }
        }
        .onChange(of: sessionTypeManager.selectedType) { _, newType in
            if !sessionManager.session.isActive {
                applySelectedPattern()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            handleAppBackground()
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

    private func applySelectedPattern() {
        sessionManager.applyPattern(patternManager.selectedPattern)
    }

    private func cycleSessionType() {
        let allCases = SessionType.allCases
        if let index = allCases.firstIndex(of: sessionTypeManager.selectedType) {
            let nextIndex = (index + 1) % allCases.count
            sessionTypeManager.selectedType = allCases[nextIndex]
        }
    }

    private func startSession() {
        // Apply latest pattern selection
        applySelectedPattern()

        // Check subscription limits
        if !subscriptionManager.canStartSession {
            showNoSessions = true
            return
        }

        // Check duration limit
        if !subscriptionManager.canUseDuration(displayDuration) {
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

        // Start soundscape if enabled
        if subscriptionManager.currentTier.hasSoundscapes {
            soundscapeManager.startIfConfigured()
        }

        // Send update to watch
        if watchSessionManager.isWatchPaired && subscriptionManager.currentTier.hasAppleWatchCompanion {
            watchSessionManager.sendSessionUpdate(session: sessionManager.session, sessionType: sessionType)
        }

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
                soundscapeManager.stop()

                // Record in history if tier supports it
                if subscriptionManager.currentTier.hasSessionHistory {
                    historyManager.recordSession(
                        durationMinutes: selectedMinutes,
                        completedCycles: completedCycles,
                        patternName: patternManager.selectedPattern.name
                    )

                    // Schedule streak nudge if at risk
                    if historyManager.isStreakAtRisk {
                        ReminderManager.shared.scheduleStreakNudge()
                    }
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
        soundscapeManager.stop()

        // Send session end to watch
        if watchSessionManager.isWatchPaired && subscriptionManager.currentTier.hasAppleWatchCompanion {
            watchSessionManager.sendSessionUpdate(session: sessionManager.session, sessionType: sessionType)
        }
    }

    private func resumeSession() {
        showInterrupted = false
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
        applySelectedPattern()
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
