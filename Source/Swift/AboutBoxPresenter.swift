import AppKit
import SwiftUI

@objc final class AboutBoxPresenter: NSObject {
    private static var window: NSWindow?

    @objc static func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let hc = NSHostingController(rootView: AboutBoxView())
        hc.preferredContentSize = NSSize(width: 335, height: 220)

        let w = NSWindow(contentViewController: hc)
        w.styleMask = [.titled, .closable]
        w.title = ""
        w.isReleasedWhenClosed = false

        window = w
        w.center()
        w.makeKeyAndOrderFront(nil)
    }
}
