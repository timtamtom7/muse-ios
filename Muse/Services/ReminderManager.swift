import Foundation
import UserNotifications

enum ReminderPermissionStatus {
    case notDetermined
    case denied
    case authorized
}

@Observable
final class ReminderManager {
    static let shared = ReminderManager()

    private let reminderTimeKey = "reminderTime"
    private let reminderEnabledKey = "reminderEnabled"

    var permissionStatus: ReminderPermissionStatus = .notDetermined
    var reminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: reminderEnabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: reminderEnabledKey)
            if newValue {
                scheduleReminder()
            } else {
                cancelReminder()
            }
        }
    }

    var reminderTime: Date {
        get {
            if let interval = UserDefaults.standard.object(forKey: reminderTimeKey) as? TimeInterval {
                return Date(timeIntervalSince1970: interval)
            }
            // Default: 8:00 AM today
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 8
            components.minute = 0
            return calendar.date(from: components) ?? Date()
        }
        set {
            UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: reminderTimeKey)
            if reminderEnabled {
                scheduleReminder()
            }
        }
    }

    var formattedReminderTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: reminderTime)
    }

    init() {
        checkPermissionStatus()
    }

    func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    self.permissionStatus = .notDetermined
                case .denied, .provisional, .ephemeral:
                    self.permissionStatus = .denied
                case .authorized:
                    self.permissionStatus = .authorized
                @unknown default:
                    self.permissionStatus = .notDetermined
                }
            }
        }
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.permissionStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            return false
        }
    }

    func scheduleReminder() {
        cancelReminder()

        guard permissionStatus == .authorized else {
            if permissionStatus == .notDetermined {
                Task {
                    let granted = await requestPermission()
                    if granted {
                        await scheduleReminderInternal()
                    }
                }
            }
            return
        }

        Task {
            await scheduleReminderInternal()
        }
    }

    private func scheduleReminderInternal() async {
        let center = UNUserNotificationCenter.current()

        // Build trigger for daily reminder
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Time to breathe"
        content.body = "Take a moment for yourself today."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "dailyBreathingReminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule reminder: \(error)")
        }
    }

    func scheduleStreakNudge() {
        guard permissionStatus == .authorized else { return }

        let center = UNUserNotificationCenter.current()

        // Nudge in 2 hours if streak at risk
        let triggerDate = Date().addingTimeInterval(2 * 60 * 60)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak"
        content.body = "You have a \(SessionHistoryManager.shared.currentStreak)-day streak. Take 1 minute to keep it alive."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "streakNudge",
            content: content,
            trigger: trigger
        )

        Task {
            try? await center.add(request)
        }
    }

    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyBreathingReminder"])
    }

    func cancelStreakNudge() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streakNudge"])
    }
}
