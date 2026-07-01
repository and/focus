import XCTest
@testable import FocusFlow

final class ScoringTests: XCTestCase {
    var engine: FocusScoreEngine!

    override func setUp() {
        super.setUp()
        engine = FocusScoreEngine.shared
    }

    private func makeEvent(bundleID: String, category: AppCategory, duration: Double) -> ActivityEvent {
        ActivityEvent(id: nil, timestamp: Date(), bundleID: bundleID, appName: bundleID, windowTitle: nil, category: category, durationSeconds: duration)
    }

    func testEmptyEventsProduceDeepFocus() {
        let (score, level) = engine.calculateScore(events: [])
        XCTAssertEqual(score, 100)
        XCTAssertEqual(level, .deepFocus)
    }

    func testSingleLongProductiveSessionScoresHigh() {
        let events = [makeEvent(bundleID: "com.apple.dt.Xcode", category: .productive, duration: 20 * 60)]
        let (score, level) = engine.calculateScore(events: events)
        XCTAssertGreaterThanOrEqual(score, 80)
        XCTAssertEqual(level, .deepFocus)
    }

    func testFrequentSwitchingBetweenDistractingAppsScoresLow() {
        var events: [ActivityEvent] = []
        for i in 0..<40 {
            let bundleID = i % 2 == 0 ? "com.twitter.app" : "com.reddit.app"
            events.append(makeEvent(bundleID: bundleID, category: .distracting, duration: 30))
        }
        let (score, level) = engine.calculateScore(events: events)
        XCTAssertLessThan(score, 40)
        XCTAssertTrue(level == .scattered || level == .distracted)
    }

    func testFocusLevelThresholds() {
        XCTAssertEqual(FocusLevel.from(score: 100), .deepFocus)
        XCTAssertEqual(FocusLevel.from(score: 80), .deepFocus)
        XCTAssertEqual(FocusLevel.from(score: 79), .focused)
        XCTAssertEqual(FocusLevel.from(score: 60), .focused)
        XCTAssertEqual(FocusLevel.from(score: 59), .moderate)
        XCTAssertEqual(FocusLevel.from(score: 40), .moderate)
        XCTAssertEqual(FocusLevel.from(score: 39), .scattered)
        XCTAssertEqual(FocusLevel.from(score: 20), .scattered)
        XCTAssertEqual(FocusLevel.from(score: 19), .distracted)
        XCTAssertEqual(FocusLevel.from(score: 0), .distracted)
    }
}
