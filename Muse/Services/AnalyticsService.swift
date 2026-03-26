import Foundation

/// Lightweight analytics service for tracking anonymous usage data.
/// Opt-in only - disabled by default.
final class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    @Published private(set) var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.analyticsEnabled)
        }
    }

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Keys.analyticsEnabled)
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    /// Track an analytics event (only if analytics is enabled)
    func track(_ event: String, params: [String: Any]? = nil) {
        guard isEnabled else { return }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry: [String: Any] = [
            "event": event,
            "timestamp": timestamp,
            "params": params ?? [:]
        ]
        // Log to a local file (in production, this would send to an analytics endpoint)
        #if DEBUG
        print("[Analytics] \(event): \(params ?? [:])")
        #endif
        appendToLog(entry)
    }

    // MARK: - Session Tracking

    func trackSessionStarted(duration: Int, patternName: String?) {
        track("session_started", params: [
            "duration": duration,
            "pattern": patternName ?? "unknown"
        ])
    }

    func trackSessionCompleted(duration: Int, patternName: String?) {
        track("session_completed", params: [
            "duration": duration,
            "pattern": patternName ?? "unknown"
        ])
    }

    func trackSessionInterrupted(duration: Int) {
        track("session_interrupted", params: ["duration": duration])
    }

    // MARK: - Pattern Tracking

    func trackPatternSelected(name: String) {
        track("pattern_selected", params: ["pattern": name])
    }

    func trackCustomPatternCreated(name: String) {
        track("custom_pattern_created", params: ["pattern": name])
    }

    func trackCommunityPatternImported(name: String) {
        track("community_pattern_imported", params: ["pattern": name])
    }

    // MARK: - Subscription

    func trackSubscriptionViewed(tier: String) {
        track("subscription_viewed", params: ["tier": tier])
    }

    func trackUpgradeAttempted(fromTier: String, toTier: String) {
        track("upgrade_attempted", params: [
            "from_tier": fromTier,
            "to_tier": toTier
        ])
    }

    func trackSubscriptionPurchased(tier: String) {
        track("subscription_purchased", params: ["tier": tier])
    }

    // MARK: - Error Tracking

    func trackError(_ error: String, context: String) {
        track("error", params: [
            "error": error,
            "context": context
        ])
    }

    // MARK: - Private

    private func appendToLog(_ entry: [String: Any]) {
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let logDir = docsDir.appendingPathComponent("analytics", isDirectory: true)

        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = dateFormatter.string(from: Date()) + ".jsonl"
        let fileURL = logDir.appendingPathComponent(fileName)

        guard let data = try? JSONSerialization.data(withJSONObject: entry) else { return }
        let line = String(data: data, encoding: .utf8)! + "\n"
        try? line.appendToURL(fileURL)
    }

    private enum Keys {
        static let analyticsEnabled = "analytics_opt_in"
    }
}

private extension String {
    func appendToURL(_ url: URL) throws {
        let handle = try FileHandle(forWritingTo: url)
        handle.seekToEndOfFile()
        if let data = self.data(using: .utf8) {
            handle.write(data)
        }
        try handle.close()
    }
}
