import Foundation
import GRDB

class SessionStore {
    static let shared = SessionStore()
    private let dbQueue = DatabaseManager.shared.dbQueue
    
    private init() {}
    
    func saveSession(_ session: inout FocusSession) throws {
        try dbQueue.write { db in
            try session.save(db)
        }
    }
    
    func getActiveSession() throws -> FocusSession? {
        try dbQueue.read { db in
            try FocusSession
                .filter(FocusSession.Columns.endTime == nil)
                .order(FocusSession.Columns.startTime.desc)
                .fetchOne(db)
        }
    }
    
    func fetchSessions(since date: Date) throws -> [FocusSession] {
        try dbQueue.read { db in
            try FocusSession
                .filter(FocusSession.Columns.startTime >= date)
                .order(FocusSession.Columns.startTime.asc)
                .fetchAll(db)
        }
    }
    
    func deleteSessionsOlderThan(days: Int) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        _ = try dbQueue.write { db in
            try FocusSession
                .filter(FocusSession.Columns.startTime < cutoffDate)
                .deleteAll(db)
        }
    }
    
    // MARK: - Daily Scores CRUD
    func saveDailyScore(_ score: inout DailyScore) throws {
        try dbQueue.write { db in
            try score.save(db)
        }
    }
    
    func fetchDailyScores(since date: Date) throws -> [DailyScore] {
        try dbQueue.read { db in
            try DailyScore
                .filter(DailyScore.Columns.date >= date)
                .order(DailyScore.Columns.date.asc)
                .fetchAll(db)
        }
    }
    
    func fetchDailyScore(for date: Date) throws -> DailyScore? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return try dbQueue.read { db in
            try DailyScore
                .filter(DailyScore.Columns.date == startOfDay)
                .fetchOne(db)
        }
    }
}
