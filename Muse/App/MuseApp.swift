import SwiftUI
import WatchConnectivity

@main
struct MuseApp: App {
    @State private var onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    @State private var watchSessionManager = iPhoneWatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingComplete {
                    BreatheView()
                } else {
                    OnboardingContainer(onComplete: {
                        withAnimation {
                            onboardingComplete = true
                        }
                    })
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - iPhone Watch Session Manager

@Observable
final class iPhoneWatchSessionManager: NSObject {
    static let shared = iPhoneWatchSessionManager()

    private var wcSession: WCSession?

    var isWatchPaired: Bool {
        wcSession?.isPaired ?? false
    }

    var isWatchReachable: Bool {
        wcSession?.isReachable ?? false
    }

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

    func sendSessionUpdate(session: BreathingSession, sessionType: SessionType) {
        guard let wc = wcSession else { return }

        let context: [String: Any] = [
            "sessionActive": session.isActive,
            "duration": session.totalDuration,
            "elapsed": session.elapsedTime,
            "phase": phaseString(from: session.phase),
            "phaseProgress": session.phaseProgress,
            "sessionType": sessionType.rawValue
        ]

        if session.isActive {
            try? wc.updateApplicationContext(context)
        } else {
            wc.sendMessage(context, replyHandler: nil) { error in
                print("WCSession send error: \(error)")
            }
        }
    }

    private func phaseString(from phase: BreathPhase) -> String {
        switch phase {
        case .idle: return "idle"
        case .inhale: return "inhale"
        case .holdIn: return "holdIn"
        case .exhale: return "exhale"
        case .holdOut: return "holdOut"
        case .complete: return "complete"
        }
    }
}

extension iPhoneWatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Watch session activated
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        // Watch reachability changed
    }
}

struct OnboardingContainer: View {
    let onComplete: () -> Void
    @State private var isComplete = true

    var body: some View {
        OnboardingView(isComplete: $isComplete)
            .onChange(of: isComplete) { _, newValue in
                if !newValue {
                    onComplete()
                }
            }
    }
}
