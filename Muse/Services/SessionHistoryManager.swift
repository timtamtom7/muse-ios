import Foundation

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let durationMinutes: Int
    let completedCycles: Int

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

    func recordSession(durationMinutes: Int, completedCycles: Int) {
        let record = SessionRecord(
            id: UUID(),
            date: Date(),
            durationMinutes: durationMinutes,
            completedCycles: completedCycles
        )
        sessions.insert(record, at: 0)
        if sessions.count > maxHistoryCount {
            sessions = Array(sessions.prefix(maxHistoryCount))
        }
        saveSessions()
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

    var averageDuration: Int {
        guard !sessions.isEmpty else { return 0 }
        return totalMinutes / sessions.count
    }
}
