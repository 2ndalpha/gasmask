import SwiftUI

struct HostsTextViewRepresentable: NSViewRepresentable {
    let selectedHosts: Hosts?
    let contentToken: UInt64
    let onTextChange: (String) -> Void
    @AppStorage("syntaxHighlighting") private var syntaxHighlighting = true

    func makeNSView(context: Context) -> NSScrollView {
        guard let textView = HostsTextView.createForProgrammaticUse() else {
            return NSScrollView()
        }
        textView.delegate = context.coordinator
        textView.setSyntaxHighlighting(syntaxHighlighting)

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = false

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        let contents = selectedHosts?.contents() ?? ""

        if selectedHosts !== context.coordinator.lastUpdatedHosts {
            // Selection changed — always replace (O(1) check + O(n) replacement)
            context.coordinator.isUpdatingFromModel = true
            defer { context.coordinator.isUpdatingFromModel = false }
            textView.replaceContent(with: contents)
            context.coordinator.lastUpdatedHosts = selectedHosts
            context.coordinator.lastContentToken = contentToken
        } else if contentToken != context.coordinator.lastContentToken {
            // Token changed — external content update (download, save, sync) or user edit.
            // User edits also trigger this path (textDidChange → setContents → setSaved:NO
            // → HostsNodeNeedsUpdate → rowRefreshToken++), but the text view already contains
            // the correct content, so the comparison below will find equality and skip.
            // For editable files (local/combined, typically small), this O(n) check is cheap.
            context.coordinator.lastContentToken = contentToken
            let currentLength = (textView.string as NSString).length
            let newLength = (contents as NSString).length
            if currentLength != newLength || textView.string != contents {
                context.coordinator.isUpdatingFromModel = true
                defer { context.coordinator.isUpdatingFromModel = false }
                textView.replaceContent(with: contents)
            }
        }
        // If neither selection nor token changed, skip entirely — O(1)

        let isEditable = selectedHosts?.editable ?? false
        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
        }

        if textView.syntaxHighlighting() != syntaxHighlighting {
            textView.setSyntaxHighlighting(syntaxHighlighting)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextChange: onTextChange)
    }

    // MARK: - Coordinator

    @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
        let onTextChange: (String) -> Void
        weak var textView: HostsTextView?
        // Weak to avoid retaining a deleted Hosts object; nilling forces a content refresh
        weak var lastUpdatedHosts: Hosts?
        var lastContentToken: UInt64 = 0
        var isUpdatingFromModel = false

        init(onTextChange: @escaping (String) -> Void) {
            self.onTextChange = onTextChange
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromModel,
                  let textView = notification.object as? HostsTextView else { return }
            onTextChange(textView.string)
        }
    }
}
