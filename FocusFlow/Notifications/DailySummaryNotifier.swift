import Foundation
import UserNotifications

class DailySummaryNotifier {
    static let shared = DailySummaryNotifier()
    
    private init() {}
    
    func scheduleDailySummaryNotification(at hour: Int = 18) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyFocusSummary"])
        
        updateNotificationContent(hour: hour)
    }
    
    func updateNotificationContent(hour: Int) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        do {
            let events = try EventStore.shared.fetchEvents(since: startOfToday)
            let result = FocusScoreEngine.shared.calculateScore(events: events)
            
            // Calculate stats
            let switchCount = max(events.count - 1, 0)
            let productiveSeconds = events.filter { $0.category == .productive || $0.category == .reference }
                .compactMap { $0.durationSeconds }.reduce(0, +)
            let focusHours = Int(productiveSeconds) / 3600
            let focusMinutes = (Int(productiveSeconds) % 3600) / 60
            
            var streakMinutes = 0
            var longestStreak: Double = 0
            var currentStreak: Double = 0
            var dominantApp = "Xcode"
            
            for event in events {
                let duration = event.durationSeconds ?? 0
                if event.category == .productive || event.category == .reference || event.category == .neutral {
                    currentStreak += duration
                    if currentStreak > longestStreak {
                        longestStreak = currentStreak
                        dominantApp = event.appName
                    }
                } else if event.category == .distracting {
                    currentStreak = 0
                }
            }
            streakMinutes = Int(round(longestStreak / 60.0))
            
            let content = UNMutableNotificationContent()
            content.title = "Daily Focus Summary"
            content.body = "Focus Score: \(result.score) (\(result.level.rawValue))\n\(focusHours)h \(focusMinutes)m of focused work · \(switchCount) switches\nBest streak: \(streakMinutes) minutes in \(dominantApp)"
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "dailyFocusSummary", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("DailySummaryNotifier: Failed to schedule daily summary: \(error)")
                }
            }
        } catch {
            print("DailySummaryNotifier: Failed to fetch today's stats: \(error)")
        }
    }
}
