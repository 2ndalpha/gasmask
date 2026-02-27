import AppKit
import SwiftUI

@objc final class URLSheetPresenter: NSObject {
    private static var activePanel: NSPanel?

    @objc static func presentInWindow(_ externalWindow: NSWindow?) {
        guard let parent = externalWindow ?? NSApp.keyWindow ?? NSApp.mainWindow else {
            NSLog("[URLSheetPresenter] No parent window — cannot present sheet")
            return
        }

        // panel is set after creation; closures capture it weakly to avoid a retain cycle
        var panel: NSPanel?

        let view = URLSheetView(
            onAdd: { [weak panel] url in
                guard let panel else { return }
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
            onCancel: { [weak panel] in
                guard let panel else { return }
                parent.endSheet(panel)
                URLSheetPresenter.activePanel = nil
            }
        )

        let hostingController = NSHostingController(rootView: view)
        let p = NSPanel(contentViewController: hostingController)
        p.styleMask = NSWindow.StyleMask([.titled, .fullSizeContentView])

        panel = p
        URLSheetPresenter.activePanel = p

        parent.beginSheet(p) { _ in
            URLSheetPresenter.activePanel = nil
        }
    }
}
