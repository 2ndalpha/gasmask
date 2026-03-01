import SwiftUI

struct HostsRowView: View {
    let hosts: Hosts
    let isGroup: Bool
    // Unused in body; exists to invalidate SwiftUI's byte-comparison cache when Hosts properties change.
    let refreshToken: UInt64

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
                Image(systemName: "wifi.slash")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .help("Offline")
            }
            if group.synchronizing() {
                ProgressView()
                    .controlSize(.small)
                    .help("Synchronizing")
            }
        }
        if let error = hosts.error() {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.yellow)
                .help(error.description ?? "Error")
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
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.yellow)
                .help(error.description ?? "Error")
        }
        if !hosts.saved() {
            Circle()
                .fill(.blue)
                .frame(width: 6, height: 6)
                .accessibilityLabel("Unsaved")
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        Self.accessibilityDescription(for: hosts)
    }

    static func accessibilityDescription(for hosts: Hosts) -> String {
        var parts: [String] = []
        parts.append(hosts.name() ?? "")
        if hosts.active() { parts.append("active") }
        if !hosts.saved() { parts.append("unsaved") }
        if hosts.error() != nil { parts.append("has error") }
        if !hosts.enabled() { parts.append("disabled") }
        return parts.joined(separator: ", ")
    }
}
