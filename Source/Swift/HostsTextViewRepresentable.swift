import SwiftUI

struct HostsTextViewRepresentable: NSViewRepresentable {
    @ObservedObject var store: HostsDataStore
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

        let contents = store.selectedHosts?.contents() ?? ""
        if textView.string != contents {
            context.coordinator.isUpdatingFromModel = true
            textView.string = contents
            context.coordinator.isUpdatingFromModel = false
        }

        textView.isEditable = store.selectedHosts?.editable ?? false

        if textView.syntaxHighlighting() != syntaxHighlighting {
            textView.setSyntaxHighlighting(syntaxHighlighting)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    // MARK: - Coordinator

    @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
        let store: HostsDataStore
        weak var textView: HostsTextView?
        var isUpdatingFromModel = false

        init(store: HostsDataStore) {
            self.store = store
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromModel,
                  let textView = notification.object as? HostsTextView else { return }
            store.selectedHosts?.setContents(textView.string)
        }
    }
}
