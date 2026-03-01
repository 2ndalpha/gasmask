import SwiftUI

struct EditorToolbar: ToolbarContent {
    @ObservedObject var store: HostsDataStore

    @State private var hostsToRemove: Hosts?

    var body: some ToolbarContent {
        ToolbarItem(id: "create", placement: .automatic) {
            Menu {
                Button("Local") {
                    HostsMainController.defaultInstance()?.createNewHostsFile(nil)
                }
                Button("Remote") {
                    URLSheetPresenter.presentInWindow(nil)
                }
                Button("Combined") {
                    HostsMainController.defaultInstance()?.createCombinedHostsFile(nil)
                }
            } label: {
                Label("Create", systemImage: "plus")
            }
        }

        ToolbarItem(id: "remove", placement: .automatic) {
            Button {
                hostsToRemove = store.selectedHosts
            } label: {
                Label("Remove", systemImage: "minus")
            }
            .disabled(!store.canRemoveFiles || store.selectedHosts == nil)
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

        ToolbarItem(id: "save", placement: .automatic) {
            Button {
                if let hosts = store.selectedHosts {
                    HostsMainController.defaultInstance()?.save(hosts)
                }
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(store.selectedHosts == nil || store.selectedHosts?.saved() != false)
        }

        ToolbarItem(id: "activate", placement: .automatic) {
            Button {
                if let hosts = store.selectedHosts {
                    HostsMainController.defaultInstance()?.activateHostsFile(hosts)
                }
            } label: {
                Label("Activate", systemImage: "power")
            }
            .disabled(
                store.selectedHosts == nil
                || store.selectedHosts?.active() == true
                || store.selectedHosts?.exists != true
            )
        }
    }
}
