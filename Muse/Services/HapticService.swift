import CoreHaptics
import UIKit

final class HapticService {
    static let shared = HapticService()

    private var engine: CHHapticEngine?
    private(set) var supportsHaptics: Bool

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "hapticEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "hapticEnabled") }
    }

    init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        if supportsHaptics {
            setupEngine()
        }
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

    func playInhale() {
        guard isEnabled else { return }
        playTransient(intensity: 0.5, sharpness: 0.3)
    }

    func playExhale() {
        guard isEnabled else { return }
        playTransient(intensity: 0.4, sharpness: 0.2)
    }

    func playSessionComplete() {
        guard isEnabled else { return }
        playCompletionPattern()
    }

    private func playTransient(intensity: Float, sharpness: Float) {
        guard supportsHaptics, let engine = engine else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

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

    private func playCompletionPattern() {
        guard supportsHaptics, let engine = engine else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        do {
            // Gentle ascending then descending intensity pattern for "success" feel
            let events: [CHHapticEvent] = [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0,
                    duration: 0.15
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
                    ],
                    relativeTime: 0.15,
                    duration: 0.2
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: 0.35,
                    duration: 0.25
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
