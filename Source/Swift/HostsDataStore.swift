import Foundation
import Combine

// MARK: - Notification Names
// These are defined as #define macros in Gas_Mask_Prefix.pch, which Swift cannot import.
// Mirror them here as NSNotification.Name constants.

extension NSNotification.Name {
    static let hostsFileCreated = NSNotification.Name("HostsFileCreatedNotification")
    static let hostsFileRemoved = NSNotification.Name("HostsFileRemovedNotification")
    static let hostsFileRenamed = NSNotification.Name("HostsFileRenamedNotification")
    static let hostsFileSaved = NSNotification.Name("HostsFileSavedNotification")
    static let hostsNodeNeedsUpdate = NSNotification.Name("HostsNodeNeedsUpdateNotification")
    static let hostsFileShouldBeRenamed = NSNotification.Name("HostsFileShouldBeRenamedNotification")
    static let hostsFileShouldBeSelected = NSNotification.Name("HostsFileShouldBeSelectedNotification")
    static let synchronizingStatusChanged = NSNotification.Name("SynchronizingStatusChangedNotification")
    static let allHostsFilesLoadedFromDisk = NSNotification.Name("AllHostsFilesLoadedFromDiskNotification")
}

// MARK: - HostsDataStore

final class HostsDataStore: ObservableObject {

    static let shared = HostsDataStore()

    // MARK: Published Properties

    @Published var hostsGroups: [HostsGroup] = []
    @Published var selectedHosts: Hosts? {
        didSet {
            guard selectedHosts !== oldValue, !isSyncingSelection else { return }
            if let hosts = selectedHosts {
                HostsMainController.defaultInstance()?.select(hosts)
            }
        }
    }
    @Published var filesCount: Int = 0
    @Published var canRemoveFiles: Bool = false
    @Published var renamingHosts: Hosts?

    // MARK: Private

    private var notificationObservers: [NSObjectProtocol] = []
    private var isSyncingSelection = false

    // MARK: Init

    private init() {
        refreshGroups()
        refreshFilesCount()
        observeNotifications()
    }

    // MARK: Refresh

    func refreshGroups() {
        guard let controller = HostsMainController.defaultInstance(),
              let content = controller.content as? [HostsGroup] else {
            hostsGroups = []
            return
        }
        hostsGroups = content
    }

    private func refreshFilesCount() {
        guard let controller = HostsMainController.defaultInstance() else { return }
        filesCount = Int(controller.filesCount())
        canRemoveFiles = controller.canRemoveFiles()
    }

    // MARK: Selection Sync

    /// Called when the ObjC layer selects a hosts file (via notification).
    private func syncSelectionFromModel(_ hosts: Hosts?) {
        isSyncingSelection = true
        selectedHosts = hosts
        isSyncingSelection = false
    }

    // MARK: Notification Observers

    private func observeNotifications() {
        let nc = NotificationCenter.default

        // Data change notifications — refresh groups and counts
        let refreshNames: [NSNotification.Name] = [
            .hostsFileCreated,
            .hostsFileRemoved,
            .hostsFileRenamed
        ]

        for name in refreshNames {
            let observer = nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.refreshGroups()
                self?.refreshFilesCount()
            }
            notificationObservers.append(observer)
        }

        // All files loaded — refresh data then select the active file
        let loadedObserver = nc.addObserver(
            forName: .allHostsFilesLoadedFromDisk, object: nil, queue: .main
        ) { [weak self] _ in
            self?.refreshGroups()
            self?.refreshFilesCount()
            let active = HostsMainController.defaultInstance()?.activeHostsFile()
            self?.syncSelectionFromModel(active)
        }
        notificationObservers.append(loadedObserver)

        // Single-row refresh notifications — reassign hostsGroups to force SwiftUI diffing
        let rowRefreshNames: [NSNotification.Name] = [
            .hostsFileSaved,
            .hostsNodeNeedsUpdate,
            .synchronizingStatusChanged
        ]

        for name in rowRefreshNames {
            let observer = nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                self.hostsGroups = self.hostsGroups
            }
            notificationObservers.append(observer)
        }

        // UI action notifications
        let renameObserver = nc.addObserver(
            forName: .hostsFileShouldBeRenamed, object: nil, queue: .main
        ) { [weak self] notification in
            self?.renamingHosts = notification.object as? Hosts
        }
        notificationObservers.append(renameObserver)

        let selectObserver = nc.addObserver(
            forName: .hostsFileShouldBeSelected, object: nil, queue: .main
        ) { [weak self] notification in
            if let hosts = notification.object as? Hosts {
                self?.syncSelectionFromModel(hosts)
            }
        }
        notificationObservers.append(selectObserver)
    }

}
