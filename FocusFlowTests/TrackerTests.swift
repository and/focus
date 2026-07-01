import XCTest
@testable import FocusFlow

final class TrackerTests: XCTestCase {
    func testIdleDetectorDefaultThreshold() {
        let detector = IdleDetector()
        XCTAssertEqual(detector.idleThreshold, 120)
    }

    func testIdleDetectorThresholdIsConfigurable() {
        let detector = IdleDetector()
        detector.idleThreshold = 60
        XCTAssertEqual(detector.idleThreshold, 60)
    }

    func testIdleDetectorStartStopDoesNotCrash() {
        let detector = IdleDetector()
        detector.start()
        detector.stop()
    }
}
