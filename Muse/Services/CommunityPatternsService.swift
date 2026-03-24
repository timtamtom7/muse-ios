import Foundation

// MARK: - Community Pattern Model

struct CommunityPattern: Codable, Identifiable, Equatable {
    let id: UUID
    let pattern: BreathingPattern
    let authorName: String
    let downloads: Int
    let createdAt: Date
    let description: String
    let tags: [String]

    static func == (lhs: CommunityPattern, rhs: CommunityPattern) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Community Patterns Service

@Observable
final class CommunityPatternsService {
    static let shared = CommunityPatternsService()

    private let sharedPatternsKey = "sharedCommunityPatterns"
    private let popularPatternsKey = "popularPatternsThisWeek"
    private let mySharedPatternsKey = "mySharedPatterns"

    var communityPatterns: [CommunityPattern] = []
    var popularPatternsThisWeek: [CommunityPattern] = []
    var mySharedPatterns: [CommunityPattern] = []

    init() {
        loadPatterns()
        seedInitialPatternsIfNeeded()
    }

    private func loadPatterns() {
        // Load community patterns
        if let data = UserDefaults.standard.data(forKey: sharedPatternsKey),
           let decoded = try? JSONDecoder().decode([CommunityPattern].self, from: data) {
            communityPatterns = decoded
        }

        // Load popular patterns
        if let data = UserDefaults.standard.data(forKey: popularPatternsKey),
           let decoded = try? JSONDecoder().decode([CommunityPattern].self, from: data) {
            popularPatternsThisWeek = decoded
        }

        // Load my shared patterns
        if let data = UserDefaults.standard.data(forKey: mySharedPatternsKey),
           let decoded = try? JSONDecoder().decode([CommunityPattern].self, from: data) {
            mySharedPatterns = decoded
        }
    }

    private func saveCommunityPatterns() {
        guard let encoded = try? JSONEncoder().encode(communityPatterns) else { return }
        UserDefaults.standard.set(encoded, forKey: sharedPatternsKey)
    }

    private func savePopularPatterns() {
        guard let encoded = try? JSONEncoder().encode(popularPatternsThisWeek) else { return }
        UserDefaults.standard.set(encoded, forKey: popularPatternsKey)
    }

    private func saveMySharedPatterns() {
        guard let encoded = try? JSONEncoder().encode(mySharedPatterns) else { return }
        UserDefaults.standard.set(encoded, forKey: mySharedPatternsKey)
    }

    private func seedInitialPatternsIfNeeded() {
        guard communityPatterns.isEmpty else { return }

        let seedPatterns: [CommunityPattern] = [
            CommunityPattern(
                id: UUID(),
                pattern: BreathingPattern(
                    id: UUID(),
                    name: "4-7-8 Sleep",
                    inhaleSeconds: 4,
                    holdInSeconds: 7,
                    exhaleSeconds: 8,
                    holdOutSeconds: 0,
                    isBuiltIn: false
                ),
                authorName: "SleepWell",
                downloads: 2847,
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                description: "Classic 4-7-8 technique for falling asleep faster. Promotes deep relaxation.",
                tags: ["sleep", "relaxation", "beginner"]
            ),
            CommunityPattern(
                id: UUID(),
                pattern: BreathingPattern(
                    id: UUID(),
                    name: "Coherent 5.5",
                    inhaleSeconds: 5,
                    holdInSeconds: 0,
                    exhaleSeconds: 5,
                    holdOutSeconds: 0,
                    isBuiltIn: false
                ),
                authorName: "HeartMathFans",
                downloads: 1923,
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                description: "5.5 second breaths for heart rate variability. Used by athletes and meditators.",
                tags: ["hrv", "focus", "advanced"]
            ),
            CommunityPattern(
                id: UUID(),
                pattern: BreathingPattern(
                    id: UUID(),
                    name: "Morning Energizer",
                    inhaleSeconds: 6,
                    holdInSeconds: 0,
                    exhaleSeconds: 2,
                    holdOutSeconds: 0,
                    isBuiltIn: false
                ),
                authorName: "SunriseBreath",
                downloads: 1456,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                description: "Quick energizing pattern to start your day. Short exhales for alertness.",
                tags: ["morning", "energy", "quick"]
            ),
            CommunityPattern(
                id: UUID(),
                pattern: BreathingPattern(
                    id: UUID(),
                    name: "Deep Calm",
                    inhaleSeconds: 3,
                    holdInSeconds: 3,
                    exhaleSeconds: 6,
                    holdOutSeconds: 3,
                    isBuiltIn: false
                ),
                authorName: "ZenMaster",
                downloads: 3102,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                description: "Equal parts calm with extended exhale for parasympathetic activation.",
                tags: ["relaxation", "anxiety", "intermediate"]
            ),
            CommunityPattern(
                id: UUID(),
                pattern: BreathingPattern(
                    id: UUID(),
                    name: "Box Extended",
                    inhaleSeconds: 6,
                    holdInSeconds: 6,
                    exhaleSeconds: 6,
                    holdOutSeconds: 6,
                    isBuiltIn: false
                ),
                authorName: "BoxBreathClub",
                downloads: 987,
                createdAt: Calendar.current.date(byAdding: .hour, value: -12, to: Date())!,
                description: "Extended box breathing for stress relief. Longer holds increase focus.",
                tags: ["focus", "stress", "advanced"]
            )
        ]

        communityPatterns = seedPatterns
        popularPatternsThisWeek = seedPatterns.sorted { $0.downloads > $1.downloads }
        saveCommunityPatterns()
        savePopularPatterns()
    }

    // MARK: - Share Pattern

    func sharePattern(_ pattern: BreathingPattern, description: String, tags: [String]) {
        let communityPattern = CommunityPattern(
            id: UUID(),
            pattern: BreathingPattern(
                id: UUID(),
                name: pattern.name,
                inhaleSeconds: pattern.inhaleSeconds,
                holdInSeconds: pattern.holdInSeconds,
                exhaleSeconds: pattern.exhaleSeconds,
                holdOutSeconds: pattern.holdOutSeconds,
                isBuiltIn: false
            ),
            authorName: "You",
            downloads: 0,
            createdAt: Date(),
            description: description,
            tags: tags
        )

        mySharedPatterns.insert(communityPattern, at: 0)
        communityPatterns.insert(communityPattern, at: 0)
        saveMySharedPatterns()
        saveCommunityPatterns()
    }

    // MARK: - Import Pattern

    func importPattern(_ communityPattern: CommunityPattern) -> BreathingPattern {
        // Return a copy with a new ID so user owns it
        let imported = communityPattern.pattern
        let newPattern = BreathingPattern(
            id: UUID(),
            name: imported.name,
            inhaleSeconds: imported.inhaleSeconds,
            holdInSeconds: imported.holdInSeconds,
            exhaleSeconds: imported.exhaleSeconds,
            holdOutSeconds: imported.holdOutSeconds,
            isBuiltIn: false
        )

        // Track the download
        if let index = communityPatterns.firstIndex(where: { $0.id == communityPattern.id }) {
            var updated = communityPatterns[index]
            updated = CommunityPattern(
                id: updated.id,
                pattern: updated.pattern,
                authorName: updated.authorName,
                downloads: updated.downloads + 1,
                createdAt: updated.createdAt,
                description: updated.description,
                tags: updated.tags
            )
            communityPatterns[index] = updated
            saveCommunityPatterns()
        }

        return newPattern
    }

    // MARK: - Delete My Shared Pattern

    func deleteMySharedPattern(_ pattern: CommunityPattern) {
        mySharedPatterns.removeAll { $0.id == pattern.id }
        communityPatterns.removeAll { $0.id == pattern.id }
        saveMySharedPatterns()
        saveCommunityPatterns()
    }

    // MARK: - Search

    func searchPatterns(query: String) -> [CommunityPattern] {
        guard !query.isEmpty else { return communityPatterns }
        let lowercased = query.lowercased()
        return communityPatterns.filter { cp in
            cp.pattern.name.lowercased().contains(lowercased) ||
            cp.authorName.lowercased().contains(lowercased) ||
            cp.description.lowercased().contains(lowercased) ||
            cp.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }

    // MARK: - Filter by Tag

    func filterByTag(_ tag: String) -> [CommunityPattern] {
        communityPatterns.filter { $0.tags.contains(tag) }
    }

    // MARK: - All Tags

    var allTags: [String] {
        let allTags = communityPatterns.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
}
