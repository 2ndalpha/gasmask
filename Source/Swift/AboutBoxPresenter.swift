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
        let w = NSWindow(contentViewController: hc)
        w.styleMask = [.titled, .closable]
        w.title = ""
        // Keep the window alive after close so it can be reopened
        w.isReleasedWhenClosed = false

        window = w
        w.center()
        w.makeKeyAndOrderFront(nil)
    }
}
