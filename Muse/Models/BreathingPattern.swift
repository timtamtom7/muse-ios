import Foundation

struct BreathingPattern: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var inhaleSeconds: Double
    var holdInSeconds: Double
    var exhaleSeconds: Double
    var holdOutSeconds: Double
    var isBuiltIn: Bool

    var totalCycleDuration: Double {
        inhaleSeconds + holdInSeconds + exhaleSeconds + holdOutSeconds
    }

    var displayTitle: String { name }

    static let boxBreathing = BreathingPattern(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Box breathing",
        inhaleSeconds: 4,
        holdInSeconds: 4,
        exhaleSeconds: 4,
        holdOutSeconds: 4,
        isBuiltIn: true
    )

    static let relaxing = BreathingPattern(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Relaxing",
        inhaleSeconds: 4,
        holdInSeconds: 2,
        exhaleSeconds: 6,
        holdOutSeconds: 2,
        isBuiltIn: true
    )

    static let energizing = BreathingPattern(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Energizing",
        inhaleSeconds: 4,
        holdInSeconds: 0,
        exhaleSeconds: 4,
        holdOutSeconds: 0,
        isBuiltIn: true
    )

    static let builtInPatterns: [BreathingPattern] = [
        .boxBreathing,
        .relaxing,
        .energizing
    ]

    static let `default` = boxBreathing

    static func == (lhs: BreathingPattern, rhs: BreathingPattern) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
final class BreathingPatternManager {
    static let shared = BreathingPatternManager()

    private let patternsKey = "customBreathingPatterns"
    private let selectedPatternKey = "selectedBreathingPattern"

    var customPatterns: [BreathingPattern] = []
    var selectedPattern: BreathingPattern = .default

    init() {
        loadCustomPatterns()
        loadSelectedPattern()
    }

    var allPatterns: [BreathingPattern] {
        BreathingPattern.builtInPatterns + customPatterns
    }

    private func loadCustomPatterns() {
        guard let data = UserDefaults.standard.data(forKey: patternsKey),
              let decoded = try? JSONDecoder().decode([BreathingPattern].self, from: data) else {
            customPatterns = []
            return
        }
        customPatterns = decoded
    }

    private func saveCustomPatterns() {
        guard let encoded = try? JSONEncoder().encode(customPatterns) else { return }
        UserDefaults.standard.set(encoded, forKey: patternsKey)
    }

    private func loadSelectedPattern() {
        guard let data = UserDefaults.standard.data(forKey: selectedPatternKey),
              let decoded = try? JSONDecoder().decode(BreathingPattern.self, from: data) else {
            selectedPattern = .default
            return
        }
        selectedPattern = decoded
    }

    func saveSelectedPattern(_ pattern: BreathingPattern) {
        selectedPattern = pattern
        guard let encoded = try? JSONEncoder().encode(pattern) else { return }
        UserDefaults.standard.set(encoded, forKey: selectedPatternKey)
    }

    func addCustomPattern(_ pattern: BreathingPattern) {
        customPatterns.append(pattern)
        saveCustomPatterns()
    }

    func updateCustomPattern(_ pattern: BreathingPattern) {
        if let index = customPatterns.firstIndex(where: { $0.id == pattern.id }) {
            customPatterns[index] = pattern
            saveCustomPatterns()
        }
    }

    func deleteCustomPattern(_ pattern: BreathingPattern) {
        customPatterns.removeAll { $0.id == pattern.id }
        saveCustomPatterns()
        if selectedPattern.id == pattern.id {
            saveSelectedPattern(.default)
        }
    }
}
