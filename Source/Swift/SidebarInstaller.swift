import SwiftUI

@objc final class SidebarInstaller: NSObject {
    @objc static func install(in splitView: NSSplitView) {
        let store = HostsDataStore.shared
        let sidebar = SidebarView(store: store)
        let hostingView = NSHostingView(rootView: sidebar)

        guard !splitView.subviews.isEmpty else { return }
        let leftPane = splitView.subviews[0]
        hostingView.frame = leftPane.frame
        hostingView.autoresizingMask = [.width, .height]
        splitView.replaceSubview(leftPane, with: hostingView)

        // Deactivate the old ListController to prevent duplicate notification handling
        ListController.defaultInstance()?.deactivate()
    }
}
