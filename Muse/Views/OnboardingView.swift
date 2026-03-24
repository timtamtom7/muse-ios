import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var orbPhase: BreathPhase = .idle
    @State private var orbProgress: Double = 0
    @State private var animationTimer: Timer?

    private let pageCount = 4
    @Binding var isComplete: Bool

    var body: some View {
        ZStack {
            Color(hex: "050508")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 6) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage
                                ? Color(hex: "e8d5c4")
                                : Color(hex: "6b6560").opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 16)

                // Pages
                TabView(selection: $currentPage) {
                    OnboardingPage1()
                        .tag(0)

                    OnboardingPage2()
                        .tag(1)

                    OnboardingPage3()
                        .tag(2)

                    OnboardingPage4(onStart: {
                        markComplete()
                    })
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom nav
                HStack {
                    if currentPage > 0 {
                        Button {
                            withAnimation { currentPage -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(hex: "6b6560"))
                        }
                    } else {
                        Color.clear.frame(width: 44)
                    }

                    Spacer()

                    if currentPage < pageCount - 1 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Next")
                                    .font(.system(size: 15, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(Color(hex: "e8d5c4"))
                        }
                    } else {
                        Color.clear.frame(width: 60)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startOrbAnimation()
        }
        .onDisappear {
            stopOrbAnimation()
        }
    }

    private func startOrbAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            updateOrb()
        }
    }

    private func stopOrbAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func updateOrb() {
        let cycleDuration: Double = 12.0
        let elapsed = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: cycleDuration)
        let phaseLength = cycleDuration / 4.0

        if elapsed < phaseLength {
            orbPhase = .inhale
            orbProgress = elapsed / phaseLength
        } else if elapsed < phaseLength * 2 {
            orbPhase = .holdIn
            orbProgress = (elapsed - phaseLength) / phaseLength
        } else if elapsed < phaseLength * 3 {
            orbPhase = .exhale
            orbProgress = (elapsed - phaseLength * 2) / phaseLength
        } else {
            orbPhase = .holdOut
            orbProgress = (elapsed - phaseLength * 3) / phaseLength
        }
    }

    private func markComplete() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        stopOrbAnimation()
        isComplete = false // Will trigger parent to switch view
    }
}

// MARK: - Page 1: "Just breathe"
struct OnboardingPage1: View {
    @State private var orbPhase: BreathPhase = .idle
    @State private var orbProgress: Double = 0
    @State private var animationTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated orb
            OrbView(phase: orbPhase, phaseProgress: orbProgress)
                .frame(width: 200, height: 200)
                .padding(.bottom, 40)

            // Text
            VStack(spacing: 12) {
                Text("Just breathe.")
                    .font(.system(size: 34, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("No playlists. No narrations. No backgrounds of rainforests. Just an orb, your breath, and a few quiet minutes.")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
        .onAppear { startOrbAnimation() }
        .onDisappear { stopOrbAnimation() }
    }

    private func startOrbAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            updateOrb()
        }
    }

    private func stopOrbAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func updateOrb() {
        let cycleDuration: Double = 12.0
        let elapsed = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: cycleDuration)
        let phaseLength = cycleDuration / 4.0

        if elapsed < phaseLength {
            orbPhase = .inhale
            orbProgress = elapsed / phaseLength
        } else if elapsed < phaseLength * 2 {
            orbPhase = .holdIn
            orbProgress = (elapsed - phaseLength) / phaseLength
        } else if elapsed < phaseLength * 3 {
            orbPhase = .exhale
            orbProgress = (elapsed - phaseLength * 2) / phaseLength
        } else {
            orbPhase = .holdOut
            orbProgress = (elapsed - phaseLength * 3) / phaseLength
        }
    }
}

// MARK: - Page 2: "Follow the orb"
struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Breathing cycle diagram
            BreathingCycleDiagram()
                .frame(width: 200, height: 200)
                .padding(.bottom, 40)

            VStack(spacing: 12) {
                Text("Follow the orb.")
                    .font(.system(size: 34, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("The orb expands — breathe in. It contracts — breathe out. Each cycle is 12 seconds. You don't time it, you feel it.")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Breathing Cycle Diagram
struct BreathingCycleDiagram: View {
    @State private var phase: BreathPhase = .inhale
    @State private var progress: Double = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Cycle ring
            Circle()
                .stroke(Color(hex: "2a2a30"), lineWidth: 2)
                .frame(width: 180, height: 180)

            // Animated arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hex: "e8d5c4").opacity(0.0), location: 0.0),
                            .init(color: Color(hex: "e8d5c4").opacity(0.6), location: 0.3),
                            .init(color: Color(hex: "e8d5c4"), location: 0.5),
                            .init(color: Color(hex: "e8d5c4").opacity(0.6), location: 0.7),
                            .init(color: Color(hex: "e8d5c4").opacity(0.0), location: 1.0)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))

            // Phase labels around the circle
            VStack {
                Text("inhale")
                    .offset(y: -100)
                    .opacity(phase == .inhale ? 1.0 : 0.4)
                Spacer()
            }
            .frame(height: 180)

            HStack {
                Text("hold")
                    .offset(x: -100)
                    .opacity(phase == .holdIn || phase == .holdOut ? 1.0 : 0.4)
                Spacer()
            }
            .frame(width: 180, height: 180)

            HStack {
                Spacer()
                Text("exhale")
                    .offset(x: 100)
                    .opacity(phase == .exhale ? 1.0 : 0.4)
            }
            .frame(width: 180, height: 180)

            // Center orb
            OrbView(phase: phase, phaseProgress: progress)
                .frame(width: 80, height: 80)

            // Phase label
            Text(phaseLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "6b6560"))
                .offset(y: 110)
        }
        .onAppear { startAnimation() }
        .onDisappear { timer?.invalidate() }
    }

    private var phaseLabel: String {
        switch phase {
        case .inhale: return "breathe in"
        case .holdIn: return "hold"
        case .exhale: return "breathe out"
        case .holdOut: return "hold"
        default: return ""
        }
    }

    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            let cycleDuration: Double = 12.0
            let elapsed = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: cycleDuration)
            progress = elapsed / cycleDuration

            let phaseLength = cycleDuration / 4.0
            if elapsed < phaseLength {
                phase = .inhale
            } else if elapsed < phaseLength * 2 {
                phase = .holdIn
            } else if elapsed < phaseLength * 3 {
                phase = .exhale
            } else {
                phase = .holdOut
            }
        }
    }
}

// MARK: - Page 3: "Feel the difference"
struct OnboardingPage3: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Benefits icons
            VStack(spacing: 24) {
                BenefitRow(icon: "drop.fill", title: "Less stress", subtitle: "Even 5 minutes a day lowers cortisol")
                BenefitRow(icon: "brain.head.profile", title: "Sharper focus", subtitle: "Better attention, less mind-wandering")
                BenefitRow(icon: "moon.fill", title: "Deeper sleep", subtitle: "Wind down without screen fatigue")
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
            .padding(.bottom, 20)

            VStack(spacing: 12) {
                Text("Feel the difference.")
                    .font(.system(size: 34, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("The research is decades old. The practice is ancient. The results are yours in minutes.")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color(hex: "6b6560"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "c4b5a0"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6b6560"))
            }

            Spacer()
        }
    }
}

// MARK: - Page 4: "Breathe"
struct OnboardingPage4: View {
    let onStart: () -> Void

    @State private var orbPhase: BreathPhase = .idle
    @State private var orbProgress: Double = 0
    @State private var animationTimer: Timer?
    @State private var showStartButton = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            OrbView(phase: orbPhase, phaseProgress: orbProgress)
                .frame(width: 200, height: 200)
                .padding(.bottom, 40)

            VStack(spacing: 16) {
                Text("Breathe.")
                    .font(.system(size: 40, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(Color(hex: "e8d5c4"))

                Text("That's all. Just start.")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color(hex: "6b6560"))

                Button {
                    onStart()
                } label: {
                    Text("Begin")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "050508"))
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Color(hex: "e8d5c4"), in: Capsule())
                }
                .padding(.top, 24)
                .opacity(showStartButton ? 1 : 0)
                .scaleEffect(showStartButton ? 1 : 0.9)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            startOrbAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showStartButton = true
                }
            }
        }
        .onDisappear {
            stopOrbAnimation()
        }
    }

    private func startOrbAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            updateOrb()
        }
    }

    private func stopOrbAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func updateOrb() {
        let cycleDuration: Double = 12.0
        let elapsed = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: cycleDuration)
        let phaseLength = cycleDuration / 4.0

        if elapsed < phaseLength {
            orbPhase = .inhale
            orbProgress = elapsed / phaseLength
        } else if elapsed < phaseLength * 2 {
            orbPhase = .holdIn
            orbProgress = (elapsed - phaseLength) / phaseLength
        } else if elapsed < phaseLength * 3 {
            orbPhase = .exhale
            orbProgress = (elapsed - phaseLength * 2) / phaseLength
        } else {
            orbPhase = .holdOut
            orbProgress = (elapsed - phaseLength * 3) / phaseLength
        }
    }
}

#Preview {
    OnboardingView(isComplete: .constant(true))
}
