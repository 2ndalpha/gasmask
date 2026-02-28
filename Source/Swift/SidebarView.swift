import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @ObservedObject var store: HostsDataStore

    @State private var editingName: String = ""
    @State private var isEditing = false
    @State private var renameError: String?

    var body: some View {
        List(selection: $store.selectedHosts) {
            ForEach(store.hostsGroups, id: \.self) { group in
                let children = (group.children as? [Hosts]) ?? []
                if !children.isEmpty {
                    Section(header: HostsRowView(hosts: group, isGroup: true)) {
                        ForEach(children, id: \.self) { hosts in
                            rowContent(for: hosts)
                                .tag(hosts)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .onDrop(of: [.fileURL, .url, .utf8PlainText], delegate: SidebarDropDelegate(store: store))
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
    }

    // MARK: - Row Content

    @ViewBuilder
    private func rowContent(for hosts: Hosts) -> some View {
        if isEditing, store.renamingHosts === hosts {
            renameField(for: hosts)
        } else {
            HostsRowView(hosts: hosts, isGroup: false)
                .draggable(hosts.contents() ?? "") {
                    Text(hosts.name() ?? "")
                }
                .contextMenu { contextMenuItems(for: hosts) }
        }
    }

    // MARK: - Inline Rename

    private func renameField(for hosts: Hosts) -> some View {
        TextField("Name", text: $editingName, onCommit: {
            commitRename(hosts)
        })
        .textFieldStyle(.plain)
        .font(.system(size: NSFont.smallSystemFontSize))
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
                HostsMainController.defaultInstance()?.removeHostsFile(hosts, moveToTrash: false)
            }
        }
    }
}

// MARK: - Drop Support

extension SidebarView {

    struct SidebarDropDelegate: DropDelegate {
        let store: HostsDataStore

        func validateDrop(info: DropInfo) -> Bool {
            info.hasItemsConforming(to: [.fileURL, .url, .utf8PlainText])
        }

        func performDrop(info: DropInfo) -> Bool {
            guard let controller = HostsMainController.defaultInstance() else { return false }

            let providers = info.itemProviders(for: [.fileURL, .url, .utf8PlainText])
            for provider in providers {
                if provider.canLoadObject(ofClass: URL.self) {
                    provider.loadObject(ofClass: URL.self) { url, error in
                        if let error {
                            NSLog("Drop URL load failed: %@", error.localizedDescription)
                            return
                        }
                        guard let url else { return }
                        DispatchQueue.main.async {
                            if url.isFileURL {
                                _ = controller.createHosts(fromLocalURL: url, to: defaultGroup())
                            } else {
                                _ = controller.createHosts(from: url, to: defaultGroup())
                            }
                        }
                    }
                    return true
                }
            }
            return false
        }

        private func defaultGroup() -> HostsGroup? {
            store.hostsGroups.first
        }
    }
}
