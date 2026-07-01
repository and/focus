import XCTest
@testable import FocusFlow

final class CategorizerTests: XCTestCase {
    var categorizer: AppCategorizer!

    override func setUp() {
        super.setUp()
        categorizer = AppCategorizer.shared
    }

    func testDefaultProductiveMapping() {
        XCTAssertEqual(categorizer.categorize(bundleID: "com.apple.dt.Xcode"), .productive)
    }

    func testDefaultDistractingMapping() {
        XCTAssertEqual(categorizer.categorize(bundleID: "com.spotify.client"), .distracting)
    }

    func testUnknownBundleIDFallsBackToNeutral() {
        XCTAssertEqual(categorizer.categorize(bundleID: "com.some.unknown.app"), .neutral)
    }

    func testCustomOverrideTakesPrecedence() {
        categorizer.setCategory(for: "com.some.unknown.app", category: .productive)
        defer { categorizer.removeCategoryOverride(for: "com.some.unknown.app") }
        XCTAssertEqual(categorizer.categorize(bundleID: "com.some.unknown.app"), .productive)
    }

    func testBrowserTitleKeywordRecategorizesToProductive() {
        let category = categorizer.categorize(bundleID: "com.apple.Safari", windowTitle: "My Repo — GitHub")
        XCTAssertEqual(category, .productive)
    }

    func testBrowserTitleKeywordRecategorizesToDistracting() {
        let category = categorizer.categorize(bundleID: "com.google.Chrome", windowTitle: "Some Video — YouTube")
        XCTAssertEqual(category, .distracting)
    }

    func testBrowserWithoutMatchingKeywordFallsBackToNeutral() {
        let category = categorizer.categorize(bundleID: "org.mozilla.firefox", windowTitle: "An Unrelated Page")
        XCTAssertEqual(category, .neutral)
    }

    func testIsBrowserRecognizesKnownBrowsers() {
        XCTAssertTrue(categorizer.isBrowser(bundleID: "com.apple.Safari"))
        XCTAssertTrue(categorizer.isBrowser(bundleID: "com.google.Chrome"))
        XCTAssertFalse(categorizer.isBrowser(bundleID: "com.apple.dt.Xcode"))
    }
}
