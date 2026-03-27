import CoreHaptics
import UIKit

/// iOS 26 Liquid Glass Haptic Service
/// Uses CoreHaptics for rich, immersive feedback during breathing sessions.
final class HapticService {
    static let shared = HapticService()

    private var engine: CHHapticEngine?
    private(set) var supportsHaptics: Bool

    /// Whether haptic feedback is enabled by the user.
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "hapticEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "hapticEnabled") }
    }

    init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        if supportsHaptics {
            setupEngine()
        }
        // Default to enabled if not previously set
        if UserDefaults.standard.object(forKey: "hapticEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "hapticEnabled")
        }
    }

    private func setupEngine() {
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            engine?.stoppedHandler = { _ in }
            try engine?.start()
        } catch {
            engine = nil
        }
    }

    /// Light haptic for inhale start — soft, building sensation.
    func playInhale() {
        guard isEnabled else { return }
        playBreathPhase(intensity: 0.5, sharpness: 0.25, style: .light)
    }

    /// Light haptic for exhale — gentler, releasing sensation.
    func playExhale() {
        guard isEnabled else { return }
        playBreathPhase(intensity: 0.4, sharpness: 0.15, style: .light)
    }

    /// Subtle tick for hold phases — just enough to mark the transition.
    func playHoldTick() {
        guard isEnabled else { return }
        playBreathPhase(intensity: 0.25, sharpness: 0.1, style: .light)
    }

    /// Rich completion pattern for session end — ascending then settling.
    func playSessionComplete() {
        guard isEnabled else { return }
        playCompletionPattern()
    }

    /// Light tap for UI interactions (button taps, selections).
    func playSelection() {
        guard isEnabled else { return }
        if supportsHaptics, let engine = engine {
            playCoreHapticTransient(intensity: 0.3, sharpness: 0.4, engine: engine)
        } else {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    // MARK: - Private

    private enum BreathStyle {
        case light, medium, heavy
    }

    private func playBreathPhase(intensity: Float, sharpness: Float, style: BreathStyle) {
        if supportsHaptics, let engine = engine {
            playCoreHapticTransient(intensity: intensity, sharpness: sharpness, engine: engine)
        } else {
            let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
            switch style {
            case .light:  uiStyle = .light
            case .medium: uiStyle = .medium
            case .heavy:  uiStyle = .heavy
            }
            UIImpactFeedbackGenerator(style: uiStyle).impactOccurred()
        }
    }

    private func playCoreHapticTransient(intensity: Float, sharpness: Float, engine: CHHapticEngine) {
        do {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    /// iOS 26 Liquid Glass completion pattern — three ascending waves then a gentle settle.
    private func playCompletionPattern() {
        if supportsHaptics, let engine = engine {
            playCoreHapticCompletion(engine: engine)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func playCoreHapticCompletion(engine: CHHapticEngine) {
        do {
            // Three ascending waves, then a soft settle
            let events: [CHHapticEvent] = [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0,
                    duration: 0.12
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
                    ],
                    relativeTime: 0.12,
                    duration: 0.15
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.75),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: 0.27,
                    duration: 0.2
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0.47,
                    duration: 0.4
                )
            ]
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
