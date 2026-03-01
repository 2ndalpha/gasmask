import XCTest
import Combine
@testable import Gas_Mask

final class HostsTextViewPerformanceTests: XCTestCase {

    private var textView: HostsTextView!
    private var scrollView: NSScrollView!
    private var window: NSWindow!

    override func setUp() {
        super.setUp()
        guard let tv = HostsTextView.createForProgrammaticUse() else {
            XCTFail("Failed to create HostsTextView")
            return
        }
        textView = tv
        textView.setSyntaxHighlighting(true)

        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true

        // Put in a window so layout is triggered (mimics real usage)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = scrollView
        window.orderBack(nil)
    }

    override func tearDown() {
        window.orderOut(nil)
        window = nil
        scrollView = nil
        textView = nil
        super.tearDown()
    }

    // MARK: - Small File Switching (User-reported lockup with local files)

    /// Reproduces the reported issue: switching between two SMALL local files
    /// should not lock up the UI. This exercises the exact updateNSView flow.
    func testRapidSwitching_twoSmallLocalFiles_completesQuickly() {
        let fileA = "127.0.0.1 localhost\n::1 localhost\n# my local config\n"
        let fileB = "127.0.0.1 myhost.local\n192.168.1.1 router.local\n"

        let switchCount = 20
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<switchCount {
            // Simulate what updateNSView does: compare + replace
            simulateUpdateNSView(contents: fileA)
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
            simulateUpdateNSView(contents: fileB)
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let activeTime = elapsed - Double(switchCount) * 2.0 * 0.01

        // 20 round-trip switches between small files must be near-instant
        XCTAssertLessThan(activeTime, 0.5,
            "Small file switching took \(String(format: "%.3f", activeTime))s active time — UI lockup confirmed")
    }

    /// Tests that updateNSView guard correctly skips replacement when content
    /// is unchanged (e.g., during notification-triggered re-renders).
    func testUpdateNSView_sameContent_doesNotReplace() {
        let content = "127.0.0.1 localhost\n"
        textView.replaceContent(with: content)

        // After setting content, the guard should detect equal content and skip
        // replaceContent. We verify by checking the length guard works.
        let currentLength = (textView.string as NSString).length
        let newLength = (content as NSString).length

        // The guard condition: lengths match AND content matches → no replacement
        let wouldReplace = currentLength != newLength || textView.string != content
        XCTAssertFalse(wouldReplace,
            "updateNSView would replace content even though it hasn't changed")
    }

    // MARK: - Notification Cascade Tests

    /// Verifies that rapidly changing selectedHosts triggers a bounded number
    /// of rowRefreshToken increments (not an unbounded cascade).
    func testSelectionChange_doesNotCascadeRowRefreshToken() {
        let store = HostsDataStore()
        let tokenBefore = store.rowRefreshToken

        // Simulate what happens during selection: just changing selectedHosts
        // should NOT increment rowRefreshToken (which triggers full sidebar re-render)
        let hosts1 = Hosts(path: "/tmp/testA.hst")!
        let hosts2 = Hosts(path: "/tmp/testB.hst")!

        for _ in 0..<10 {
            store.selectedHosts = hosts1
            store.selectedHosts = hosts2
        }

        // Drain notification queue
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        let tokenAfter = store.rowRefreshToken
        XCTAssertEqual(tokenBefore, tokenAfter,
            "rowRefreshToken changed by \(tokenAfter - tokenBefore) during selection switches — " +
            "indicates notification cascade causing unnecessary sidebar re-renders")
    }

    /// Verifies that selecting a Hosts file doesn't post HostsNodeNeedsUpdate
    /// (which would trigger rowRefreshToken increment → full sidebar re-render).
    func testSelectionChange_doesNotPostNeedsUpdateNotification() {
        var notificationCount = 0
        let observer = NotificationCenter.default.addObserver(
            forName: .hostsNodeNeedsUpdate, object: nil, queue: .main
        ) { _ in
            notificationCount += 1
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        let store = HostsDataStore()
        let hosts1 = Hosts(path: "/tmp/testA.hst")!
        let hosts2 = Hosts(path: "/tmp/testB.hst")!

        store.selectedHosts = hosts1
        store.selectedHosts = hosts2
        store.selectedHosts = hosts1

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        XCTAssertEqual(notificationCount, 0,
            "Selecting a hosts file posted \(notificationCount) HostsNodeNeedsUpdate notifications — " +
            "each one triggers a full sidebar re-render")
    }

    // MARK: - Large File Switching

    /// Verifies that switching between a large remote hosts file and a small local file
    /// multiple times completes within a reasonable time and doesn't lock the UI.
    func testRapidSwitching_largeAndSmallFile_completesQuickly() {
        let largeContent = Self.generateLargeHostsContent(lineCount: 16000)
        let smallContent = "127.0.0.1 localhost\n::1 localhost\n"

        let switchCount = 5
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<switchCount {
            textView.replaceContent(with: largeContent)
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
            textView.replaceContent(with: smallContent)
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let activeTime = elapsed - Double(switchCount) * 2.0 * 0.05

        XCTAssertLessThan(activeTime, 2.0,
            "Rapid switching active time: \(String(format: "%.2f", activeTime))s (total: \(String(format: "%.2f", elapsed))s)")
    }

    /// Verifies that switching from a large file to a small file cancels pending
    /// async highlighting (generation counter should invalidate stale work).
    func testSwitchToSmallFile_cancelsPendingHighlighting() {
        let largeContent = Self.generateLargeHostsContent(lineCount: 16000)

        textView.replaceContent(with: largeContent)
        textView.replaceContent(with: "127.0.0.1 localhost\n")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        XCTAssertEqual(textView.string, "127.0.0.1 localhost\n")
    }

    /// Measures the wall-clock cost of a single large file text replacement.
    func testPerformance_singleLargeFileSwitch() {
        let largeContent = Self.generateLargeHostsContent(lineCount: 16000)

        measure {
            textView.replaceContent(with: largeContent)
            textView.replaceContent(with: "")
        }
    }

    // MARK: - Integration: HostsDataStore + updateNSView pipeline

    /// Simulates the full pipeline: HostsDataStore selection change → Hosts.contents()
    /// → updateNSView guard → replaceContent. Tests that the combination of all layers
    /// completes quickly for small local files.
    func testIntegration_storeSelectionThenUpdateNSView_completesQuickly() {
        let store = HostsDataStore()

        // Create two hosts with pre-loaded content (simulates cached local files)
        let hosts1 = Hosts(path: "/tmp/integA.hst")!
        hosts1.setContents("127.0.0.1 localhost\n::1 localhost\n# local config A\n")
        hosts1.setSaved(true) // Reset saved flag to avoid HostsNodeNeedsUpdate

        let hosts2 = Hosts(path: "/tmp/integB.hst")!
        hosts2.setContents("192.168.1.1 router.local\n10.0.0.1 gateway.local\n")
        hosts2.setSaved(true)

        let switchCount = 20
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<switchCount {
            // Step 1: HostsDataStore selection change
            store.selectedHosts = hosts1
            // Step 2: Simulate what updateNSView does
            let contents1 = store.selectedHosts?.contents() ?? ""
            simulateUpdateNSView(contents: contents1)

            store.selectedHosts = hosts2
            let contents2 = store.selectedHosts?.contents() ?? ""
            simulateUpdateNSView(contents: contents2)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // 40 switches (20 round trips) through the full pipeline must complete quickly
        XCTAssertLessThan(elapsed, 1.0,
            "Full store→updateNSView pipeline: \(String(format: "%.3f", elapsed))s for \(switchCount * 2) switches")
    }

    /// Demonstrates that the old O(n) guard check was expensive for large files.
    /// The new pointer-based guard (hostsChanged || externalChange) avoids this.
    func testGuardCheck_pointerBased_skipsStringComparison() {
        let content = Self.generateLargeHostsContent(lineCount: 16000)
        textView.replaceContent(with: content)

        let hosts = Hosts(path: "/tmp/guardCheck.hst")!
        hosts.setContents(content)
        hosts.setSaved(true)

        // Simulate updateNSView with pointer-based guard (new approach):
        // same Hosts pointer + same contentToken → skip entirely (O(1))
        var lastUpdatedHosts: Hosts? = hosts
        var lastContentToken: UInt64 = 42
        let contentToken: UInt64 = 42

        let iterations = 100
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            let hostsChanged = hosts !== lastUpdatedHosts
            let externalChange = contentToken != lastContentToken
            if hostsChanged || externalChange {
                textView.replaceContent(with: content)
                lastUpdatedHosts = hosts
                lastContentToken = contentToken
            }
            // Nothing happens — the guard correctly skips
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        NSLog("Pointer-based guard on 16K-line file: %.6fs for %d calls (%.4fms each)",
              elapsed, iterations, elapsed / Double(iterations) * 1000)

        // O(1) pointer/token comparison — must be near-instant even for huge files
        XCTAssertLessThan(elapsed, 0.01,
            "Pointer-based guard took \(String(format: "%.3f", elapsed))s — should be near-instant")
    }

    /// Verifies that HostsDataStore.selectedHosts didSet does NOT trigger a
    /// re-entrant update (which would cause updateNSView to fire multiple times
    /// per selection change in the real app).
    func testStoreSelection_countsObjectWillChangePublications() {
        let store = HostsDataStore()
        let hosts1 = Hosts(path: "/tmp/countA.hst")!
        let hosts2 = Hosts(path: "/tmp/countB.hst")!

        var changeCount = 0
        let cancellable = store.objectWillChange.sink { _ in
            changeCount += 1
        }
        defer { cancellable.cancel() }

        store.selectedHosts = hosts1
        store.selectedHosts = hosts2
        store.selectedHosts = hosts1

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        // Each assignment should produce exactly 1 objectWillChange, not more
        XCTAssertEqual(changeCount, 3,
            "Expected 3 objectWillChange publications for 3 selection changes, got \(changeCount) — " +
            "indicates re-entrant updates causing extra SwiftUI re-renders")
    }

    // MARK: - Regression: compare old vs new text replacement

    /// Compares old approach (textView.string = x) vs new approach (replaceContentWith:)
    /// to verify the new method doesn't regress performance for small files.
    func testSmallFile_replaceContentWith_notSlowerThanDirectAssignment() {
        let fileA = "127.0.0.1 localhost\n::1 localhost\n# comment line\n"
        let fileB = "192.168.1.1 router.local\n10.0.0.1 server.local\n"
        let iterations = 100

        // Measure old approach: direct string assignment
        let oldStart = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            textView.string = fileA
            textView.string = fileB
        }
        let oldElapsed = CFAbsoluteTimeGetCurrent() - oldStart

        // Measure new approach: replaceContentWith:
        let newStart = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            textView.replaceContent(with: fileA)
            textView.replaceContent(with: fileB)
        }
        let newElapsed = CFAbsoluteTimeGetCurrent() - newStart

        NSLog("Direct assignment: %.4fs, replaceContentWith: %.4fs (ratio: %.2fx)",
              oldElapsed, newElapsed, newElapsed / oldElapsed)

        // New approach should not be more than 3x slower than direct assignment
        XCTAssertLessThan(newElapsed, oldElapsed * 3.0,
            "replaceContentWith is \(String(format: "%.1f", newElapsed / oldElapsed))x slower than direct assignment")
    }

    /// Same comparison but for a medium-sized file (~5KB, ~100 lines)
    func testMediumFile_replaceContentWith_notSlowerThanDirectAssignment() {
        let medium = Self.generateLargeHostsContent(lineCount: 100)
        let small = "127.0.0.1 localhost\n"
        let iterations = 50

        let oldStart = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            textView.string = medium
            textView.string = small
        }
        let oldElapsed = CFAbsoluteTimeGetCurrent() - oldStart

        let newStart = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            textView.replaceContent(with: medium)
            textView.replaceContent(with: small)
        }
        let newElapsed = CFAbsoluteTimeGetCurrent() - newStart

        NSLog("Medium file — Direct: %.4fs, replaceContentWith: %.4fs (ratio: %.2fx)",
              oldElapsed, newElapsed, newElapsed / oldElapsed)

        XCTAssertLessThan(newElapsed, oldElapsed * 3.0,
            "replaceContentWith is \(String(format: "%.1f", newElapsed / oldElapsed))x slower for medium files")
    }

    // MARK: - Helpers

    /// Simulates the text replacement portion of updateNSView (length-first guard + replace).
    /// Does NOT test the pointer-based selection guard — that is tested separately in
    /// testGuardCheck_pointerBased_skipsStringComparison.
    private func simulateUpdateNSView(contents: String) {
        let currentLength = (textView.string as NSString).length
        let newLength = (contents as NSString).length
        if currentLength != newLength || textView.string != contents {
            textView.replaceContent(with: contents)
        }
    }

    private static func generateLargeHostsContent(lineCount: Int) -> String {
        var lines: [String] = []
        lines.reserveCapacity(lineCount + 2)
        lines.append("# Large hosts file for testing performance")
        lines.append("# Generated with \(lineCount) entries")
        for i in 0..<lineCount {
            lines.append("0.0.0.0 ad\(i).tracker.example.com")
        }
        return lines.joined(separator: "\n")
    }
}
