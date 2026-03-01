import SwiftUI

@objc final class ContentInstaller: NSObject {
    @objc static func install(in splitView: NSSplitView) {
        guard splitView.subviews.count >= 2 else { return }

        let store = HostsDataStore.shared
        let content = ContentView(store: store)
        let hostingView = NSHostingView(rootView: content)

        let rightPane = splitView.subviews[1]
        hostingView.frame = rightPane.frame
        hostingView.autoresizingMask = [.width, .height]
        splitView.replaceSubview(rightPane, with: hostingView)
    }
}
