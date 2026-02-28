import XCTest
import AppKit
@testable import Gas_Mask

final class PreferencesPresenterTests: XCTestCase {

    /// Finds the preferences window by its `NSTabViewController` content.
    private func preferencesWindow() -> NSWindow? {
        NSApp.windows.first { $0.contentViewController is NSTabViewController }
    }

    override func tearDown() {
        // Close any preferences window opened during the test.
        // Drain CA transactions first to avoid animation crashes.
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
        if let w = preferencesWindow() { w.close() }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        super.tearDown()
    }

    func testShowPreferences_createsWindow() {
        PreferencesPresenter.showPreferences()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let w = preferencesWindow()
        XCTAssertNotNil(w, "A preferences window should exist")
        XCTAssertTrue(w?.isVisible ?? false, "Preferences window should be visible")
    }

    func testShowPreferences_reusesWindow() {
        PreferencesPresenter.showPreferences()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let first = preferencesWindow()
        XCTAssertNotNil(first)

        PreferencesPresenter.showPreferences()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        let second = preferencesWindow()
        XCTAssertTrue(first === second, "Should reuse the same window instance")
    }

    func testShowPreferences_hasFiveTabs() {
        PreferencesPresenter.showPreferences()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let tabVC = preferencesWindow()?.contentViewController as? NSTabViewController
        XCTAssertEqual(tabVC?.tabViewItems.count, 5, "Should have 5 preference tabs")
    }

    func testShowPreferences_tabLabelsMatch() {
        PreferencesPresenter.showPreferences()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let tabVC = preferencesWindow()?.contentViewController as? NSTabViewController
        let labels = tabVC?.tabViewItems.map(\.label)
        XCTAssertEqual(labels, ["General", "Editor", "Remote", "Hotkeys", "Update"])
    }

    func testShowPreferences_tabsHaveIcons() {
        PreferencesPresenter.showPreferences()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let tabVC = preferencesWindow()?.contentViewController as? NSTabViewController
        XCTAssertNotNil(tabVC)
        for item in tabVC?.tabViewItems ?? [] {
            XCTAssertNotNil(item.image, "Tab '\(item.label)' should have an icon")
        }
    }

    /// Captures a screenshot of a specific tab and saves to /tmp/preferences-<tab>.png.
    private func captureTab(index: Int, name: String) throws {
        try XCTSkipIf(NSScreen.main == nil, "No display available")
        PreferencesPresenter.showPreferences()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
        let w = try XCTUnwrap(preferencesWindow())
        let tabVC = try XCTUnwrap(w.contentViewController as? NSTabViewController)
        tabVC.selectedTabViewItemIndex = index
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

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
                try png.write(to: URL(fileURLWithPath: "/tmp/preferences-\(name).png"))
            }
        }
    }

    func testScreenshot_allTabs() throws {
        for (i, name) in ["general", "editor", "remote", "hotkeys", "update"].enumerated() {
            try captureTab(index: i, name: name)
        }
    }

    func testShowPreferences_toolbarStyleIsPreference() {
        PreferencesPresenter.showPreferences()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let w = preferencesWindow()
        XCTAssertEqual(w?.toolbarStyle, .preference)
    }
}
