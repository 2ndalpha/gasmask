import XCTest
@testable import Gas_Mask

final class HostsDataStoreTests: XCTestCase {

    // MARK: - Notification Name Constants

    /// Verify Swift notification names match the ObjC #define values from Gas_Mask_Prefix.pch
    func testNotificationNames_matchObjCDefines() {
        XCTAssertEqual(NSNotification.Name.hostsFileCreated.rawValue, "HostsFileCreatedNotification")
        XCTAssertEqual(NSNotification.Name.hostsFileRemoved.rawValue, "HostsFileRemovedNotification")
        XCTAssertEqual(NSNotification.Name.hostsFileRenamed.rawValue, "HostsFileRenamedNotification")
        XCTAssertEqual(NSNotification.Name.hostsFileSaved.rawValue, "HostsFileSavedNotification")
        XCTAssertEqual(NSNotification.Name.hostsNodeNeedsUpdate.rawValue, "HostsNodeNeedsUpdateNotification")
        XCTAssertEqual(NSNotification.Name.hostsFileShouldBeRenamed.rawValue, "HostsFileShouldBeRenamedNotification")
        XCTAssertEqual(NSNotification.Name.hostsFileShouldBeSelected.rawValue, "HostsFileShouldBeSelectedNotification")
        XCTAssertEqual(NSNotification.Name.synchronizingStatusChanged.rawValue, "SynchronizingStatusChangedNotification")
        XCTAssertEqual(NSNotification.Name.allHostsFilesLoadedFromDisk.rawValue, "AllHostsFilesLoadedFromDiskNotification")
    }

    // MARK: - Instance Creation

    func testInit_returnsDistinctInstances() {
        let a = HostsDataStore()
        let b = HostsDataStore()
        XCTAssertFalse(a === b)
    }

    // MARK: - Notification Response

    func testRenameNotification_setsRenamingHosts() {
        let store = HostsDataStore()

        let hosts = Hosts(path: "/tmp/test.hst")!
        store.renamingHosts = nil

        NotificationCenter.default.post(name: .hostsFileShouldBeRenamed, object: hosts)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertTrue(store.renamingHosts === hosts)
    }

    func testSelectNotification_updatesSelectedHosts() {
        let store = HostsDataStore()

        let hosts = Hosts(path: "/tmp/test.hst")!
        store.selectedHosts = nil

        NotificationCenter.default.post(name: .hostsFileShouldBeSelected, object: hosts)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertTrue(store.selectedHosts === hosts)
    }

    // MARK: - Busy State

    func testBusyNotification_setsIsBusy() {
        let store = HostsDataStore()
        XCTAssertFalse(store.isBusy, "precondition")

        NotificationCenter.default.post(name: .threadBusy, object: nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertTrue(store.isBusy)
    }

    func testNotBusyNotification_clearsIsBusy() {
        let store = HostsDataStore()

        NotificationCenter.default.post(name: .threadBusy, object: nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertTrue(store.isBusy, "precondition")

        NotificationCenter.default.post(name: .threadNotBusy, object: nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertFalse(store.isBusy)
    }
}
