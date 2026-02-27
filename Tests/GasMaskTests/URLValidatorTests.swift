import XCTest
@testable import Gas_Mask

final class URLValidatorTests: XCTestCase {

    func testEmptyString_isFalse() {
        XCTAssertFalse(URLValidator.isValid(""))
    }

    func testHTTPURL_isTrue() {
        XCTAssertTrue(URLValidator.isValid("http://example.com/hosts"))
    }

    func testHTTPSURL_isTrue() {
        XCTAssertTrue(URLValidator.isValid("https://example.com/hosts"))
    }

    func testFTPURL_isFalse() {
        XCTAssertFalse(URLValidator.isValid("ftp://example.com"))
    }

    func testNoScheme_isFalse() {
        XCTAssertFalse(URLValidator.isValid("example.com"))
    }

    func testHTTPBareScheme_isTrue() {
        // Matches ObjC parity: URL(string:) returns non-nil for "http://"
        XCTAssertTrue(URLValidator.isValid("http://"))
    }
}
