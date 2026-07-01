import Foundation
import GRDB

// ActivityEvent — raw tracking data
struct ActivityEvent: Codable, FetchableRecord, PersistableRecord, TableRecord {
    var id: Int64?
    var timestamp: Date
    var bundleID: String
    var appName: String
    var windowTitle: String?
    var category: AppCategory
    var durationSeconds: Double?     // filled in when the next event arrives
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, bundleID, appName, windowTitle, category, durationSeconds
    }
    
    // Define database table columns
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let bundleID = Column(CodingKeys.bundleID)
        static let appName = Column(CodingKeys.appName)
        static let windowTitle = Column(CodingKeys.windowTitle)
        static let category = Column(CodingKeys.category)
        static let durationSeconds = Column(CodingKeys.durationSeconds)
    }
    
    static var databaseTableName: String = "activityEvents"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// FocusSession — a scored block of focused work
struct FocusSession: Codable, FetchableRecord, PersistableRecord, TableRecord {
    var id: Int64?
    var startTime: Date
    var endTime: Date?
    var score: Int                   // 0–100
    var level: FocusLevel
    var dominantApp: String          // app used most during this session
    var switchCount: Int
    var idleSeconds: Double
    
    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, score, level, dominantApp, switchCount, idleSeconds
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let startTime = Column(CodingKeys.startTime)
        static let endTime = Column(CodingKeys.endTime)
        static let score = Column(CodingKeys.score)
        static let level = Column(CodingKeys.level)
        static let dominantApp = Column(CodingKeys.dominantApp)
        static let switchCount = Column(CodingKeys.switchCount)
        static let idleSeconds = Column(CodingKeys.idleSeconds)
    }
    
    static var databaseTableName: String = "focusSessions"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// DailyScore — aggregated daily summary
struct DailyScore: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable {
    var id: Int64?
    var date: Date                   // calendar date (no time)
    var averageScore: Int
    var peakScore: Int
    var totalFocusedMinutes: Double  // time in .focused or .deepFocus
    var totalActiveMinutes: Double
    var totalSwitches: Int
    var topAppsData: Data            // JSON-encoded top 5 apps by time
    
    enum CodingKeys: String, CodingKey {
        case id, date, averageScore, peakScore, totalFocusedMinutes, totalActiveMinutes, totalSwitches, topAppsData
    }
    
    var topApps: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: topAppsData)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                topAppsData = data
            }
        }
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let date = Column(CodingKeys.date)
        static let averageScore = Column(CodingKeys.averageScore)
        static let peakScore = Column(CodingKeys.peakScore)
        static let totalFocusedMinutes = Column(CodingKeys.totalFocusedMinutes)
        static let totalActiveMinutes = Column(CodingKeys.totalActiveMinutes)
        static let totalSwitches = Column(CodingKeys.totalSwitches)
        static let topAppsData = Column(CodingKeys.topAppsData)
    }
    
    static var databaseTableName: String = "dailyScores"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
