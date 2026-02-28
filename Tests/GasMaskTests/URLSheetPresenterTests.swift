import XCTest
import AppKit
import SwiftUI
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
        // Under ARC, NSWindow.close() sends an extra -release when
        // isReleasedWhenClosed is true (the default), which frees the window
        // while AppKit's sheet-transform animation may still hold a live
        // block capturing it.  Disabling this lets ARC alone manage the
        // window's lifetime, so the animation can safely release its
        // references after close().
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        // Let the run loop settle so the window becomes key
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    }

    override func tearDown() {
        // Dismiss any attached sheet before closing the window.
        // Closing a window with an attached sheet causes undefined behaviour on
        // macOS 15, corrupting subsequent test state.
        if let sheet = window?.attachedSheet {
            window?.endSheet(sheet)
            let gone = XCTNSPredicateExpectation(
                predicate: NSPredicate { [weak self] _, _ in
                    self?.window?.attachedSheet == nil
                },
                object: nil
            )
            wait(for: [gone], timeout: 3.0)
        }
        // Flush pending CA transactions and autorelease pools so that
        // AppKit's _NSWindowTransformAnimation (and its captured blocks) is
        // fully released while this window is still alive.  Without this,
        // the animation can be drained in a later test's run-loop iteration,
        // finding the captured window already freed → EXC_BAD_ACCESS.
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
        window.close()
        window = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func hostingController(for sheet: NSWindow) -> NSHostingController<URLSheetView>? {
        sheet.contentViewController as? NSHostingController<URLSheetView>
    }

    private func waitForSheet(timeout: TimeInterval = 2.0) {
        let attached = XCTNSPredicateExpectation(
            predicate: NSPredicate { [weak self] _, _ in
                self?.window?.attachedSheet != nil
            },
            object: nil
        )
        wait(for: [attached], timeout: timeout)
    }

    // MARK: - Tests

    /// The presenter must attach a sheet to the parent window.
    func testPresent_attachesSheet() {
        URLSheetPresenter.presentInWindow(window)
        waitForSheet()
        XCTAssertNotNil(window.attachedSheet)
    }

    /// Passing nil must log a warning and not crash.
    func testPresent_nilWindow_doesNotCrash() {
        URLSheetPresenter.presentInWindow(nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        // No assertion needed — test passes if no crash/exception
    }

    /// Calling endSheet on the attached sheet must dismiss it.
    func testPresent_cancelDismissesSheet() {
        URLSheetPresenter.presentInWindow(window)
        waitForSheet()

        guard let sheet = window.attachedSheet else {
            XCTFail("Sheet was not attached")
            return
        }

        window.endSheet(sheet)
        let gone = XCTNSPredicateExpectation(
            predicate: NSPredicate { [weak self] _, _ in
                self?.window?.attachedSheet == nil
            },
            object: nil
        )
        wait(for: [gone], timeout: 2.0)
        XCTAssertNil(window.attachedSheet)
    }

    /// Invoking the Cancel callback (what the Cancel button does) must dismiss the sheet.
    ///
    /// URLSheetView.onCancel is the plain closure the Cancel button calls with no
    /// intermediate logic.  URLSheetPresenter wires it to parent.endSheet(panel), so
    /// calling rootView.onCancel() is a faithful integration test of that wiring.
    func testCancelCallback_dismissesSheet() {
        URLSheetPresenter.presentInWindow(window)
        waitForSheet()

        guard let sheet = window.attachedSheet,
              let hc = hostingController(for: sheet) else {
            XCTFail("Sheet or hosting controller not found"); return
        }

        hc.rootView.onCancel()   // same as clicking Cancel

        let gone = XCTNSPredicateExpectation(
            predicate: NSPredicate { [weak self] _, _ in
                self?.window?.attachedSheet == nil
            },
            object: nil
        )
        wait(for: [gone], timeout: 2.0)

        XCTAssertNil(window.attachedSheet,
                     "Sheet should be dismissed after Cancel callback fires")
    }
}
