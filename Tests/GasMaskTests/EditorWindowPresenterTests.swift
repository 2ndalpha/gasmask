import XCTest
@testable import Gas_Mask

final class EditorWindowPresenterTests: XCTestCase {

    private var window: NSWindow!

    override func setUp() {
        super.setUp()
        window = EditorWindowPresenter.createEditorWindow()
    }

    override func tearDown() {
        window.orderOut(nil)
        window = nil
        super.tearDown()
    }

    func testWindowTitle() {
        XCTAssertEqual(window.title, "Gas Mask")
    }

    func testFrameAutosaveName() {
        XCTAssertEqual(window.frameAutosaveName, "editor_window")
    }

    func testMinSize() {
        // Width should match the configured minimum.
        // Height may be larger than 400 due to SwiftUI content minimum sizing.
        XCTAssertEqual(window.minSize.width, 400)
        XCTAssertGreaterThanOrEqual(window.minSize.height, 400)
    }

    func testStyleMask_containsExpectedOptions() {
        let mask = window.styleMask
        XCTAssertTrue(mask.contains(.titled))
        XCTAssertTrue(mask.contains(.closable))
        XCTAssertTrue(mask.contains(.miniaturizable))
        XCTAssertTrue(mask.contains(.resizable))
    }

    func testContentViewController_exists() {
        XCTAssertNotNil(window.contentViewController)
    }

    func testWindowDelegate_exists() {
        XCTAssertNotNil(window.delegate)
    }

    func testWindowShouldClose_returnsTrue() {
        let result = window.delegate?.windowShouldClose?(window) ?? false
        XCTAssertTrue(result)
    }
}
