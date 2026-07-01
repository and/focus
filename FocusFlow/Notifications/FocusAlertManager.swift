import Foundation
import UserNotifications

class FocusAlertManager {
    static let shared = FocusAlertManager()
    
    private var lastNudgeTime: Date?
    private let nudgeIntervalLimit: TimeInterval = 20 * 60 // 20 minutes
    
    private init() {
        requestNotificationPermission()
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("FocusAlertManager: Notification authorization failed: \(error)")
            }
        }
    }
    
    func checkNudges(events: [ActivityEvent], currentScore: Int) {
        guard currentScore < 100 else { return }
        
        let now = Date()
        
        // Rate limit nudges: max 1 per 20 minutes
        if let lastNudge = lastNudgeTime, now.timeIntervalSince(lastNudge) < nudgeIntervalLimit {
            return
        }
        
        // Rule 1: Score drops below 30 for more than 5 minutes
        if currentScore < 30 {
            let fiveMinsAgo = now.addingTimeInterval(-5 * 60)
            let recentEvents = events.filter { $0.timestamp >= fiveMinsAgo }
            if !recentEvents.isEmpty {
                sendNudge(title: "Focus Dipped", body: "Your focus has dipped. Consider closing some distracting tabs.")
                lastNudgeTime = now
                return
            }
        }
        
        // Rule 2: Rapid switching detected (> 10 switches in 3 minutes)
        let threeMinsAgo = now.addingTimeInterval(-3 * 60)
        let switchesInLastThreeMins = events.filter { $0.timestamp >= threeMinsAgo }.count
        if switchesInLastThreeMins > 10 {
            sendNudge(title: "Rapid Switching Detected", body: "Try staying on one task for the next 15 minutes to build momentum.")
            lastNudgeTime = now
            return
        }
        
        // Rule 3: Extended distracting app use (> 15 min on distracting category)
        let fifteenMinsAgo = now.addingTimeInterval(-15 * 60)
        let recentDistractingEvents = events.filter { $0.timestamp >= fifteenMinsAgo && $0.category == .distracting }
        let totalDistractingDuration = recentDistractingEvents.compactMap { $0.durationSeconds }.reduce(0, +)
        if totalDistractingDuration > 15 * 60 {
            let appNames = recentDistractingEvents.map { $0.appName }
            let dominantApp = appNames.reduce(into: [:]) { counts, word in counts[word, default: 0] + 1 }
                .max(by: { $0.value < $1.value })?.key ?? "distracting apps"
            
            sendNudge(title: "Ready to get back?", body: "You've been on \(dominantApp) for a while. Ready to get back to work?")
            lastNudgeTime = now
            return
        }
    }
    
    private func sendNudge(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("FocusAlertManager: Failed to send notification: \(error)")
            }
        }
    }
}
