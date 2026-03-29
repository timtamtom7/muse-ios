import Foundation
import NaturalLanguage

// MARK: - Listening Insights

struct ListeningInsights: Equatable {
    let totalListeningMinutes: Int
    let favoriteGenres: [GenreCount]
    let peakListeningHours: [Int]
    let newGenresDiscovered: Int
    let averageSessionMinutes: Int
    let weeklyListeningMinutes: [Int]
    let topArtists: [ArtistCount]

    var totalListeningHours: Double {
        Double(totalListeningMinutes) / 60.0
    }

    static let empty = ListeningInsights(
        totalListeningMinutes: 0,
        favoriteGenres: [],
        peakListeningHours: [],
        newGenresDiscovered: 0,
        averageSessionMinutes: 0,
        weeklyListeningMinutes: Array(repeating: 0, count: 7),
        topArtists: []
    )
}

struct GenreCount: Equatable, Identifiable {
    var id: String { genre }
    let genre: String
    let count: Int
    var percentage: Double = 0
}

struct ArtistCount: Equatable, Identifiable {
    var id: String { artist }
    let artist: String
    let playCount: Int
}

struct Recommendation: Identifiable, Equatable {
    let id = UUID()
    let track: Track
    let score: Double
    let reason: String
}

// MARK: - Mood Categories

enum PlaylistMood: String, CaseIterable, Identifiable {
    case focus = "Focus"
    case workout = "Workout"
    case dinner = "Dinner"
    case commute = "Commute"
    case chill = "Chill"
    case party = "Party"
    case sleep = "Sleep"
    case roadTrip = "Road Trip"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .focus: return "Deep work and concentration"
        case .workout: return "High energy training"
        case .dinner: return "Ambient dining atmosphere"
        case .commute: return "Your daily journey"
        case .chill: return "Relaxed and mellow vibes"
        case .party: return "Upbeat crowd favorites"
        case .sleep: return "Wind down and rest"
        case .roadTrip: return "Adventures on the road"
        }
    }

    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .workout: return "flame.fill"
        case .dinner: return "fork.knife"
        case .commute: return "car.fill"
        case .chill: return "leaf.fill"
        case .party: return "party.popper.fill"
        case .sleep: return "moon.fill"
        case .roadTrip: return "map.fill"
        }
    }

    var targetBPMRange: ClosedRange<Double> {
        switch self {
        case .focus: return 60...80
        case .workout: return 140...180
        case .dinner: return 85...110
        case .commute: return 90...120
        case .chill: return 70...95
        case .party: return 110...140
        case .sleep: return 50...70
        case .roadTrip: return 100...130
        }
    }
}

// MARK: - AI Music Service

final class AIMusicService: ObservableObject, @unchecked Sendable {
    nonisolated(unsafe) static let shared = AIMusicService()

    @Published var lastInsights: ListeningInsights = .empty
    @Published var recentRecommendations: [Recommendation] = []

    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])

    private init() {}

    // MARK: - Recommendations

    func getRecommendations(for track: Track, from library: [Track]) -> [Track] {
        guard !library.isEmpty else { return [] }

        let scored = library
            .filter { $0.id != track.id }
            .map { candidate -> (Track, Double) in
                let score = computeSimilarity(between: track, and: candidate)
                return (candidate, score)
            }
            .filter { $0.1 > 0.2 }
            .sorted { $0.1 > $1.1 }
            .prefix(10)

        return scored.map { $0.0 }
    }

    func getRecommendations(for track: Track, from library: [Track]) -> [Recommendation] {
        guard !library.isEmpty else { return [] }

        let candidates = library.filter { $0.id != track.id }

        let similar = candidates
            .map { candidate -> (Track, Double, String) in
                let score = computeSimilarity(between: track, and: candidate)
                let reason = generateReason(shared: track, candidate: candidate, score: score)
                return (candidate, score, reason)
            }
            .filter { $0.1 > 0.15 }
            .sorted { $0.1 > $1.1 }
            .prefix(15)

        return similar.map { Recommendation(track: $0.0, score: $0.1, reason: $0.2) }
    }

    private func computeSimilarity(between source: Track, and candidate: Track) -> Double {
        var score: Double = 0
        var factors: Double = 0

        // Artist similarity (40% weight)
        let artistSim = stringSimilarity(source.artist, candidate.artist)
        score += artistSim * 0.4
        factors += 0.4

        // Album era similarity (20% weight) — based on duration as proxy
        let durationSim = durationSimilarity(source.duration, candidate.duration)
        score += durationSim * 0.2
        factors += 0.2

        // Title mood similarity (20% weight)
        let titleSim = textSimilarity(source.title, candidate.title)
        score += titleSim * 0.2
        factors += 0.2

        // Album similarity (20% weight)
        let albumSim = stringSimilarity(source.album, candidate.album)
        score += albumSim * 0.2
        factors += 0.2

        return factors > 0 ? score / factors : 0
    }

    private func stringSimilarity(_ a: String, _ b: String) -> Double {
        let aLower = a.lowercased()
        let bLower = b.lowercased()
        if aLower == bLower { return 1.0 }

        // Check if one contains the other
        if aLower.contains(bLower) || bLower.contains(aLower) {
            return 0.7
        }

        // Extract key tokens
        let aTokens = extractKeywords(from: aLower)
        let bTokens = extractKeywords(from: bLower)

        let intersection = aTokens.intersection(bTokens)
        let union = aTokens.union(bTokens)

        guard !union.isEmpty else { return 0 }
        return Double(intersection.count) / Double(union.count) * 0.8
    }

    private func extractKeywords(from text: String) -> Set<String> {
        tagger.string = text
        var keywords = Set<String>()
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, _ in
            if let tag = tag, [.noun, .verb, .adjective].contains(tag) {
                let token = String(text[tagger.string.startIndex..<text.endIndex]).lowercased()
                keywords.insert(token)
            }
            return true
        }

        // Also add n-grams for artist names
        let words = text.split(separator: " ").map { String($0) }
        for i in 0..<words.count {
            for j in (i+1)...min(i+2, words.count) {
                keywords.insert(words[i..<j].joined(separator: " "))
            }
        }

        return keywords
    }

    private func textSimilarity(_ a: String, _ b: String) -> Double {
        let aClean = a.lowercased()
        let bClean = b.lowercased()
        if aClean == bClean { return 1.0 }

        let aTokens = Set(aClean.split(separator: " ").map { String($0) })
        let bTokens = Set(bClean.split(separator: " ").map { String($0) })

        let intersection = aTokens.intersection(bTokens)
        let union = aTokens.union(bTokens)

        guard !union.isEmpty else { return 0 }

        // Boost if keywords match
        let aKeywords = extractKeywords(from: aClean)
        let bKeywords = extractKeywords(from: bClean)
        let keywordBoost = aKeywords.intersection(bKeywords).isEmpty ? 0.0 : 0.2

        return Double(intersection.count) / Double(union.count) + keywordBoost
    }

    private func durationSimilarity(_ a: TimeInterval, _ b: TimeInterval) -> Double {
        let ratio = max(a, b) / min(a, b)
        if ratio <= 1.1 { return 1.0 }
        if ratio <= 1.3 { return 0.8 }
        if ratio <= 1.6 { return 0.5 }
        return 0.2
    }

    private func generateReason(shared: Track, candidate: Track, score: Double) -> String {
        if stringSimilarity(shared.artist, candidate.artist) > 0.6 {
            return "Same artist vibe — \(candidate.artist)"
        } else if stringSimilarity(shared.album, candidate.album) > 0.5 {
            return "From the same album world: \(candidate.album)"
        } else if textSimilarity(shared.title, candidate.title) > 0.3 {
            return "Similar mood to \"\(shared.title)\""
        } else if durationSimilarity(shared.duration, candidate.duration) > 0.8 {
            return "Same energy & length"
        } else {
            return "Handpicked for your taste"
        }
    }

    // MARK: - Playlist Generation

    func generatePlaylist(for mood: PlaylistMood, from library: [Track], count: Int = 25) -> [Track] {
        guard !library.isEmpty else { return [] }

        let targetBPM = mood.targetBPMRange
        let candidates = library.filter { candidate in
            // Duration-based BPM proxy
            let bpmProxy = estimateBPM(for: candidate)
            return targetBPM.contains(bpmProxy) || targetBPM.expanded(by: 20).contains(bpmProxy)
        }

        // If not enough candidates, fall back to all tracks
        let pool = candidates.isEmpty ? library : candidates

        // Sort by mood fitness
        let scored = pool.map { track -> (Track, Double) in
            let bpmProxy = estimateBPM(for: track)
            let fitness: Double
            if targetBPM.contains(bpmProxy) {
                fitness = 1.0
            } else {
                let center = (targetBPM.lowerBound + targetBPM.upperBound) / 2
                let dist = abs(bpmProxy - center)
                fitness = max(0.3, 1.0 - (dist / 50.0))
            }
            return (track, fitness)
        }
        .shuffled()
        .sorted { $0.1 > $1.1 }

        let selected = scored.prefix(count).map { $0.0 }

        // Ensure variety (different artists)
        var result: [Track] = []
        var usedArtists = Set<String>()
        for track in selected {
            if result.count >= count { break }
            if !usedArtists.contains(track.artist) || Double(result.filter { $0.artist == track.artist }.count) < Double(count) * 0.3 {
                result.append(track)
                usedArtists.insert(track.artist)
            }
        }

        return result
    }

    private func estimateBPM(for track: Track) -> Double {
        // Estimate BPM from track duration
        // Short tracks (~2-3 min) tend to be faster, longer ones slower
        let minutes = track.duration / 60.0
        if minutes < 2.5 { return 140 }
        if minutes < 3.5 { return 120 }
        if minutes < 4.5 { return 100 }
        return 85
    }

    // MARK: - Listening Pattern Analysis

    func analyzeListeningPatterns(tracks: [Track]) -> ListeningInsights {
        guard !tracks.isEmpty else { return .empty }

        // Genre breakdown — use artist+album keyword analysis
        let genreKeywords: [String: [String]] = [
            "Electronic": ["electronic", "edm", "synth", "techno", "house", "dance"],
            "Indie": ["indie", "alternative", "dream", "shoegaze", "lo-fi"],
            "Rock": ["rock", "metal", "punk", "grunge", "hardcore"],
            "Pop": ["pop", "dance", "chart", "radio"],
            "R&B": ["r&b", "soul", "funk", "disco", "motown"],
            "Hip-Hop": ["hip-hop", "rap", "trap", "drill"],
            "Classical": ["symphony", "orchestra", "concerto", "sonata", "classical"],
            "Jazz": ["jazz", "swing", "bebop", "fusion"],
            "80s": ["80s", "synthwave", "new wave", "retro"],
            "Folk": ["folk", "acoustic", "country", "americana"],
        ]

        var genreCounts: [String: Int] = [:]
        for track in tracks {
            let searchText = "\(track.artist) \(track.album) \(track.title)".lowercased()
            var matched = false
            for (genre, keywords) in genreKeywords {
                for keyword in keywords {
                    if searchText.contains(keyword) {
                        genreCounts[genre, default: 0] += 1
                        matched = true
                        break
                    }
                }
            }
            if !matched {
                genreCounts["Other", default: 0] += 1
            }
        }

        let total = max(genreCounts.values.reduce(0, +), 1)
        let sortedGenres = genreCounts
            .map { GenreCount(genre: $0.key, count: $0.value) }
            .map { gc in
                var mutable = gc
                mutable.percentage = Double(gc.count) / Double(total) * 100
                return mutable
            }
            .sorted { $0.count > $1.count }

        // Artist counts
        var artistPlayCounts: [String: Int] = [:]
        for track in tracks {
            artistPlayCounts[track.artist, default: 0] += 1
        }
        let topArtists = artistPlayCounts
            .map { ArtistCount(artist: $0.key, playCount: $0.value) }
            .sorted { $0.playCount > $1.playCount }
            .prefix(5)

        // Total listening time estimate
        let totalMinutes = tracks.reduce(0) { $0 + Int($1.duration / 60) }

        // Peak hours — simulate based on library size (real impl would use timestamps)
        let peakHours = (tracks.count > 10) ? [8, 12, 18, 21] : [18, 21]

        // Weekly distribution — simulate
        let weeklyMinutes = (0..<7).map { day in
            let base = totalMinutes / max(tracks.count, 1)
            let variance = [1.2, 0.8, 0.6, 0.7, 1.0, 1.5, 1.3][day]
            return Int(Double(base) * variance)
        }

        return ListeningInsights(
            totalListeningMinutes: totalMinutes,
            favoriteGenres: Array(sortedGenres.prefix(5)),
            peakListeningHours: peakHours,
            newGenresDiscovered: max(1, sortedGenres.count / 2),
            averageSessionMinutes: tracks.isEmpty ? 0 : totalMinutes / max(tracks.count / 10, 1),
            weeklyListeningMinutes: weeklyMinutes,
            topArtists: Array(topArtists)
        )
    }

    // MARK: - For LibraryService Integration

    func updateInsights(from tracks: [Track]) {
        let insights = analyzeListeningPatterns(tracks: tracks)
        DispatchQueue.main.async {
            self.lastInsights = insights
        }
    }

    func refreshRecommendations(for track: Track, library: [Track]) {
        let recs = getRecommendations(for: track, from: library)
        DispatchQueue.main.async {
            self.recentRecommendations = recs
        }
    }
}

// MARK: - ClosedRange Extension

extension ClosedRange where Bound == Double {
    func expanded(by delta: Double) -> ClosedRange<Double> {
        return (lowerBound - delta)...(upperBound + delta)
    }
}
