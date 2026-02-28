import XCTest
import AppKit
import SwiftUI
@testable import Gas_Mask

/// Tests URLSheetView's Add and Cancel callbacks.
///
/// Strategy
/// --------
/// SwiftUI on macOS 14+ renders Button as a private framework view (not NSButton),
/// so button clicks cannot be driven through the NSView hierarchy.
///
/// Add button: driven via the text field's Return key (TextField.onSubmit fires the
/// exact same closure as the Add button action), making it a faithful end-to-end test.
///
/// Cancel button: `URLSheetView.onCancel` is the plain closure the Cancel button
/// calls.  Invoking it directly (via NSHostingController.rootView.onCancel()) is
/// equivalent to clicking Cancel — the view contains no logic between the tap and
/// the callback call.  The full integration (callback → sheet dismissed) is verified
/// separately in URLSheetPresenterTests.
final class URLSheetViewTests: XCTestCase {
    private var panel: NSPanel?

    override func tearDown() {
        panel?.close()
        panel = nil
        // Drain the run loop so SwiftUI can finish tearing down its view tree
        // (e.g. NetworkStatusObserver KVO) before the next test starts.
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeHostingController(
        urlText: String = "",
        onAdd: @escaping (URL) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) -> NSHostingController<URLSheetView> {
        let view = URLSheetView(urlText: urlText, onAdd: onAdd, onCancel: onCancel)
        let hc = NSHostingController(rootView: view)
        let p = NSPanel(contentViewController: hc)
        p.makeKeyAndOrderFront(nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
        panel = p
        return hc
    }

    private func sendReturn(to window: NSWindow) {
        guard let event = NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber, context: nil,
            characters: "\r", charactersIgnoringModifiers: "\r",
            isARepeat: false, keyCode: 36
        ) else { return }
        window.sendEvent(event)
    }

    // MARK: - Add button enabled state
    //
    // SwiftUI on macOS 14+ renders Button as a private framework view, so we
    // cannot walk the NSView hierarchy to check isEnabled.  URLSheetView
    // exposes isAddButtonEnabled (which mirrors the .disabled modifier) as a
    // plain computed property, making it testable without AppKit involvement.

    func testAddButton_isEnabled_forHTTPSURL() {
        let view = URLSheetView(urlText: "https://example.com/hosts",
                                onAdd: { _ in }, onCancel: {})
        XCTAssertTrue(view.isAddButtonEnabled)
    }

    func testAddButton_isEnabled_forHTTPURL() {
        let view = URLSheetView(urlText: "http://example.com/hosts",
                                onAdd: { _ in }, onCancel: {})
        XCTAssertTrue(view.isAddButtonEnabled)
    }

    func testAddButton_isDisabled_forEmptyURL() {
        let view = URLSheetView(urlText: "", onAdd: { _ in }, onCancel: {})
        XCTAssertFalse(view.isAddButtonEnabled)
    }

    func testAddButton_isDisabled_forFTPURL() {
        let view = URLSheetView(urlText: "ftp://example.com",
                                onAdd: { _ in }, onCancel: {})
        XCTAssertFalse(view.isAddButtonEnabled)
    }

    func testAddButton_isDisabled_forNoScheme() {
        let view = URLSheetView(urlText: "example.com", onAdd: { _ in }, onCancel: {})
        XCTAssertFalse(view.isAddButtonEnabled)
    }

    // MARK: - Cancel callback

    /// Invoking onCancel (what the Cancel button does) calls the provided closure.
    func testCancelCallback_isCalled() {
        var called = false
        let hc = makeHostingController(onCancel: { called = true })

        hc.rootView.onCancel()

        XCTAssertTrue(called,
                      "onCancel closure must be invoked — the Cancel button calls it directly")
    }

    // MARK: - Add button / text-field Return (valid URL)

    /// Return with a valid https URL triggers onAdd via TextField.onSubmit —
    /// the same closure the Add button calls, so this is a faithful functional test.
    func testReturnKey_callsOnAdd_withHTTPSURL() {
        var receivedURL: URL?
        _ = makeHostingController(
            urlText: "https://example.com/hosts",
            onAdd: { receivedURL = $0 }
        )

        sendReturn(to: panel!)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))

        XCTAssertEqual(receivedURL?.absoluteString, "https://example.com/hosts")
    }

    func testReturnKey_callsOnAdd_withHTTPURL() {
        var receivedURL: URL?
        _ = makeHostingController(
            urlText: "http://example.com/hosts",
            onAdd: { receivedURL = $0 }
        )

        sendReturn(to: panel!)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))

        XCTAssertEqual(receivedURL?.absoluteString, "http://example.com/hosts")
    }

    // MARK: - Add button / text-field Return (invalid URL — must not fire)

    func testReturnKey_doesNotCallOnAdd_withEmptyURL() {
        var addCalled = false
        _ = makeHostingController(urlText: "", onAdd: { _ in addCalled = true })

        sendReturn(to: panel!)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))

        XCTAssertFalse(addCalled, "onAdd must not fire for empty URL")
    }

    func testReturnKey_doesNotCallOnAdd_withInvalidURL() {
        var addCalled = false
        _ = makeHostingController(urlText: "ftp://example.com",
                                        onAdd: { _ in addCalled = true })

        sendReturn(to: panel!)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))

        XCTAssertFalse(addCalled, "onAdd must not fire for non-http(s) URL")
    }
}
