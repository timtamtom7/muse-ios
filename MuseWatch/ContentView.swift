import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var sessionManager = WatchSessionManager.shared
    @State private var isActive = false
    @State private var elapsed: TimeInterval = 0
    @State private var totalDuration: TimeInterval = 600
    @State private var phase: WatchBreathPhase = .idle
    @State private var phaseProgress: Double = 0
    @State private var remainingMinutes: Int = 10
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Background based on session type
            Color(hex: sessionManager.sessionType.backgroundHex)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Session type indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: sessionManager.sessionType.orbCoreColor))
                        .frame(width: 4, height: 4)
                    Text(sessionManager.sessionType.displayName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color(hex: "6b6560"))
                }
                .padding(.top, 4)

                Spacer()

                // Orb
                WatchOrbView(
                    phase: phase,
                    progress: phaseProgress,
                    sessionType: sessionManager.sessionType
                )
                .frame(width: 100, height: 100)

                // Phase label
                if isActive {
                    Text(phaseLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: sessionManager.sessionType.orbCoreColor).opacity(0.7))
                        .padding(.top, 4)
                }

                Spacer()

                // Timer / remaining time
                VStack(spacing: 2) {
                    if isActive {
                        Text(formatRemaining(elapsed: elapsed))
                            .font(.system(size: 24, weight: .light, design: .rounded))
                            .foregroundStyle(Color(hex: sessionManager.sessionType.orbCoreColor).opacity(0.8))
                            .monospacedDigit()
                    } else {
                        Text("\(Int(totalDuration / 60)) min")
                            .font(.system(size: 24, weight: .light, design: .rounded))
                            .foregroundStyle(Color(hex: sessionManager.sessionType.orbCoreColor).opacity(0.8))
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            sessionManager.startSession()
        }
        .onChange(of: sessionManager.receivedMessage) { _, _ in
            handleMessage()
        }
    }

    private var phaseLabel: String {
        switch phase {
        case .inhale: return sessionManager.sessionType.guidanceMessages.inhale
        case .holdIn: return sessionManager.sessionType.guidanceMessages.holdIn
        case .exhale: return sessionManager.sessionType.guidanceMessages.exhale
        case .holdOut: return sessionManager.sessionType.guidanceMessages.holdOut
        default: return ""
        }
    }

    private func formatRemaining(elapsed: TimeInterval) -> String {
        let remaining = max(0, totalDuration - elapsed)
        let mins = Int(remaining) / 60
        let secs = Int(remaining) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func handleMessage() {
        guard let msg = sessionManager.lastMessage else { return }

        if let sessionActive = msg["sessionActive"] as? Bool {
            isActive = sessionActive
            if !sessionActive {
                timer?.invalidate()
                timer = nil
                phase = .idle
            } else {
                startTimer()
            }
        }

        if let dur = msg["duration"] as? TimeInterval {
            totalDuration = dur
        }

        if let elapsedTime = msg["elapsed"] as? TimeInterval {
            elapsed = elapsedTime
        }

        if let phaseRaw = msg["phase"] as? String {
            phase = WatchBreathPhase(rawValue: phaseRaw) ?? .idle
        }

        if let progress = msg["phaseProgress"] as? Double {
            phaseProgress = progress
        }

        if let typeRaw = msg["sessionType"] as? String,
           let type = WatchSessionType(rawValue: typeRaw) {
            sessionManager.sessionType = type
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsed += 1
            if elapsed >= totalDuration {
                timer?.invalidate()
                isActive = false
                WKInterfaceDevice.current().play(.success)
            }
        }
    }
}

// MARK: - Watch Session Manager

enum WatchBreathPhase: String {
    case idle
    case inhale
    case holdIn
    case exhale
    case holdOut
    case complete
}

enum WatchSessionType: String {
    case focus = "Focus"
    case sleep = "Sleep"
    case relax = "Relax"
    case wakeUp = "Wake Up"

    var backgroundHex: String {
        switch self {
        case .focus: return "050508"
        case .sleep: return "03040a"
        case .relax: return "080706"
        case .wakeUp: return "0a0805"
        }
    }

    var orbCoreColor: String {
        switch self {
        case .focus: return "f5efe6"
        case .sleep: return "b8c5d6"
        case .relax: return "e8d5c4"
        case .wakeUp: return "f5d0a9"
        }
    }

    var guidanceMessages: (inhale: String, holdIn: String, exhale: String, holdOut: String) {
        switch self {
        case .focus: return ("Breathe in", "Hold", "Breathe out", "Hold")
        case .sleep: return ("Slowly breathe in", "Soften", "Release", "Rest")
        case .relax: return ("Let breath in", "Release tension", "Breathe out", "Settle")
        case .wakeUp: return ("Energize", "Hold bright", "Exhale slow", "Pause")
        }
    }
}

@Observable
final class WatchSessionManager: NSObject {
    static let shared = WatchSessionManager()

    var sessionType: WatchSessionType = .focus
    var lastMessage: [String: Any]?
    var receivedMessage: UUID = UUID()

    private var wcSession: WCSession?

    override init() {
        super.init()
        setupWCSession()
    }

    private func setupWCSession() {
        guard WCSession.isSupported() else { return }
        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()
    }

    func startSession() {
        sendMessage(["action": "watchStarted"])
    }

    func stopSession() {
        sendMessage(["action": "watchStopped"])
    }

    private func sendMessage(_ message: [String: Any]) {
        guard let session = wcSession, session.isReachable else { return }
        session.sendMessage(message, replyHandler: nil) { error in
            print("WCSession send error: \(error)")
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.lastMessage = message
            self.receivedMessage = UUID()
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.lastMessage = applicationContext
            self.receivedMessage = UUID()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Ready
    }
}

#Preview {
    ContentView()
}
