import SwiftUI

struct StatusBarView: View {
    @ObservedObject var store: HostsDataStore

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                if store.selectedHosts?.editable == false {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .help("Hosts file can not be modified")
                        .accessibilityLabel("Read-only")
                }

                Spacer()

                Text(filesCountText)
                    .font(.system(size: NSFont.smallSystemFontSize))
                    .foregroundStyle(.secondary)

                Spacer()

                if store.isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Busy")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
        }
    }

    private var filesCountText: String {
        switch store.filesCount {
        case 0: return "No files"
        case 1: return "One file"
        default: return "\(store.filesCount) files"
        }
    }
}
