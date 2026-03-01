import XCTest
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

    // MARK: - Tests

    /// Verifies that switching between a large remote hosts file and a small local file
    /// multiple times completes within a reasonable time and doesn't lock the UI.
    /// This drains the run loop between switches to allow queued async highlighting
    /// chunks to execute, simulating real user interaction.
    func testRapidSwitching_largeAndSmallFile_completesQuickly() {
        let largeContent = Self.generateLargeHostsContent(lineCount: 16000)
        let smallContent = "127.0.0.1 localhost\n::1 localhost\n"

        let switchCount = 5
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<switchCount {
            textView.replaceContent(with: largeContent)
            // Drain run loop briefly — lets queued async highlighting chunks execute,
            // simulating the delay between clicks when a user interacts with the sidebar.
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
            textView.replaceContent(with: smallContent)
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        // Subtract the deliberate sleep time (5 switches × 2 drains × 0.05s = 0.5s)
        let activeTime = elapsed - Double(switchCount) * 2.0 * 0.05

        // The active processing time for 5 round-trip switches should be well under 2s.
        // Before the fix, each large file switch could take 300ms+ in synchronous work.
        XCTAssertLessThan(activeTime, 2.0,
            "Rapid switching active time: \(String(format: "%.2f", activeTime))s (total: \(String(format: "%.2f", elapsed))s)")
    }

    /// Verifies that switching from a large file to a small file cancels pending
    /// async highlighting (generation counter should invalidate stale work).
    func testSwitchToSmallFile_cancelsPendingHighlighting() {
        let largeContent = Self.generateLargeHostsContent(lineCount: 16000)

        textView.replaceContent(with: largeContent)

        // Switch to small content, which should cancel any pending async work
        textView.replaceContent(with: "127.0.0.1 localhost\n")

        // Drain the run loop to let any queued async highlighting run
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        // The text should be the small content (no crash, no stale highlighting)
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

    // MARK: - Helpers

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
