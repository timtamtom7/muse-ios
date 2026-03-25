import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Beta program service for managing TestFlight feedback and release notes.
final class BetaService: ObservableObject {
    static let shared = BetaService()

    @Published var currentBuildNumber: String = ""
    @Published var currentVersion: String = ""
    @Published var releaseNotes: String = ""

    private init() {
        loadBuildInfo()
    }

    private func loadBuildInfo() {
        // Get version from bundle
        currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        currentBuildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // Load release notes
        loadReleaseNotes()
    }

    private func loadReleaseNotes() {
        // Try to load from bundle
        if let url = Bundle.main.url(forResource: "release_notes", withExtension: "txt"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            releaseNotes = content
        } else {
            // Provide default release notes
            releaseNotes = """
            Thank you for testing Muse!

            This beta build includes:
            • Performance improvements
            • Bug fixes
            • New breathing patterns

            To report feedback:
            1. Tap "Send Beta Feedback" in Settings
            2. Describe the issue or suggestion
            3. Optionally include a screenshot

            Your feedback helps make Muse better for everyone.
            """
        }
    }

    /// Check if running a TestFlight build
    var isTestFlight: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return Bundle.main.appStoreReceiptURL?.path.contains("sandbox") == true ||
               Bundle.main.infoDictionary?["ApplicationType"] as? String == "maccatalyst"
        #endif
    }

    /// Open the TestFlight app to submit feedback
    func openTestFlightFeedback() {
        #if canImport(UIKit) && !os(watchOS)
        if let url = URL(string: "https://testflight.apple.com") {
            UIApplication.shared.open(url)
        }
        #endif
    }

    /// Get the number of days remaining in the TestFlight period
    var testFlightDaysRemaining: Int? {
        guard isTestFlight else { return nil }
        // TestFlight beta typically expires; estimate based on build date
        return nil // In production, parse from TestFlight receipt
    }
}

/// Beta feedback submission model
struct BetaFeedback: Identifiable {
    let id = UUID()
    let timestamp: Date
    let rating: Int // 1-5 stars
    let message: String
    let includeScreenshot: Bool
    let appVersion: String
    let buildNumber: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
