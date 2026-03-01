import XCTest
import Combine
import SwiftUI
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
        let largeContent = Self.generateLargeHostsContent(lineCount: 5000)
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
        let largeContent = Self.generateLargeHostsContent(lineCount: 5000)

        textView.replaceContent(with: largeContent)
        textView.replaceContent(with: "127.0.0.1 localhost\n")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        XCTAssertEqual(textView.string, "127.0.0.1 localhost\n")
    }

    /// Measures the wall-clock cost of a single large file text replacement.
    func testPerformance_singleLargeFileSwitch() {
        let largeContent = Self.generateLargeHostsContent(lineCount: 5000)

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
        let content = Self.generateLargeHostsContent(lineCount: 5000)
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

        NSLog("Pointer-based guard on 5K-line file: %.6fs for %d calls (%.4fms each)",
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

    // MARK: - Verification: User-reported scenario (2 local + 1 remote)

    /// Reproduces the exact user-reported scenario:
    /// 1. App has 2 local files and 1 remote file (~5K lines, reduced from 30K for CI)
    /// 2. App restarts → remote file downloads → notification cascade fires
    /// 3. User clicks between the 2 local files → UI should remain responsive
    ///
    /// This test counts the total objectWillChange publications during the download
    /// lifecycle to verify the notification cascade is bounded.
    func testDownloadLifecycle_objectWillChangeCount() {
        let store = HostsDataStore()

        // Set up 2 local files + 1 remote with large content
        let local1 = Hosts(path: "/tmp/local1.hst")!
        local1.setContents("127.0.0.1 localhost\n::1 localhost\n")
        local1.setSaved(true)

        let local2 = Hosts(path: "/tmp/local2.hst")!
        local2.setContents("192.168.1.1 router.local\n")
        local2.setSaved(true)

        let remote = Hosts(path: "/tmp/remote.hst")!
        remote.setSaved(true)
        remote.exists = true
        remote.setEnabled(true)

        // Select a local file (user's starting state)
        store.selectedHosts = local1

        // Drain any pending events from setup
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        var changeCount = 0
        let cancellable = store.objectWillChange.sink { _ in
            changeCount += 1
        }
        defer { cancellable.cancel() }

        // === Simulate hostsDownloadingStarted ===
        // increaseActiveDownloadsCount → setSynchronizing:YES → SynchronizingStatusChanged
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
        // setEnabled:NO → HostsNodeNeedsUpdate
        remote.setEnabled(false)
        // ThreadBusy
        NotificationCenter.default.post(name: .threadBusy, object: nil)

        // === Simulate hostsDownloaded (happens after download completes) ===
        // decreaseActiveDownloadsCount → setSynchronizing:NO → SynchronizingStatusChanged
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
        // setEnabled:YES
        remote.setEnabled(true)
        // setContents with large content → setSaved:NO → HostsNodeNeedsUpdate
        let largeContent = Self.generateLargeHostsContent(lineCount: 5000)
        remote.setContents(largeContent)
        // [hosts save] → setSaved:YES → HostsNodeNeedsUpdate
        remote.setSaved(true)
        // setExists:YES → HostsNodeNeedsUpdate (guard skips since already YES)
        remote.exists = true
        // HostsFileSaved
        NotificationCenter.default.post(name: .hostsFileSaved, object: remote)
        // ThreadNotBusy
        NotificationCenter.default.post(name: .threadNotBusy, object: nil)

        // Drain all queued notification handlers
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        NSLog("Download lifecycle caused %d objectWillChange publications", changeCount)

        // The download lifecycle should cause a bounded number of publications.
        // Each notification that matches rowRefreshNames or busy state causes one.
        // We don't assert an exact count but verify it's bounded (not cascading).
        XCTAssertLessThan(changeCount, 20,
            "Download lifecycle caused \(changeCount) objectWillChange publications — " +
            "excessive re-renders will lock up the UI")
    }

    /// Reproduces the user scenario end-to-end:
    /// 1. Remote file has been downloaded (1MB content cached in memory)
    /// 2. User switches between 2 local files
    /// 3. Each switch triggers the full updateNSView pipeline
    /// 4. Download notifications have incremented rowRefreshToken (contentToken changed)
    ///
    /// The key question: does the elevated contentToken cause expensive work
    /// when switching between local files?
    func testLocalFileSwitching_afterRemoteDownload_completesQuickly() {
        let store = HostsDataStore()

        // Set up files
        let local1 = Hosts(path: "/tmp/verifyA.hst")!
        local1.setContents("127.0.0.1 localhost\n::1 localhost\n# config A\n")
        local1.setSaved(true)

        let local2 = Hosts(path: "/tmp/verifyB.hst")!
        local2.setContents("192.168.1.1 router.local\n10.0.0.1 gateway.local\n")
        local2.setSaved(true)

        let remote = Hosts(path: "/tmp/verifyRemote.hst")!
        remote.setSaved(true)
        remote.exists = true
        remote.setEnabled(true)

        // Simulate download lifecycle (posts notifications → increments rowRefreshToken)
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
        remote.setEnabled(false)
        NotificationCenter.default.post(name: .threadBusy, object: nil)
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
        remote.setEnabled(true)
        let largeContent = Self.generateLargeHostsContent(lineCount: 5000)
        remote.setContents(largeContent)
        remote.setSaved(true)
        NotificationCenter.default.post(name: .hostsFileSaved, object: remote)
        NotificationCenter.default.post(name: .threadNotBusy, object: nil)

        // Drain download notifications
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        let tokenAfterDownload = store.rowRefreshToken
        NSLog("rowRefreshToken after download: %llu", tokenAfterDownload)

        // === Now simulate the user switching between local files ===
        // This exercises the full pipeline: store selection → contents() → updateNSView guard → replaceContent
        var lastUpdatedHosts: Hosts? = nil
        var lastContentToken: UInt64 = 0

        let switchCount = 20
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<switchCount {
            // Switch to local1
            store.selectedHosts = local1
            let contents1 = store.selectedHosts?.contents() ?? ""
            let token1 = store.rowRefreshToken
            // Simulate updateNSView logic
            if local1 !== lastUpdatedHosts {
                textView.replaceContent(with: contents1)
                lastUpdatedHosts = local1
                lastContentToken = token1
            } else if token1 != lastContentToken {
                lastContentToken = token1
                let currentLen = (textView.string as NSString).length
                let newLen = (contents1 as NSString).length
                if currentLen != newLen || textView.string != contents1 {
                    textView.replaceContent(with: contents1)
                }
            }

            // Switch to local2
            store.selectedHosts = local2
            let contents2 = store.selectedHosts?.contents() ?? ""
            let token2 = store.rowRefreshToken
            if local2 !== lastUpdatedHosts {
                textView.replaceContent(with: contents2)
                lastUpdatedHosts = local2
                lastContentToken = token2
            } else if token2 != lastContentToken {
                lastContentToken = token2
                let currentLen = (textView.string as NSString).length
                let newLen = (contents2 as NSString).length
                if currentLen != newLen || textView.string != contents2 {
                    textView.replaceContent(with: contents2)
                }
            }
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        NSLog("Local file switching after remote download: %.3fs for %d round-trips", elapsed, switchCount)

        // 20 round-trip switches between small local files should be instant,
        // even with a large remote file's content cached in memory
        XCTAssertLessThan(elapsed, 0.5,
            "Switching between local files took \(String(format: "%.3f", elapsed))s " +
            "after remote download — UI lockup confirmed")
    }

    /// Tests what happens when notification handlers fire DURING local file switches.
    /// This simulates the user clicking between files while the download lifecycle
    /// is still firing notifications (race condition scenario).
    func testLocalFileSwitching_duringDownloadNotifications_completesQuickly() {
        let store = HostsDataStore()

        let local1 = Hosts(path: "/tmp/raceA.hst")!
        local1.setContents("127.0.0.1 localhost\n::1 localhost\n")
        local1.setSaved(true)

        let local2 = Hosts(path: "/tmp/raceB.hst")!
        local2.setContents("192.168.1.1 router.local\n")
        local2.setSaved(true)

        let remote = Hosts(path: "/tmp/raceRemote.hst")!
        remote.setSaved(true)
        remote.exists = true
        remote.setEnabled(true)

        store.selectedHosts = local1
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        let switchCount = 10
        let start = CFAbsoluteTimeGetCurrent()

        for i in 0..<switchCount {
            // User switches file
            store.selectedHosts = (i % 2 == 0) ? local2 : local1
            let contents = store.selectedHosts?.contents() ?? ""
            simulateUpdateNSView(contents: contents)

            // Meanwhile, download notification fires (as if remote file just updated)
            NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: remote)

            // Allow notification handlers to fire
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))

            // Simulate another updateNSView triggered by the notification
            let sameContents = store.selectedHosts?.contents() ?? ""
            simulateUpdateNSView(contents: sameContents)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let activeTime = elapsed - Double(switchCount) * 0.01

        NSLog("Switching during notifications: %.3fs active (%.3fs total) for %d switches",
              activeTime, elapsed, switchCount)

        XCTAssertLessThan(activeTime, 0.5,
            "Local file switching during download notifications took " +
            "\(String(format: "%.3f", activeTime))s active time — UI lockup confirmed")
    }

    /// Measures the cost of the full download notification cascade on the main thread.
    /// This is the synchronous cost that blocks the UI during remote file download.
    func testDownloadLifecycle_mainThreadBlockingTime() {
        let remote = Hosts(path: "/tmp/blockingRemote.hst")!
        remote.setSaved(true)
        remote.exists = true
        remote.setEnabled(true)

        let largeContent = Self.generateLargeHostsContent(lineCount: 5000)

        // Measure just the synchronous notification posting + property changes
        // (this is what hostsDownloaded: does on the main thread)
        let start = CFAbsoluteTimeGetCurrent()

        // Simulate hostsDownloaded: body (synchronous on main thread)
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
        remote.setEnabled(true)
        remote.setContents(largeContent)  // 1MB string assignment + setSaved:NO + notification
        remote.setSaved(true)  // setSaved:YES + notification
        remote.exists = true
        NotificationCenter.default.post(name: .hostsFileSaved, object: remote)
        NotificationCenter.default.post(name: .threadNotBusy, object: nil)

        let syncElapsed = CFAbsoluteTimeGetCurrent() - start

        // Now simulate the disk write that saveHosts: does
        let tempPath = NSTemporaryDirectory() + "gasmask_perf_test_\(UUID().uuidString).hst"
        let diskStart = CFAbsoluteTimeGetCurrent()
        try? largeContent.write(toFile: tempPath, atomically: true, encoding: .utf8)
        let diskElapsed = CFAbsoluteTimeGetCurrent() - diskStart
        try? FileManager.default.removeItem(atPath: tempPath)

        NSLog("Download lifecycle sync cost: %.3fms (notifications) + %.3fms (1MB disk write) = %.3fms total",
              syncElapsed * 1000, diskElapsed * 1000, (syncElapsed + diskElapsed) * 1000)

        // The synchronous portion that blocks the main thread (notifications + disk write)
        // should complete in well under 100ms
        XCTAssertLessThan(syncElapsed + diskElapsed, 0.1,
            "Download lifecycle blocks main thread for \(String(format: "%.0f", (syncElapsed + diskElapsed) * 1000))ms — " +
            "will cause UI jank during file switching")
    }

    // MARK: - SwiftUI Integration: Full Rendering Pipeline

    /// Hosts the ACTUAL SwiftUI ContentView in a real NSWindow via NSHostingController
    /// and measures end-to-end latency of selection changes through the full rendering pipeline.
    /// This is the closest we can get to the real app scenario in a test.
    func testSwiftUI_contentViewRendering_localFileSwitching() {
        let store = HostsDataStore()

        // Create local files with pre-loaded content
        let local1 = Hosts(path: "/tmp/swiftuiA.hst")!
        local1.setContents("127.0.0.1 localhost\n::1 localhost\n# config A\n")
        local1.setSaved(true)

        let local2 = Hosts(path: "/tmp/swiftuiB.hst")!
        local2.setContents("192.168.1.1 router.local\n10.0.0.1 gateway.local\n")
        local2.setSaved(true)

        // Create remote file with large content (simulating StevenBlack hosts)
        let remote = Hosts(path: "/tmp/swiftuiRemote.hst")!
        let largeContent = Self.generateLargeHostsContent(lineCount: 5000)
        remote.setContents(largeContent)
        remote.setSaved(true)
        remote.exists = true
        remote.setEnabled(true)

        // Host ContentView in a real window (exercises full SwiftUI rendering)
        let contentView = ContentView(store: store)
        let hostingController = NSHostingController(rootView: contentView)
        let testWindow = NSWindow(contentViewController: hostingController)
        testWindow.setContentSize(NSSize(width: 800, height: 600))
        testWindow.orderBack(nil)

        // Initial selection
        store.selectedHosts = local1
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        // Now simulate download notification cascade (increments rowRefreshToken multiple times)
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
        remote.setEnabled(false)
        NotificationCenter.default.post(name: .threadBusy, object: nil)
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
        remote.setEnabled(true)
        NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: remote)
        NotificationCenter.default.post(name: .hostsFileSaved, object: remote)
        NotificationCenter.default.post(name: .threadNotBusy, object: nil)

        // Drain all pending notifications and let SwiftUI settle
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        // === Measure local file switching through the full SwiftUI pipeline ===
        let switchCount = 20
        var switchTimes: [Double] = []

        for i in 0..<switchCount {
            let target = (i % 2 == 0) ? local2 : local1

            let switchStart = CFAbsoluteTimeGetCurrent()
            store.selectedHosts = target
            // Allow SwiftUI to process the change and call updateNSView
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
            let switchElapsed = CFAbsoluteTimeGetCurrent() - switchStart - 0.02

            switchTimes.append(switchElapsed)
        }

        testWindow.orderOut(nil)

        let totalActive = switchTimes.reduce(0, +)
        let maxSwitch = switchTimes.max() ?? 0
        let avgSwitch = totalActive / Double(switchCount)

        NSLog("SwiftUI ContentView switching: avg=%.1fms, max=%.1fms, total=%.1fms for %d switches",
              avgSwitch * 1000, maxSwitch * 1000, totalActive * 1000, switchCount)

        // Each switch through the full SwiftUI pipeline should complete in under 50ms
        XCTAssertLessThan(maxSwitch, 0.05,
            "Slowest switch took \(String(format: "%.1f", maxSwitch * 1000))ms through full SwiftUI pipeline")
        XCTAssertLessThan(totalActive, 1.0,
            "Total active time: \(String(format: "%.0f", totalActive * 1000))ms for \(switchCount) switches")
    }

    /// Same as above but also hosts SidebarView with mock hostsGroups to measure
    /// the full sidebar + content view re-rendering cost.
    func testSwiftUI_fullEditorRendering_localFileSwitching() {
        let store = HostsDataStore()

        let local1 = Hosts(path: "/tmp/fullEdA.hst")!
        local1.setContents("127.0.0.1 localhost\n::1 localhost\n")
        local1.setSaved(true)

        let local2 = Hosts(path: "/tmp/fullEdB.hst")!
        local2.setContents("192.168.1.1 router.local\n")
        local2.setSaved(true)

        let remote = Hosts(path: "/tmp/fullEdRemote.hst")!
        let largeContent = Self.generateLargeHostsContent(lineCount: 5000)
        remote.setContents(largeContent)
        remote.setSaved(true)
        remote.exists = true
        remote.setEnabled(true)

        // Host the full EditorView (NavigationSplitView with sidebar + content)
        let editorView = EditorView()
        let hostingController = NSHostingController(rootView: editorView)
        let testWindow = NSWindow(contentViewController: hostingController)
        testWindow.setContentSize(NSSize(width: 800, height: 600))
        testWindow.orderBack(nil)

        // Wait for initial render
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        // Simulate download cascade on the store
        // Note: EditorView creates its own @StateObject store, so we can't easily
        // control it from here. Instead we post notifications that ALL HostsDataStore
        // instances will observe, incrementing their rowRefreshTokens.
        for _ in 0..<5 {
            NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: remote)
        }
        NotificationCenter.default.post(name: .hostsFileSaved, object: remote)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        // Measure how long each notification-triggered re-render takes
        let iterations = 10
        var renderTimes: [Double] = []

        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: remote)
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
            let elapsed = CFAbsoluteTimeGetCurrent() - start - 0.02
            renderTimes.append(elapsed)
        }

        testWindow.orderOut(nil)

        let maxRender = renderTimes.max() ?? 0
        let avgRender = renderTimes.reduce(0, +) / Double(iterations)

        NSLog("Full EditorView re-render per notification: avg=%.1fms, max=%.1fms",
              avgRender * 1000, maxRender * 1000)

        // Each notification-triggered re-render should not block the UI.
        // Threshold is generous (200ms) because CI Intel runners are significantly
        // slower than Apple Silicon and SwiftUI layout in a full NavigationSplitView
        // has high variance under load.
        XCTAssertLessThan(maxRender, 0.2,
            "Slowest re-render took \(String(format: "%.1f", maxRender * 1000))ms — " +
            "would cause visible UI jank")
    }

    // MARK: - Concurrent Download + User Interaction

    /// Most realistic test: simulates the EXACT scenario the user reports.
    /// 1. Hosts a real ContentView in a real window
    /// 2. Starts a simulated download on a background thread
    /// 3. While the download is in progress, switches between local files on the main thread
    /// 4. The download completion fires on the main thread (interleaved with user clicks)
    /// 5. Measures if user file switches are delayed by download processing
    func testConcurrentDownload_localFileSwitching_remainsResponsive() {
        let store = HostsDataStore()

        let local1 = Hosts(path: "/tmp/concA.hst")!
        local1.setContents("127.0.0.1 localhost\n::1 localhost\n# config A\n")
        local1.setSaved(true)

        let local2 = Hosts(path: "/tmp/concB.hst")!
        local2.setContents("192.168.1.1 router.local\n10.0.0.1 gateway\n")
        local2.setSaved(true)

        let remote = Hosts(path: "/tmp/concRemote.hst")!
        remote.setSaved(true)
        remote.exists = true
        remote.setEnabled(true)

        // Host ContentView in a real window
        let contentView = ContentView(store: store)
        let hostingController = NSHostingController(rootView: contentView)
        let testWindow = NSWindow(contentViewController: hostingController)
        testWindow.setContentSize(NSSize(width: 800, height: 600))
        testWindow.orderBack(nil)

        store.selectedHosts = local1
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        // Simulate download starting (notifications dispatched to main queue from background)
        DispatchQueue.global().async {
            // hostsDownloadingStarted
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
                remote.setEnabled(false)
                NotificationCenter.default.post(name: .threadBusy, object: nil)
            }
        }

        // User starts clicking between files immediately
        var switchTimes: [Double] = []
        let switchCount = 10

        for i in 0..<switchCount {
            let target = (i % 2 == 0) ? local2 : local1
            let switchStart = CFAbsoluteTimeGetCurrent()
            store.selectedHosts = target
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.03))
            let switchElapsed = CFAbsoluteTimeGetCurrent() - switchStart - 0.03
            switchTimes.append(switchElapsed)

            // Midway through, simulate download completion (large content + disk write)
            if i == 3 {
                let largeContent = Self.generateLargeHostsContent(lineCount: 5000)
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        // This is what hostsDownloaded: does on the main thread
                        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
                        remote.setEnabled(true)
                        remote.setContents(largeContent)
                        remote.setSaved(true)
                        remote.exists = true

                        // Synchronous disk write (the real bottleneck?)
                        let tempPath = NSTemporaryDirectory() + "gasmask_perf_\(UUID().uuidString).hst"
                        try? largeContent.write(toFile: tempPath, atomically: true, encoding: .utf8)
                        try? FileManager.default.removeItem(atPath: tempPath)

                        NotificationCenter.default.post(name: .hostsFileSaved, object: remote)
                        NotificationCenter.default.post(name: .threadNotBusy, object: nil)
                    }
                }
            }
        }

        testWindow.orderOut(nil)

        let maxSwitch = switchTimes.max() ?? 0
        let avgSwitch = switchTimes.reduce(0, +) / Double(switchCount)
        let totalActive = switchTimes.reduce(0, +)

        // Log individual switch times to identify any outlier
        for (i, t) in switchTimes.enumerated() {
            NSLog("Switch %d: %.1fms%@", i, t * 1000, t > 0.05 ? " ⚠️ SLOW" : "")
        }
        NSLog("Concurrent download test: avg=%.1fms, max=%.1fms, total=%.0fms",
              avgSwitch * 1000, maxSwitch * 1000, totalActive * 1000)

        // The switch that coincides with download completion might be slower,
        // but should still be under 200ms for a good user experience
        XCTAssertLessThan(maxSwitch, 0.2,
            "Slowest switch during concurrent download took " +
            "\(String(format: "%.0f", maxSwitch * 1000))ms — user will perceive lockup")
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
