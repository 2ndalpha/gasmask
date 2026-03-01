import XCTest
import AppKit
import SwiftUI
@testable import Gas_Mask

final class AboutBoxPresenterTests: XCTestCase {

    /// Finds the About box window by its hosting controller content.
    private func aboutWindow() -> NSWindow? {
        NSApp.windows.first {
            $0.contentViewController is NSHostingController<AboutBoxView>
        }
    }

    override func tearDown() {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
        if let w = aboutWindow() { w.close() }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        super.tearDown()
    }

    func testShow_createsWindow() {
        AboutBoxPresenter.show()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let w = aboutWindow()
        XCTAssertNotNil(w, "An About box window should exist")
        XCTAssertTrue(w?.isVisible ?? false, "About box window should be visible")
    }

    func testShow_reusesWindow() {
        AboutBoxPresenter.show()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let first = aboutWindow()
        XCTAssertNotNil(first)

        AboutBoxPresenter.show()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        let second = aboutWindow()
        XCTAssertTrue(first === second, "Should reuse the same window instance")
    }

    func testShow_windowStyleMask() {
        AboutBoxPresenter.show()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let w = aboutWindow()
        XCTAssertNotNil(w)
        XCTAssertTrue(w?.styleMask.contains(.titled) ?? false)
        XCTAssertTrue(w?.styleMask.contains(.closable) ?? false)
    }

    func testShow_windowIsNotReleasedWhenClosed() {
        AboutBoxPresenter.show()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let w = aboutWindow()
        XCTAssertNotNil(w)
        XCTAssertFalse(w?.isReleasedWhenClosed ?? true)
    }

    func testScreenshot_aboutBox() throws {
        try XCTSkipIf(NSScreen.main == nil, "No display available")
        AboutBoxPresenter.show()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
        let w = try XCTUnwrap(aboutWindow())

        let frame = w.frame
        let screenFrame = w.screen?.frame ?? NSScreen.main?.frame ?? .zero
        let cgRect = CGRect(
            x: frame.origin.x,
            y: screenFrame.height - frame.origin.y - frame.height,
            width: frame.width,
            height: frame.height
        )
        if let displayID = w.screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
           let image = CGDisplayCreateImage(displayID, rect: cgRect) {
            let bitmap = NSBitmapImageRep(cgImage: image)
            if let png = bitmap.representation(using: .png, properties: [:]) {
                try png.write(to: URL(fileURLWithPath: "/tmp/about-box.png"))
            }
        }
    }
}
