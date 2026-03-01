import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @ObservedObject var store: HostsDataStore

    @State private var editingName: String = ""
    @State private var isEditing = false
    @State private var renameError: String?
    @State private var hostsToRemove: Hosts?

    var body: some View {
        List(selection: $store.selectedHosts) {
            ForEach(store.hostsGroups, id: \.self) { group in
                let children = (group.children as? [Hosts]) ?? []
                Section(header: HostsRowView(hosts: group, isGroup: true, refreshToken: store.rowRefreshToken)) {
                    ForEach(children, id: \.self) { hosts in
                        rowContent(for: hosts)
                            .tag(hosts)
                    }
                }
                .onDrop(of: [.fileURL, .url], delegate: SidebarDropDelegate(group: group))
            }
        }
        .listStyle(.sidebar)
        .onChange(of: store.renamingHosts) { newValue in
            if let hosts = newValue {
                beginRename(hosts)
            }
        }
        .alert("Rename Error", isPresented: Binding(
            get: { renameError != nil },
            set: { if !$0 { renameError = nil } }
        )) {
            Button("OK") { renameError = nil }
        } message: {
            Text(renameError ?? "")
        }
        .alert("Remove Hosts File", isPresented: Binding(
            get: { hostsToRemove != nil },
            set: { if !$0 { hostsToRemove = nil } }
        )) {
            Button("Cancel", role: .cancel) { hostsToRemove = nil }
            Button("Remove", role: .destructive) {
                if let hosts = hostsToRemove {
                    HostsMainController.defaultInstance()?.removeHostsFile(hosts, moveToTrash: true)
                }
                hostsToRemove = nil
            }
        } message: {
            Text("Are you sure you want to remove \"\(hostsToRemove?.name() ?? "")\"? The file will be moved to Trash.")
        }
    }

    // MARK: - Row Content

    @ViewBuilder
    private func rowContent(for hosts: Hosts) -> some View {
        if isEditing, store.renamingHosts === hosts {
            renameField(for: hosts)
        } else {
            HostsRowView(hosts: hosts, isGroup: false, refreshToken: store.rowRefreshToken)
                .contextMenu { contextMenuItems(for: hosts) }
        }
    }

    // MARK: - Inline Rename

    private func renameField(for hosts: Hosts) -> some View {
        TextField("Name", text: $editingName)
        .textFieldStyle(.plain)
        .font(.system(size: NSFont.smallSystemFontSize))
        .onSubmit {
            commitRename(hosts)
        }
        .onExitCommand {
            cancelRename()
        }
    }

    private func beginRename(_ hosts: Hosts) {
        editingName = hosts.name() ?? ""
        isEditing = true
    }

    private func commitRename(_ hosts: Hosts) {
        defer {
            isEditing = false
            store.renamingHosts = nil
        }

        let trimmed = editingName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if trimmed.contains("/") {
            renameError = "File name cannot contain forward slash."
            return
        }

        guard let controller = HostsMainController.defaultInstance() else { return }
        let renamed = controller.rename(hosts, to: trimmed)
        if renamed {
            NotificationCenter.default.post(name: .hostsFileRenamed, object: hosts)
        } else {
            renameError = "A file with that name already exists."
        }
    }

    private func cancelRename() {
        isEditing = false
        store.renamingHosts = nil
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuItems(for hosts: Hosts) -> some View {
        if !hosts.saved() {
            Button("Save") {
                HostsMainController.defaultInstance()?.save(hosts)
            }
        }

        if !hosts.active() {
            Button("Activate") {
                HostsMainController.defaultInstance()?.activateHostsFile(hosts)
            }
            .disabled(!hosts.exists)
        }

        Button("Show In Finder") {
            if let path = hosts.path {
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
            }
        }
        .disabled(!hosts.exists)

        if let remote = hosts as? RemoteHosts {
            Button("Open in Browser") {
                if let url = remote.url {
                    NSWorkspace.shared.open(url)
                }
            }
        }

        Divider()

        if hosts is RemoteHosts {
            Button("Move to Local") {
                HostsMainController.defaultInstance()?.move(hosts, toControllerClass: LocalHostsController.self)
            }
            .disabled(!hosts.exists)
        }

        Button("Rename") {
            store.renamingHosts = hosts
        }

        Divider()

        if store.canRemoveFiles {
            Button("Remove") {
                hostsToRemove = hosts
            }
        }
    }
}

// MARK: - Drop Support

extension SidebarView {

    struct SidebarDropDelegate: DropDelegate {
        let group: HostsGroup

        func validateDrop(info: DropInfo) -> Bool {
            info.hasItemsConforming(to: [.fileURL, .url])
        }

        func performDrop(info: DropInfo) -> Bool {
            guard let controller = HostsMainController.defaultInstance() else { return false }

            let providers = info.itemProviders(for: [.fileURL, .url])
            var handled = false
            for provider in providers {
                if provider.canLoadObject(ofClass: URL.self) {
                    handled = true
                    _ = provider.loadObject(ofClass: URL.self) { url, error in
                        if let error {
                            NSLog("Drop URL load failed: %@", error.localizedDescription)
                            return
                        }
                        guard let url else { return }
                        DispatchQueue.main.async {
                            if url.isFileURL {
                                _ = controller.createHosts(fromLocalURL: url, to: group)
                            } else {
                                _ = controller.createHosts(from: url, to: group)
                            }
                        }
                    }
                }
            }
            return handled
        }
    }
}
