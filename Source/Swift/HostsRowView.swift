import SwiftUI

struct HostsRowView: View {
    let hosts: Hosts
    let isGroup: Bool

    @State private var showingErrorPopover = false
    @State private var showingOfflinePopover = false

    var body: some View {
        if isGroup {
            groupRow
        } else {
            fileRow
        }
    }

    // MARK: - Group Row

    private var groupRow: some View {
        HStack(spacing: 4) {
            Text(hosts.name() ?? "")
                .font(.system(size: NSFont.smallSystemFontSize, weight: .semibold))
            Spacer()
            groupBadges
        }
    }

    @ViewBuilder
    private var groupBadges: some View {
        if let group = hosts as? HostsGroup {
            if !group.online() {
                Button {
                    showingOfflinePopover = true
                } label: {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Offline")
                .accessibilityLabel("Show offline details")
                .popover(isPresented: $showingOfflinePopover) {
                    ErrorPopoverView(
                        title: "No Internet Connection",
                        description: "Can't update hosts files because you are not connected to the Internet."
                    )
                }
            }
            if group.synchronizing() {
                ProgressView()
                    .controlSize(.small)
                    .help("Synchronizing")
            }
        }
        if let error = hosts.error() {
            errorBadgeButton(for: error)
        }
    }

    // MARK: - File Row

    private var fileRow: some View {
        HStack(spacing: 4) {
            if hosts.active() {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                    .accessibilityLabel("Active")
            }

            fileIcon
                .frame(width: 16, height: 16)

            Text(hosts.name() ?? "")
                .font(.system(size: NSFont.smallSystemFontSize))
                .lineLimit(1)
                .opacity(hosts.enabled() ? 1.0 : 0.5)

            Spacer()

            trailingBadges
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    @ViewBuilder
    private var fileIcon: some View {
        if hosts is CombinedHosts {
            Image(systemName: "doc.on.doc")
                .foregroundStyle(.secondary)
        } else if hosts is RemoteHosts {
            Image(systemName: "globe")
                .foregroundStyle(hosts.enabled() ? .secondary : .tertiary)
        } else {
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var trailingBadges: some View {
        if let error = hosts.error() {
            errorBadgeButton(for: error)
        }
        if !hosts.saved() {
            Circle()
                .fill(.blue)
                .frame(width: 6, height: 6)
                .accessibilityLabel("Unsaved")
        }
    }

    // MARK: - Error Badge

    // Note: `Error` here is the ObjC Error class from Error.h, not Swift.Error
    private func errorBadgeButton(for error: Error) -> some View {
        Button {
            showingErrorPopover = true
        } label: {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.yellow)
        }
        .buttonStyle(.plain)
        .help(error.description ?? "Error")
        .accessibilityLabel("Show error details")
        .popover(isPresented: $showingErrorPopover) {
            ErrorPopoverView(
                title: errorTitle(for: error.type),
                description: error.description,
                url: error.url
            )
        }
    }

    // MARK: - Helpers

    private func errorTitle(for type: UInt) -> String {
        switch type {
        case UInt(NetworkOffline): return "No Internet Connection"
        case UInt(ServerNotFound): return "Server Not Found"
        case UInt(FileNotFound): return "Hosts File Not Found"
        case UInt(FailedToDownload): return "Download Failed"
        case UInt(BadContentType): return "Bad Content"
        case UInt(InvalidMobileMeAccount): return "Invalid Account"
        default: return "Error"
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts: [String] = []
        parts.append(hosts.name() ?? "")
        if hosts.active() { parts.append("active") }
        if !hosts.saved() { parts.append("unsaved") }
        if hosts.error() != nil { parts.append("has error") }
        if !hosts.enabled() { parts.append("disabled") }
        return parts.joined(separator: ", ")
    }
}
