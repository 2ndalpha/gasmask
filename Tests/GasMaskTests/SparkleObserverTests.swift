import XCTest
@testable import Gas_Mask

final class SparkleObserverTests: XCTestCase {

    func testLastCheckDateFormatted_nil_returnsNever() {
        let observer = SparkleObserver(updater: nil)
        observer.lastCheckDate = nil
        XCTAssertEqual(observer.lastCheckDateFormatted, "Last Checked: Never")
    }

    func testNilUpdater_defaultState() {
        let observer = SparkleObserver(updater: nil)
        XCTAssertNil(observer.lastCheckDate)
        XCTAssertFalse(observer.automaticChecksEnabled)
        XCTAssertFalse(observer.canCheckForUpdates)
    }

    func testLastCheckDateFormatted_date_returnsFormattedString() {
        let observer = SparkleObserver(updater: nil)
        // Use a fixed date: 2026-02-28 15:45:00 UTC
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 28
        components.hour = 15
        components.minute = 45
        let date = Calendar.current.date(from: components)!
        observer.lastCheckDate = date

        let result = observer.lastCheckDateFormatted
        XCTAssertTrue(result.hasPrefix("Last Checked: "),
                      "Should start with 'Last Checked: ', got: \(result)")
        XCTAssertFalse(result.hasSuffix("Never"),
                       "Should not say Never when date is set")
        // The exact format depends on locale, so just verify it contains the year
        XCTAssertTrue(result.contains("2026"),
                      "Should contain the year, got: \(result)")
    }
}
