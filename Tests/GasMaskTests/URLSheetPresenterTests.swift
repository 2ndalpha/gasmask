import XCTest
import AppKit
@testable import Gas_Mask

final class URLSheetPresenterTests: XCTestCase {
    var window: NSWindow!

    override func setUp() {
        super.setUp()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false
        )
        window.makeKeyAndOrderFront(nil)
        // Let the run loop settle so the window becomes key
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    }

    override func tearDown() {
        if let sheet = window?.attachedSheet {
            window?.endSheet(sheet)
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        }
        window.close()
        window = nil
        super.tearDown()
    }

    func testPresent_attachesSheet() {
        URLSheetPresenter.presentInWindow(window)

        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { [weak self] _, _ in
                self?.window.attachedSheet != nil
            },
            object: nil
        )
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(window.attachedSheet)
    }

    func testPresent_nilWindow_doesNotCrash() {
        // Should log a warning and return without crashing
        URLSheetPresenter.presentInWindow(nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        // No assertion needed — test passes if no crash/exception
    }

    func testPresent_cancelDismissesSheet() {
        URLSheetPresenter.presentInWindow(window)

        let attachExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { [weak self] _, _ in
                self?.window.attachedSheet != nil
            },
            object: nil
        )
        wait(for: [attachExpectation], timeout: 2.0)

        guard let sheet = window.attachedSheet else {
            XCTFail("Sheet was not attached")
            return
        }

        window.endSheet(sheet)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertNil(window.attachedSheet)
    }
}
