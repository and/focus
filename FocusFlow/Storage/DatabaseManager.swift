import Foundation
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()
    
    let dbQueue: DatabaseQueue
    
    private init() {
        do {
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let focusFlowURL = appSupportURL.appendingPathComponent("FocusFlow", isDirectory: true)
            
            if !fileManager.fileExists(atPath: focusFlowURL.path) {
                try fileManager.createDirectory(at: focusFlowURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            let dbURL = focusFlowURL.appendingPathComponent("db.sqlite")
            print("Database path: \(dbURL.path)")
            
            self.dbQueue = try DatabaseQueue(path: dbURL.path)
            try setupDatabase()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }
    
    private func setupDatabase() throws {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("createTables") { db in
            // activityEvents table
            try db.create(table: "activityEvents") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("timestamp", .datetime).notNull().indexed()
                t.column("bundleID", .text).notNull()
                t.column("appName", .text).notNull()
                t.column("windowTitle", .text)
                t.column("category", .text).notNull()
                t.column("durationSeconds", .double)
            }
            
            // focusSessions table
            try db.create(table: "focusSessions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("startTime", .datetime).notNull()
                t.column("endTime", .datetime)
                t.column("score", .integer).notNull()
                t.column("level", .text).notNull()
                t.column("dominantApp", .text).notNull()
                t.column("switchCount", .integer).notNull()
                t.column("idleSeconds", .double).notNull()
            }
            
            // dailyScores table
            try db.create(table: "dailyScores") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("date", .date).notNull().unique()
                t.column("averageScore", .integer).notNull()
                t.column("peakScore", .integer).notNull()
                t.column("totalFocusedMinutes", .double).notNull()
                t.column("totalActiveMinutes", .double).notNull()
                t.column("totalSwitches", .integer).notNull()
                t.column("topAppsData", .blob).notNull()
            }
        }
        
        try migrator.migrate(dbQueue)
    }
}
