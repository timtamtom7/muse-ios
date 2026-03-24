import SwiftUI

// MARK: - Haptics Not Available Alert
struct HapticsUnavailableAlert: View {
    @Binding var isPresented: Bool
    let onDismiss: () -> Void

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                VStack(spacing: 16) {
                    Image(systemName: "iphone.radiowaves.left.and.right.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(hex: "c4b5a0"))

                    Text("Haptics unavailable")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "e8d5c4"))

                    Text("This device doesn't support haptic feedback. The session will continue without tactile cues.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "6b6560"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 4)

                    Button {
                        dismiss()
                    } label: {
                        Text("Continue anyway")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "050508"))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color(hex: "e8d5c4"), in: Capsule())
                    }
                    .padding(.top, 4)
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "0f0f14"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "2a2a30").opacity(0.6), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 32)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
        onDismiss()
    }
}

// MARK: - Session Interrupted View
struct SessionInterruptedView: View {
    let elapsedMinutes: Int
    let onResume: () -> Void
    let onDiscard: () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: "c4b5a0"))

                Text("Session interrupted")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("You breathed for \(elapsedMinutes) minute\(elapsedMinutes == 1 ? "" : "s"). That's a start.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                HStack(spacing: 12) {
                    Button {
                        onDiscard()
                    } label: {
                        Text("Discard")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "6b6560"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "1e1e24"), in: Capsule())
                    }

                    Button {
                        onResume()
                    } label: {
                        Text("Resume")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "050508"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "e8d5c4"), in: Capsule())
                    }
                }
                .padding(.top, 4)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "0f0f14"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "2a2a30").opacity(0.6), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 32)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                opacity = 1
            }
        }
    }
}

// MARK: - No Sessions Remaining View
struct NoSessionsRemainingView: View {
    let onViewPlans: () -> Void
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "clock.badge.xmark")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: "c4b5a0"))

                Text("Daily limit reached")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("You've used all 5 free sessions today. Upgrade to Practice or Master for unlimited breathing.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)

                Button {
                    onViewPlans()
                } label: {
                    Text("See plans")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "050508"))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color(hex: "e8d5c4"), in: Capsule())
                }
                .padding(.top, 4)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "0f0f14"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "2a2a30").opacity(0.6), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 32)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                opacity = 1
            }
        }
    }
}

// MARK: - Duration Not Available View
struct DurationNotAvailableView: View {
    let requestedMinutes: Int
    let maxMinutes: Int
    let onUpgrade: () -> Void
    let onSelectOther: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onSelectOther() }

            VStack(spacing: 16) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: "c4b5a0"))

                Text("\(requestedMinutes) minutes unavailable")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("Your current plan supports sessions up to \(maxMinutes) minutes. Upgrade to unlock longer sessions.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)

                Button {
                    onUpgrade()
                } label: {
                    Text("Upgrade plan")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "050508"))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color(hex: "e8d5c4"), in: Capsule())
                }
                .padding(.top, 4)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "0f0f14"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "2a2a30").opacity(0.6), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Session Complete Card (refined)
struct SessionCompleteCard: View {
    let minutes: Int
    let cyclesCompleted: Int
    var sessionType: SessionType = .focus
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var cardScale: CGFloat = 0.92

    private var orbColor: Color { Color(hex: sessionType.orbCoreColor) }
    private var textColor: Color { Color(hex: sessionType.orbCoreColor) }
    private var mutedColor: Color { Color(hex: sessionType.orbHaloColor) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 16) {
                // Orb pulse
                OrbView(phase: .complete, phaseProgress: 1.0, sessionType: sessionType)
                    .frame(width: 80, height: 80)

                VStack(spacing: 6) {
                    Text("\(minutes) minutes")
                        .font(.system(size: 28, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(textColor.opacity(0.9))

                    Text("of presence")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color(hex: "6b6560"))
                }

                if cyclesCompleted > 0 {
                    Text("\(cyclesCompleted) breath cycles")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "6b6560").opacity(0.6))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(textColor)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color(hex: "1e1e24"), in: Capsule())
                }
                .padding(.top, 8)
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "0c0c10"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "2a2a30").opacity(0.5), lineWidth: 0.5)
                    )
            )
            .scaleEffect(cardScale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                opacity = 1
                cardScale = 1
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            cardScale = 0.92
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

#Preview("Haptics unavailable") {
    HapticsUnavailableAlert(isPresented: .constant(true), onDismiss: {})
}

#Preview("Session interrupted") {
    SessionInterruptedView(
        elapsedMinutes: 3,
        onResume: {},
        onDiscard: {}
    )
}

#Preview("No sessions remaining") {
    NoSessionsRemainingView(onViewPlans: {})
}

#Preview("Session complete") {
    SessionCompleteCard(
        minutes: 10,
        cyclesCompleted: 50,
        sessionType: .focus,
        onDismiss: {}
    )
}

// MARK: - Notification Permission Denied

struct NotificationDeniedErrorView: View {
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 16) {
                Image(systemName: "bell.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: "c4b5a0"))

                Text("Notifications disabled")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("Daily reminders require notifications. Enable them in Settings, or breathe without reminders.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "6b6560"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "1e1e24"), in: Capsule())
                    }

                    Button {
                        onOpenSettings()
                    } label: {
                        Text("Open Settings")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "050508"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "e8d5c4"), in: Capsule())
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "0f0f14"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "2a2a30").opacity(0.6), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 32)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                opacity = 1
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Pattern Save Failed

struct PatternSaveFailedView: View {
    let onRetry: () -> Void
    let onDismiss: () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: "c4b5a0"))

                Text("Couldn't save pattern")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("Something went wrong saving your custom breathing pattern. Please try again.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "6b6560"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "1e1e24"), in: Capsule())
                    }

                    Button {
                        dismiss()
                        onRetry()
                    } label: {
                        Text("Try again")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "050508"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "e8d5c4"), in: Capsule())
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "0f0f14"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "2a2a30").opacity(0.6), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 32)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                opacity = 1
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

#Preview("Notification denied") {
    NotificationDeniedErrorView(
        onOpenSettings: {},
        onDismiss: {}
    )
}

#Preview("Pattern save failed") {
    PatternSaveFailedView(
        onRetry: {},
        onDismiss: {}
    )
}

// MARK: - Watch Not Paired

struct WatchNotPairedView: View {
    let onDismiss: () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 16) {
                Image(systemName: "applewatch.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: "c4b5a0"))

                Text("Apple Watch not paired")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("Pair your Apple Watch in the Watch app to use it as a companion during breathing sessions.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                Button {
                    dismiss()
                } label: {
                    Text("Got it")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "e8d5c4"))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color(hex: "1e1e24"), in: Capsule())
                }
                .padding(.top, 4)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "0f0f14"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "2a2a30").opacity(0.6), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 32)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                opacity = 1
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Sound Load Failed

struct SoundLoadFailedView: View {
    let soundscapeName: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 16) {
                Image(systemName: "speaker.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: "c4b5a0"))

                Text("Couldn't load sound")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("The soundscape \"\(soundscapeName)\" couldn't be loaded. The audio file may be missing or corrupted.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "6b6560"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "1e1e24"), in: Capsule())
                    }

                    Button {
                        dismiss()
                        onRetry()
                    } label: {
                        Text("Try again")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "050508"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "e8d5c4"), in: Capsule())
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "0f0f14"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "2a2a30").opacity(0.6), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 32)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                opacity = 1
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

#Preview("Watch not paired") {
    WatchNotPairedView(onDismiss: {})
}

#Preview("Sound load failed") {
    SoundLoadFailedView(
        soundscapeName: "Ocean Waves",
        onRetry: {},
        onDismiss: {}
    )
}
