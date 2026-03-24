import SwiftUI
import Combine

enum BreathPhase {
    case idle
    case inhale
    case holdIn
    case exhale
    case holdOut
    case complete
}

struct BreathingSession {
    var totalDuration: TimeInterval = 600 // 10 minutes default
    var elapsedTime: TimeInterval = 0
    var phase: BreathPhase = .idle
    var isActive: Bool = false

    let inhaleDuration: TimeInterval = 4
    let holdInDuration: TimeInterval = 2
    let exhaleDuration: TimeInterval = 4
    let holdOutDuration: TimeInterval = 2

    var phaseProgress: Double = 0.0 // 0.0 to 1.0 within current phase
    var overallProgress: Double { elapsedTime / totalDuration }

    var currentPhaseDuration: TimeInterval {
        switch phase {
        case .idle: return 0
        case .inhale: return inhaleDuration
        case .holdIn: return holdInDuration
        case .exhale: return exhaleDuration
        case .holdOut: return holdOutDuration
        case .complete: return 0
        }
    }

    mutating func update(elapsed: TimeInterval) {
        guard isActive else { return }
        elapsedTime = elapsed

        let cycleDuration = inhaleDuration + holdInDuration + exhaleDuration + holdOutDuration
        let cyclePosition = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        let totalPhases = 4
        let phaseLength = cycleDuration / Double(totalPhases)

        if cyclePosition < phaseLength {
            phase = .inhale
            phaseProgress = cyclePosition / phaseLength
        } else if cyclePosition < phaseLength * 2 {
            phase = .holdIn
            phaseProgress = (cyclePosition - phaseLength) / phaseLength
        } else if cyclePosition < phaseLength * 3 {
            phase = .exhale
            phaseProgress = (cyclePosition - phaseLength * 2) / phaseLength
        } else if cyclePosition < cycleDuration {
            phase = .holdOut
            phaseProgress = (cyclePosition - phaseLength * 3) / phaseLength
        }

        if elapsed >= totalDuration {
            phase = .complete
            isActive = false
        }
    }

    mutating func start() {
        elapsedTime = 0
        phase = .inhale
        isActive = true
    }

    mutating func stop() {
        isActive = false
        phase = .idle
        elapsedTime = 0
        phaseProgress = 0
    }
}

@Observable
final class BreathingSessionManager {
    var session = BreathingSession()
    var lastPhase: BreathPhase = .idle

    var remainingTime: TimeInterval {
        max(0, session.totalDuration - session.elapsedTime)
    }

    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func start() {
        session.start()
    }

    func stop() {
        session.stop()
    }

    func tick(elapsed: TimeInterval) {
        let prevPhase = session.phase
        session.update(elapsed: elapsed)
        if session.phase != prevPhase {
            lastPhase = prevPhase
        }
    }
}
