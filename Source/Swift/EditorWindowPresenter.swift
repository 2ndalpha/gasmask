import Cocoa
import SwiftUI

@objc final class EditorWindowPresenter: NSObject, NSWindowDelegate {

    private static var instance: EditorWindowPresenter?

    private let window: NSWindow

    private init(window: NSWindow) {
        self.window = window
        super.init()
        window.delegate = self
    }

    @objc static func createEditorWindow() -> NSWindow {
        let editorView = EditorView()
        let hostingController = NSHostingController(rootView: editorView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Gas Mask"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 619, height: 479))
        window.minSize = NSSize(width: 400, height: 400)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("editor_window")

        let presenter = EditorWindowPresenter(window: window)
        instance = presenter

        return window
    }

    // MARK: - NSWindowDelegate

    func windowDidBecomeMain(_ notification: Notification) {
        Preferences.setShowEditorWindow(true)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        Preferences.setShowEditorWindow(false)
        return true
    }
}
