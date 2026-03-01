import XCTest
@testable import Gas_Mask

final class HostsRowViewTests: XCTestCase {

    private var tempFilePath: String!

    override func setUp() {
        super.setUp()
        let tempDir = NSTemporaryDirectory()
        tempFilePath = (tempDir as NSString).appendingPathComponent("RowTestHosts.hst")
        try? "127.0.0.1 localhost".write(toFile: tempFilePath, atomically: true, encoding: .utf8)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: tempFilePath)
        super.tearDown()
    }

    // MARK: - Accessibility Description

    func testAccessibilityDescription_activeHost_includesActive() {
        let hosts = Hosts(path: tempFilePath)!
        hosts.setActive(true)

        let description = HostsRowView.accessibilityDescription(for: hosts)

        XCTAssertTrue(description.contains("active"))
    }

    func testAccessibilityDescription_inactiveHost_excludesActive() {
        let hosts = Hosts(path: tempFilePath)!
        // Default state is inactive

        let description = HostsRowView.accessibilityDescription(for: hosts)

        XCTAssertFalse(description.contains("active"))
    }

    func testAccessibilityDescription_unsavedHost_includesUnsaved() {
        let hosts = Hosts(path: tempFilePath)!
        hosts.setContents("# modified")

        let description = HostsRowView.accessibilityDescription(for: hosts)

        XCTAssertTrue(description.contains("unsaved"))
    }

    func testAccessibilityDescription_updatesAfterActiveChange() {
        let hosts = Hosts(path: tempFilePath)!

        let before = HostsRowView.accessibilityDescription(for: hosts)
        XCTAssertFalse(before.contains("active"), "precondition")

        hosts.setActive(true)
        let after = HostsRowView.accessibilityDescription(for: hosts)
        XCTAssertTrue(after.contains("active"))
    }
}
