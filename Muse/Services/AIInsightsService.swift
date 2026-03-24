import Foundation

// MARK: - AI Insight Model

struct AIInsight: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let category: InsightCategory
    let confidence: Double // 0.0 to 1.0
    let actionLabel: String?
    let action: (() -> Void)?

    enum InsightCategory {
        case timePattern
        case durationPattern
        case patternPreference
        case streakMotivation
        case adaptive
    }
}

// MARK: - AI Insights Service

@Observable
final class AIInsightsService {
    static let shared = AIInsightsService()

    private let insightsKey = "cachedInsights"
    private let lastAnalysisKey = "lastInsightAnalysis"

    var insights: [AIInsight] = []
    var suggestedPattern: BreathingPattern?
    var suggestedPatternReason: String?

    private let historyManager = SessionHistoryManager.shared

    init() {
        loadCachedInsights()
    }

    private func loadCachedInsights() {
        // Simple cache — refresh if stale
        if let lastAnalysis = UserDefaults.standard.object(forKey: lastAnalysisKey) as? Date {
            let hoursSinceAnalysis = Calendar.current.dateComponents([.hour], from: lastAnalysis, to: Date()).hour ?? 0
            if hoursSinceAnalysis < 6 {
                return // Keep cached insights
            }
        }
        analyzeAndGenerateInsights()
    }

    // MARK: - Analyze Session History

    func analyzeAndGenerateInsights() {
        let sessions = historyManager.sessions
        guard !sessions.isEmpty else {
            insights = []
            suggestedPattern = nil
            return
        }

        var newInsights: [AIInsight] = []

        // Insight 1: Time of day pattern
        if let timeInsight = analyzeTimeOfDay(sessions: sessions) {
            newInsights.append(timeInsight)
        }

        // Insight 2: Duration preference
        if let durationInsight = analyzeDurationPreference(sessions: sessions) {
            newInsights.append(durationInsight)
        }

        // Insight 3: Pattern preference
        if let patternInsight = analyzePatternPreference(sessions: sessions) {
            newInsights.append(patternInsight)
        }

        // Insight 4: Streak motivation
        if let streakInsight = generateStreakInsight() {
            newInsights.append(streakInsight)
        }

        // Insight 5: Best day of week
        if let dayInsight = analyzeDayOfWeek(sessions: sessions) {
            newInsights.append(dayInsight)
        }

        insights = newInsights
        suggestedPattern = generateAdaptivePattern()
        suggestedPatternReason = generatePatternReason()

        // Cache
        UserDefaults.standard.set(Date(), forKey: lastAnalysisKey)
    }

    // MARK: - Time of Day Analysis

    private func analyzeTimeOfDay(sessions: [SessionRecord]) -> AIInsight? {
        let calendar = Calendar.current
        var hourBuckets: [Int: Int] = [:] // hour -> count

        for session in sessions {
            let hour = calendar.component(.hour, from: session.date)
            hourBuckets[hour, default: 0] += 1
        }

        guard let bestHour = hourBuckets.max(by: { $0.value < $1.value })?.key else {
            return nil
        }

        let hourName: String
        if bestHour >= 5 && bestHour < 12 {
            hourName = "morning"
        } else if bestHour >= 12 && bestHour < 17 {
            hourName = "afternoon"
        } else if bestHour >= 17 && bestHour < 21 {
            hourName = "evening"
        } else {
            hourName = "night"
        }

        let totalSessions = sessions.count
        let bestCount = hourBuckets[bestHour] ?? 0
        let confidence = Double(bestCount) / Double(totalSessions)

        return AIInsight(
            id: UUID(),
            title: "Your best time is the \(hourName)",
            description: "You've completed \(bestCount) of your \(totalSessions) sessions around \(timeString(hour: bestHour)). Your mind is most receptive then.",
            icon: "clock.fill",
            category: .timePattern,
            confidence: confidence,
            actionLabel: nil,
            action: nil
        )
    }

    private func timeString(hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:00 a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    // MARK: - Duration Preference

    private func analyzeDurationPreference(sessions: [SessionRecord]) -> AIInsight? {
        let avgDuration = sessions.reduce(0) { $0 + $1.durationMinutes } / max(sessions.count, 1)

        if avgDuration >= 15 {
            return AIInsight(
                id: UUID(),
                title: "You're a deep breather",
                description: "Your average session is \(avgDuration) minutes. You prefer longer, immersive breathing sessions over quick ones.",
                icon: "hourglass",
                category: .durationPattern,
                confidence: 0.7,
                actionLabel: "Try a 20-min session",
                action: nil
            )
        } else if avgDuration <= 5 {
            return AIInsight(
                id: UUID(),
                title: "Quick breathers are most consistent",
                description: "Your average session is \(avgDuration) minutes. Short, consistent sessions build habits faster.",
                icon: "bolt.fill",
                category: .durationPattern,
                confidence: 0.7,
                actionLabel: nil,
                action: nil
            )
        } else {
            return AIInsight(
                id: UUID(),
                title: "Your sweet spot is \(avgDuration) minutes",
                description: "You've found the balance between effective breathing and practical time management.",
                icon: "checkmark.circle.fill",
                category: .durationPattern,
                confidence: 0.6,
                actionLabel: nil,
                action: nil
            )
        }
    }

    // MARK: - Pattern Preference

    private func analyzePatternPreference(sessions: [SessionRecord]) -> AIInsight? {
        var patternCounts: [String: Int] = [:]
        for session in sessions {
            if let name = session.patternName {
                patternCounts[name, default: 0] += 1
            }
        }

        guard let favorite = patternCounts.max(by: { $0.value < $1.value }) else {
            return nil
        }

        let totalWithName = sessions.filter { $0.patternName != nil }.count
        let confidence = Double(favorite.value) / Double(max(totalWithName, 1))

        return AIInsight(
            id: UUID(),
            title: "\(favorite.key) is your go-to",
            description: "You've used \(favorite.key) \(favorite.value) times. It's clearly your favorite breathing rhythm.",
            icon: "heart.fill",
            category: .patternPreference,
            confidence: confidence,
            actionLabel: "Explore variations",
            action: nil
        )
    }

    // MARK: - Streak Insight

    private func generateStreakInsight() -> AIInsight? {
        let streak = historyManager.currentStreak
        let longest = historyManager.longestStreak

        if streak == 0 {
            return AIInsight(
                id: UUID(),
                title: "Start your streak today",
                description: "Just one session today kicks off a new streak. Many users find streaks motivating.",
                icon: "flame",
                category: .streakMotivation,
                confidence: 1.0,
                actionLabel: nil,
                action: nil
            )
        } else if streak >= longest && longest > 3 {
            return AIInsight(
                id: UUID(),
                title: "You're at your best: \(streak) days",
                description: "This is your longest streak ever. You're building a real habit.",
                icon: "trophy.fill",
                category: .streakMotivation,
                confidence: 1.0,
                actionLabel: nil,
                action: nil
            )
        } else if historyManager.isStreakAtRisk {
            return AIInsight(
                id: UUID(),
                title: "Streak at risk — 1 session saves it",
                description: "Your \(streak)-day streak is about to break. One session today keeps it alive.",
                icon: "exclamationmark.triangle.fill",
                category: .streakMotivation,
                confidence: 1.0,
                actionLabel: "Breathe now",
                action: nil
            )
        } else {
            return AIInsight(
                id: UUID(),
                title: "\(streak)-day streak — keep it going",
                description: "You're \(longest - streak) days from your record. Consistency is the key.",
                icon: "flame.fill",
                category: .streakMotivation,
                confidence: 1.0,
                actionLabel: nil,
                action: nil
            )
        }
    }

    // MARK: - Day of Week Analysis

    private func analyzeDayOfWeek(sessions: [SessionRecord]) -> AIInsight? {
        let calendar = Calendar.current
        var dayBuckets: [Int: Int] = [:]

        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.date)
            dayBuckets[weekday, default: 0] += 1
        }

        guard let bestDay = dayBuckets.max(by: { $0.value < $1.value })?.key else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        var components = DateComponents()
        components.weekday = bestDay
        let dayName: String
        if let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
            dayName = formatter.string(from: date)
        } else {
            dayName = "this day"
        }

        return AIInsight(
            id: UUID(),
            title: "\(dayName)s are your strongest",
            description: "You tend to complete more sessions on \(dayName)s. Schedule your breathing practice then.",
            icon: "calendar",
            category: .timePattern,
            confidence: 0.6,
            actionLabel: nil,
            action: nil
        )
    }

    // MARK: - Adaptive Pattern Suggestion

    private func generateAdaptivePattern() -> BreathingPattern? {
        let hour = Calendar.current.component(.hour, from: Date())

        // Time-based adaptive pattern
        if hour >= 5 && hour < 10 {
            // Morning — energizing
            return BreathingPattern(
                id: UUID(),
                name: "Morning Adaptive",
                inhaleSeconds: 5,
                holdInSeconds: 2,
                exhaleSeconds: 3,
                holdOutSeconds: 1,
                isBuiltIn: false
            )
        } else if hour >= 10 && hour < 17 {
            // Midday — focus
            return BreathingPattern(
                id: UUID(),
                name: "Midday Focus",
                inhaleSeconds: 4,
                holdInSeconds: 4,
                exhaleSeconds: 4,
                holdOutSeconds: 4,
                isBuiltIn: false
            )
        } else if hour >= 17 && hour < 21 {
            // Evening — unwind
            return BreathingPattern(
                id: UUID(),
                name: "Evening Unwind",
                inhaleSeconds: 4,
                holdInSeconds: 2,
                exhaleSeconds: 6,
                holdOutSeconds: 2,
                isBuiltIn: false
            )
        } else {
            // Night — sleep
            return BreathingPattern(
                id: UUID(),
                name: "Night Wind Down",
                inhaleSeconds: 4,
                holdInSeconds: 7,
                exhaleSeconds: 8,
                holdOutSeconds: 0,
                isBuiltIn: false
            )
        }
    }

    private func generatePatternReason() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour >= 5 && hour < 10 {
            return "Morning breath for alertness. Short exhales activate your sympathetic system."
        } else if hour >= 10 && hour < 17 {
            return "Focus breathing for productivity. Box pattern maximizes oxygen uptake."
        } else if hour >= 17 && hour < 21 {
            return "Evening unwinding. Extended exhale activates parasympathetic rest."
        } else {
            return "Night wind-down. 4-7-8 pattern is clinically shown to promote sleep."
        }
    }

    // MARK: - Refresh Insights

    func refreshInsights() {
        analyzeAndGenerateInsights()
    }
}
