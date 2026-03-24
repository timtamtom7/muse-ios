import Foundation

enum SessionType: String, CaseIterable, Codable {
    case focus = "Focus"
    case sleep = "Sleep"
    case relax = "Relax"
    case wakeUp = "Wake Up"

    var displayName: String { rawValue }

    var shortName: String {
        switch self {
        case .focus: return "Focus"
        case .sleep: return "Sleep"
        case .relax: return "Relax"
        case .wakeUp: return "Wake"
        }
    }

    var defaultPatternName: String {
        switch self {
        case .focus: return "Box breathing"
        case .sleep: return "Relaxing"
        case .relax: return "Relaxing"
        case .wakeUp: return "Energizing"
        }
    }

    var orbCoreColor: String {
        switch self {
        case .focus: return "f5efe6"    // Warm white
        case .sleep: return "b8c5d6"    // Cool blue-grey
        case .relax: return "e8d5c4"    // Soft beige
        case .wakeUp: return "f5d0a9"   // Warm amber
        }
    }

    var orbGlowColor: String {
        switch self {
        case .focus: return "f0e6d3"    // Warm glow
        case .sleep: return "9fb3cc"    // Blue glow
        case .relax: return "d4c4b0"    // Soft glow
        case .wakeUp: return "e8b87a"   // Amber glow
        }
    }

    var orbHaloColor: String {
        switch self {
        case .focus: return "e8d5c4"
        case .sleep: return "8fa8bf"
        case .relax: return "c9b99a"
        case .wakeUp: return "d4956a"
        }
    }

    var orbHighlightColor: String {
        switch self {
        case .focus: return "fffcf5"
        case .sleep: return "dde8f5"
        case .relax: return "f5ede0"
        case .wakeUp: return "fff0dd"
        }
    }

    var backgroundHex: String {
        switch self {
        case .focus: return "050508"
        case .sleep: return "03040a"
        case .relax: return "080706"
        case .wakeUp: return "0a0805"
        }
    }

    var guidanceMessages: (inhale: String, holdIn: String, exhale: String, holdOut: String) {
        switch self {
        case .focus:
            return ("Breathe in", "Hold", "Breathe out", "Hold")
        case .sleep:
            return ("Slowly breathe in", "Soften", "Release", "Rest")
        case .relax:
            return ("Let breath in", "Release tension", "Breathe out", "Settle")
        case .wakeUp:
            return ("Energize", "Hold bright", "Exhale slow", "Pause")
        }
    }
}

@Observable
final class SessionTypeManager {
    static let shared = SessionTypeManager()

    private let sessionTypeKey = "selectedSessionType"

    var selectedType: SessionType {
        didSet {
            if let encoded = try? JSONEncoder().encode(selectedType) {
                UserDefaults.standard.set(encoded, forKey: sessionTypeKey)
            }
            // Also set default pattern for this session type
            let pattern = BreathingPatternManager.shared.allPatterns.first { $0.name == selectedType.defaultPatternName }
                ?? BreathingPattern.default
            BreathingPatternManager.shared.saveSelectedPattern(pattern)
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: sessionTypeKey),
           let decoded = try? JSONDecoder().decode(SessionType.self, from: data) {
            selectedType = decoded
        } else {
            selectedType = .focus
        }
    }
}
