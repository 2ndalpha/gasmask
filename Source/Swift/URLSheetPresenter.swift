import AppKit
import SwiftUI

@objc final class URLSheetPresenter: NSObject {
    private static var activePanel: NSPanel?

    @objc static func presentInWindow(_ externalWindow: NSWindow?) {
        guard activePanel == nil else {
            NSLog("[URLSheetPresenter] Sheet already presented — ignoring")
            return
        }
        guard let parent = externalWindow ?? NSApp.keyWindow ?? NSApp.mainWindow else {
            NSLog("[URLSheetPresenter] No parent window — cannot present sheet")
            return
        }

        // Closures reference activePanel at runtime (not via [weak panel] capture,
        // which would capture nil because the local var is nil when the view is built).
        let view = URLSheetView(
            onAdd: { url in
                guard let panel = URLSheetPresenter.activePanel else { return }
                parent.endSheet(panel)
                URLSheetPresenter.activePanel = nil

                if HostsMainController.defaultInstance().hostsFile(withURLExists: url) {
                    let alert = NSAlert()
                    alert.messageText = "Unable to Add"
                    alert.informativeText = "Hosts file with specified URL already exists."
                    alert.runModal()
                } else {
                    HostsMainController.defaultInstance().createHosts(
                        from: url,
                        forControllerClass: RemoteHostsController.self
                    )
                }
            },
            onCancel: {
                guard let panel = URLSheetPresenter.activePanel else { return }
                parent.endSheet(panel)
                URLSheetPresenter.activePanel = nil
            }
        )

        let hostingController = NSHostingController(rootView: view)
        let p = NSPanel(contentViewController: hostingController)
        p.styleMask = NSWindow.StyleMask([.titled, .fullSizeContentView])

        // Set activePanel before beginSheet so the closures can resolve it.
        URLSheetPresenter.activePanel = p

        parent.beginSheet(p) { _ in
            URLSheetPresenter.activePanel = nil
        }
    }
}
