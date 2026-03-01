import XCTest
import Combine
@testable import Gas_Mask

final class HostsDataStoreNotificationTests: XCTestCase {

    // MARK: - Notification Coalescing

    /// Verifies that multiple rapid row-refresh notifications are coalesced
    /// into a single `rowRefreshToken` increment (one SwiftUI re-render).
    func testCoalescing_rapidNotifications_incrementTokenOnce() {
        let store = HostsDataStore()
        let before = store.rowRefreshToken

        // Post 10 rapid notifications without draining the run loop
        for _ in 0..<10 {
            NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: nil)
        }

        // Drain: observer blocks fire, then the single coalesced async block
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        let increment = store.rowRefreshToken &- before
        XCTAssertEqual(increment, 1,
            "Expected 1 coalesced increment, got \(increment) — " +
            "each increment triggers a full SwiftUI re-render")
    }

    /// Verifies coalescing across different notification types.
    /// A download lifecycle posts hostsFileSaved, hostsNodeNeedsUpdate,
    /// and synchronizingStatusChanged in rapid succession.
    func testCoalescing_mixedNotificationTypes_incrementTokenOnce() {
        let store = HostsDataStore()
        let before = store.rowRefreshToken

        // Simulate notification cascade from hostsDownloaded:
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: nil)
        NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: nil)
        NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: nil)
        NotificationCenter.default.post(name: .hostsFileSaved, object: nil)
        NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: nil)
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: nil)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        let increment = store.rowRefreshToken &- before
        XCTAssertEqual(increment, 1,
            "Expected 1 coalesced increment from mixed notifications, got \(increment)")
    }

    /// Verifies that a single notification still increments the token by 1
    /// (coalescing doesn't break the single-notification case).
    func testCoalescing_singleNotification_incrementsTokenByOne() {
        let store = HostsDataStore()
        let before = store.rowRefreshToken

        NotificationCenter.default.post(name: .hostsFileSaved, object: nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        XCTAssertEqual(store.rowRefreshToken, before &+ 1)
    }

    /// Verifies that notifications separated by a run loop drain each
    /// produce their own increment (coalescing is per-cycle, not global).
    func testCoalescing_separateCycles_incrementTokenSeparately() {
        let store = HostsDataStore()
        let before = store.rowRefreshToken

        // First cycle
        NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: nil)
        NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        // Second cycle
        NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: nil)
        NotificationCenter.default.post(name: .hostsNodeNeedsUpdate, object: nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        let increment = store.rowRefreshToken &- before
        XCTAssertEqual(increment, 2,
            "Expected 2 increments (one per cycle), got \(increment)")
    }

    // MARK: - objectWillChange Coalescing

    /// Verifies that a download lifecycle's notification cascade produces
    /// a bounded number of objectWillChange signals.
    func testCoalescing_downloadLifecycle_boundedObjectWillChange() {
        let store = HostsDataStore()

        let remote = Hosts(path: "/tmp/coalesceTest.hst")!
        remote.setSaved(true)
        remote.exists = true
        remote.setEnabled(true)

        // Drain any pending events
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        var changeCount = 0
        let cancellable = store.objectWillChange.sink { _ in
            changeCount += 1
        }
        defer { cancellable.cancel() }

        // Simulate full download lifecycle notification cascade
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
        remote.setEnabled(false)
        NotificationCenter.default.post(name: .threadBusy, object: nil)
        NotificationCenter.default.post(name: .synchronizingStatusChanged, object: remote)
        remote.setEnabled(true)
        remote.setContents("large content here")
        remote.setSaved(true)
        NotificationCenter.default.post(name: .hostsFileSaved, object: remote)
        NotificationCenter.default.post(name: .threadNotBusy, object: nil)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))

        // With coalescing: row refresh notifications collapse to 1 objectWillChange,
        // plus busy state changes (isBusy = true, isBusy = false) = ~3 total.
        // Without coalescing: 8-12 objectWillChange signals.
        XCTAssertLessThanOrEqual(changeCount, 5,
            "Download lifecycle caused \(changeCount) objectWillChange signals — " +
            "expected ≤5 with coalescing (was 8-12 without)")
    }
}
