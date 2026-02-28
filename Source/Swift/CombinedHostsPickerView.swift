import SwiftUI

struct CombinedHostsPickerView: View {
    @ObservedObject var store: HostsDataStore

    var body: some View {
        if let combined = store.selectedHosts as? CombinedHosts {
            pickerContent(for: combined)
        }
    }

    // MARK: - Picker Content

    @ViewBuilder
    private func pickerContent(for combined: CombinedHosts) -> some View {
        let allFiles = allNonCombinedHosts()
        let includedFiles = (combined.hostsFiles() as? [Hosts]) ?? []

        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                if allFiles.isEmpty {
                    Text("No hosts files available to combine.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: NSFont.smallSystemFontSize))
                        .padding(.horizontal, 8)
                } else {
                    ForEach(allFiles, id: \.self) { hosts in
                        Toggle(
                            hosts.name() ?? "",
                            isOn: toggleBinding(for: hosts, in: combined, includedFiles: includedFiles)
                        )
                        .toggleStyle(.checkbox)
                        .font(.system(size: NSFont.smallSystemFontSize))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 1)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 150)
    }

    // MARK: - Toggle Binding

    private func toggleBinding(for hosts: Hosts, in combined: CombinedHosts, includedFiles: [Hosts]) -> Binding<Bool> {
        Binding(
            get: {
                let current = (combined.hostsFiles() as? [Hosts]) ?? []
                return current.contains { $0 === hosts }
            },
            set: { isOn in
                var files = (combined.hostsFiles() as? [Hosts]) ?? []
                if isOn {
                    if !files.contains(where: { $0 === hosts }) {
                        files.append(hosts)
                    }
                } else {
                    files.removeAll { $0 === hosts }
                }
                combined.setHostsFiles(files)
                store.hostsGroups = store.hostsGroups
            }
        )
    }

    // MARK: - Helpers

    private func allNonCombinedHosts() -> [Hosts] {
        var result: [Hosts] = []
        for group in store.hostsGroups {
            let children = (group.children as? [Hosts]) ?? []
            for hosts in children where !(hosts is CombinedHosts) {
                result.append(hosts)
            }
        }
        return result
    }
}
