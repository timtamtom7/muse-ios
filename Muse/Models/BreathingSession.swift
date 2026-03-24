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

    var pattern: BreathingPattern = .default

    var inhaleDuration: TimeInterval { pattern.inhaleSeconds }
    var holdInDuration: TimeInterval { pattern.holdInSeconds }
    var exhaleDuration: TimeInterval { pattern.exhaleSeconds }
    var holdOutDuration: TimeInterval { pattern.holdOutSeconds }

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
        guard cycleDuration > 0 else {
            phase = .complete
            isActive = false
            return
        }

        let cyclePosition = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        let totalPhases = 4
        let phaseLength = cycleDuration / Double(totalPhases)

        if cyclePosition < phaseLength {
            phase = .inhale
            phaseProgress = inhaleDuration > 0 ? cyclePosition / phaseLength : 1.0
        } else if cyclePosition < phaseLength * 2 {
            phase = .holdIn
            phaseProgress = holdInDuration > 0 ? (cyclePosition - phaseLength) / phaseLength : 1.0
        } else if cyclePosition < phaseLength * 3 {
            phase = .exhale
            phaseProgress = exhaleDuration > 0 ? (cyclePosition - phaseLength * 2) / phaseLength : 1.0
        } else if cyclePosition < cycleDuration {
            phase = .holdOut
            phaseProgress = holdOutDuration > 0 ? (cyclePosition - phaseLength * 3) / phaseLength : 1.0
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

    func applyPattern(_ pattern: BreathingPattern) {
        session.pattern = pattern
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

import Foundation

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let durationMinutes: Int
    let completedCycles: Int
    var patternName: String?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

@Observable
final class SessionHistoryManager {
    static let shared = SessionHistoryManager()

    private let historyKey = "sessionHistory"
    private let streakKey = "sessionStreak"
    private let maxHistoryCount = 500

    var sessions: [SessionRecord] = []

    init() {
        loadSessions()
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data) else {
            sessions = []
            return
        }
        sessions = decoded
    }

    private func saveSessions() {
        guard let encoded = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(encoded, forKey: historyKey)
    }

    func recordSession(durationMinutes: Int, completedCycles: Int, patternName: String? = nil) {
        let record = SessionRecord(
            id: UUID(),
            date: Date(),
            durationMinutes: durationMinutes,
            completedCycles: completedCycles,
            patternName: patternName
        )
        sessions.insert(record, at: 0)
        if sessions.count > maxHistoryCount {
            sessions = Array(sessions.prefix(maxHistoryCount))
        }
        saveSessions()
        updateStreak()
    }

    func clearHistory() {
        sessions = []
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    func deleteSession(_ session: SessionRecord) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.durationMinutes }
    }

    var totalSessions: Int {
        sessions.count
    }

    var sessionsThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.date >= weekAgo }.count
    }

    var minutesThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.durationMinutes }
    }

    var averageDurationMinutes: Int {
        guard !sessions.isEmpty else { return 0 }
        return totalMinutes / sessions.count
    }

    var currentStreak: Int {
        get {
            UserDefaults.standard.integer(forKey: streakKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: streakKey)
        }
    }

    var longestStreak: Int {
        get {
            UserDefaults.standard.integer(forKey: "longestStreak")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "longestStreak")
        }
    }

    /// Returns true if the user has no session today (streak at risk)
    var isStreakAtRisk: Bool {
        guard let lastSession = sessions.first else { return false }
        let calendar = Calendar.current
        if calendar.isDateInToday(lastSession.date) { return false }
        // If streak > 0 and no session today, it's at risk
        return currentStreak > 0
    }

    /// Returns true if streak is already broken
    var isStreakBroken: Bool {
        guard currentStreak > 0 else { return false }
        guard let lastSession = sessions.first else { return true }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastSessionDay = calendar.startOfDay(for: lastSession.date)
        let daysDiff = calendar.dateComponents([.day], from: lastSessionDay, to: today).day ?? 0
        return daysDiff > 1
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastSession = sessions.first {
            let lastSessionDay = calendar.startOfDay(for: lastSession.date)
            let daysDiff = calendar.dateComponents([.day], from: lastSessionDay, to: today).day ?? 0

            if daysDiff == 0 {
                // Same day, streak unchanged
            } else if daysDiff == 1 {
                // Consecutive day, increment streak
                currentStreak += 1
            } else {
                // Streak broken, reset to 1 (today counts)
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }
}
