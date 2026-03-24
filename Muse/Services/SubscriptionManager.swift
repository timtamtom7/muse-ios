import Foundation

enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case practice = "practice"
    case master = "master"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .practice: return "Practice"
        case .master: return "Master"
        }
    }

    var price: String {
        switch self {
        case .free: return "Free"
        case .practice: return "$4.99/mo"
        case .master: return "$9.99/mo"
        }
    }

    var monthlyPrice: Double {
        switch self {
        case .free: return 0
        case .practice: return 4.99
        case .master: return 9.99
        }
    }

    var tagline: String {
        switch self {
        case .free: return "Start your practice"
        case .practice: return "Breathe deeper"
        case .master: return "Full mastery"
        }
    }

    var sessionsPerDay: Int {
        switch self {
        case .free: return 5
        case .practice: return Int.max
        case .master: return Int.max
        }
    }

    var minDurationMinutes: Int {
        switch self {
        case .free: return 1
        case .practice: return 5
        case .master: return 5
        }
    }

    var maxDurationMinutes: Int {
        switch self {
        case .free: return 10
        case .practice: return 45
        case .master: return 60
        }
    }

    var hasSessionHistory: Bool {
        switch self {
        case .free: return false
        case .practice, .master: return true
        }
    }

    var hasCustomBreathingPatterns: Bool {
        switch self {
        case .free, .practice: return false
        case .master: return true
        }
    }

    var hasGuidedBreathHolds: Bool {
        switch self {
        case .free, .practice: return false
        case .master: return true
        }
    }

    var hasHapticPatterns: Bool {
        switch self {
        case .free, .practice: return false
        case .master: return true
        }
    }

    var hasAppleWatchCompanion: Bool {
        switch self {
        case .free, .practice: return false
        case .master: return true
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "5 sessions per day",
                "1–10 minute sessions",
                "Core breathing guide",
                "Basic haptics"
            ]
        case .practice:
            return [
                "Unlimited sessions",
                "5–45 minute sessions",
                "Session history",
                "Core breathing guide",
                "Enhanced haptics"
            ]
        case .master:
            return [
                "Everything in Practice",
                "5–60 minute sessions",
                "Custom breathing patterns",
                "Guided breath holds",
                "Advanced haptic patterns",
                "Apple Watch companion"
            ]
        }
    }
}

@Observable
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    private let tierKey = "subscriptionTier"
    private let dailySessionsKey = "dailySessionsCount"
    private let lastSessionDateKey = "lastSessionDate"

    var currentTier: SubscriptionTier {
        get {
            guard let raw = UserDefaults.standard.string(forKey: tierKey),
                  let tier = SubscriptionTier(rawValue: raw) else {
                return .free
            }
            return tier
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: tierKey)
        }
    }

    var isSubscribed: Bool {
        currentTier != .free
    }

    var canStartSession: Bool {
        if currentTier == .free {
            return sessionsUsedToday < currentTier.sessionsPerDay
        }
        return true
    }

    var sessionsUsedToday: Int {
        get {
            resetDailyCountIfNeeded()
            return UserDefaults.standard.integer(forKey: dailySessionsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: dailySessionsKey)
        }
    }

    var remainingSessionsToday: Int {
        max(0, currentTier.sessionsPerDay - sessionsUsedToday)
    }

    var availableDurations: [Int] {
        let min = currentTier.minDurationMinutes
        let max = currentTier.maxDurationMinutes
        let defaults = [1, 2, 5, 10, 15, 20, 30, 45, 60]
        return defaults.filter { $0 >= min && $0 <= max }
    }

    private func resetDailyCountIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDateKey = "lastSessionDate"

        if let lastDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date {
            if !Calendar.current.isDate(lastDate, inSameDayAs: today) {
                UserDefaults.standard.set(0, forKey: dailySessionsKey)
                UserDefaults.standard.set(today, forKey: lastDateKey)
            }
        } else {
            UserDefaults.standard.set(today, forKey: lastDateKey)
        }
    }

    func recordSession() {
        if currentTier == .free {
            sessionsUsedToday += 1
        }
    }

    func canUseDuration(_ minutes: Int) -> Bool {
        minutes >= currentTier.minDurationMinutes && minutes <= currentTier.maxDurationMinutes
    }

    func upgradePrompt(for feature: String) -> String {
        switch feature {
        case "history":
            return "Session history is available with Practice or Master."
        case "custom_patterns":
            return "Custom breathing patterns are available with Master."
        case "extended_duration":
            return "Extended durations are available with Practice or Master."
        default:
            return "Upgrade to \(SubscriptionTier.practice.displayName) or \(SubscriptionTier.master.displayName) for more."
        }
    }
}
