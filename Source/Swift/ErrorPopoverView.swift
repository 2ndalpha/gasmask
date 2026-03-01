import SwiftUI

struct ErrorPopoverView: View {
    let title: String
    var description: String?
    var url: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: NSFont.smallSystemFontSize, weight: .semibold))

            if let description, !description.isEmpty {
                Text(description)
                    .font(.system(size: NSFont.smallSystemFontSize))
                    .foregroundStyle(.secondary)
            }

            if let url {
                Button("Open in Browser") {
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.link)
                .font(.system(size: NSFont.smallSystemFontSize))
            }
        }
        .padding()
        .frame(maxWidth: 240)
    }
}
