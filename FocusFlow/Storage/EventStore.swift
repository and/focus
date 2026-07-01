import Foundation
import GRDB

class EventStore {
    static let shared = EventStore()
    private let dbQueue = DatabaseManager.shared.dbQueue
    
    private init() {}
    
    func recordEvent(bundleID: String, appName: String, windowTitle: String?, category: AppCategory) throws -> ActivityEvent {
        let now = Date()
        var newEvent = ActivityEvent(
            id: nil,
            timestamp: now,
            bundleID: bundleID,
            appName: appName,
            windowTitle: windowTitle,
            category: category,
            durationSeconds: nil
        )
        
        try dbQueue.write { db in
            // Find the most recent event to calculate its duration
            if var lastEvent = try ActivityEvent.order(ActivityEvent.Columns.timestamp.desc).limit(1).fetchOne(db) {
                let duration = now.timeIntervalSince(lastEvent.timestamp)
                // Cap extreme duration if app was running overnight or computer was sleep
                let cappedDuration = min(duration, 3600.0 * 8) // max 8 hours
                lastEvent.durationSeconds = cappedDuration
                try lastEvent.update(db)
            }
            
            // Insert the new event
            try newEvent.insert(db)
        }
        
        return newEvent
    }
    
    func fetchEvents(since date: Date) throws -> [ActivityEvent] {
        try dbQueue.read { db in
            try ActivityEvent
                .filter(ActivityEvent.Columns.timestamp >= date)
                .order(ActivityEvent.Columns.timestamp.asc)
                .fetchAll(db)
        }
    }
    
    func deleteEventsOlderThan(days: Int) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        _ = try dbQueue.write { db in
            try ActivityEvent
                .filter(ActivityEvent.Columns.timestamp < cutoffDate)
                .deleteAll(db)
        }
    }
}
