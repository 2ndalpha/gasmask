import AppKit
import MASShortcut
import SwiftUI

/// Wraps `MASShortcutView` for use in SwiftUI.
///
/// Each instance reads/writes a single UserDefaults key (e.g. `"activatePreviousHotkey"`)
/// in the same plist dict format that `MASShortcutBinder` uses for global hotkey registration.
struct ShortcutRecorderView: NSViewRepresentable {
    let prefsKey: String

    func makeNSView(context: Context) -> MASShortcutView {
        let view = MASShortcutView()
        view.setAssociatedUserDefaultsKey(prefsKey, withTransformerName: MASDictionaryTransformerName)
        view.style = .texturedRect
        return view
    }

    func updateNSView(_ nsView: MASShortcutView, context: Context) {}
}
