import AppKit
import SwiftUI

@objc final class PreferencesPresenter: NSObject {
    private static var window: NSWindow?

    @objc static func showPreferences() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let tabVC = NSTabViewController()
        tabVC.tabStyle = .toolbar

        let contentSize = NSSize(width: 550, height: 150)

        func makeTab<V: View>(label: String, symbolName: String, rootView: V) -> NSTabViewItem {
            let hc = NSHostingController(rootView: rootView)
            hc.preferredContentSize = contentSize
            let item = NSTabViewItem(viewController: hc)
            item.label = label
            item.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: label)
            return item
        }

        tabVC.addTabViewItem(makeTab(label: "General", symbolName: "gearshape", rootView: GeneralTab()))
        tabVC.addTabViewItem(makeTab(label: "Editor", symbolName: "square.and.pencil", rootView: EditorTab()))
        tabVC.addTabViewItem(makeTab(label: "Remote", symbolName: "globe", rootView: RemoteTab()))
        tabVC.addTabViewItem(makeTab(label: "Hotkeys", symbolName: "command.square.fill", rootView: HotkeysTab()))
        tabVC.addTabViewItem(makeTab(label: "Update", symbolName: "arrow.triangle.2.circlepath", rootView: UpdateTab()))

        let w = NSWindow(contentViewController: tabVC)
        w.styleMask = [.titled, .closable]
        w.toolbarStyle = .preference
        w.title = tabVC.tabViewItems.first?.label ?? "Preferences"
        w.setFrameAutosaveName("PreferencesWindow")

        // Keep the window alive after close so it can be reopened
        w.isReleasedWhenClosed = false

        window = w
        w.center()
        w.makeKeyAndOrderFront(nil)
    }
}
