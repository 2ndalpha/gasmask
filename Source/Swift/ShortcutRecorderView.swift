import AppKit
import ShortcutRecorder
import SwiftUI

/// Wraps `RecorderControl` (ShortcutRecorder) for use in SwiftUI.
///
/// Each instance reads/writes a single UserDefaults key (e.g. `"activatePreviousHotkey"`)
/// in the same plist dict format that `GlobalHotkeys` observes via KVO.
struct ShortcutRecorderView: NSViewRepresentable {
    /// The UserDefaults key storing the hotkey dict (matches ObjC #define constants).
    let prefsKey: String

    func makeCoordinator() -> Coordinator {
        Coordinator(prefsKey: prefsKey)
    }

    func makeNSView(context: Context) -> RecorderControl {
        let control = RecorderControl()
        control.delegate = context.coordinator

        // Load existing shortcut from UserDefaults
        if let plist = UserDefaults.standard.object(forKey: prefsKey),
           let hotkey = Hotkey(plistRepresentation: plist),
           hotkey.keyCode > 0 {
            if let keyCode = KeyCode(rawValue: UInt16(hotkey.keyCode)) {
                control.objectValue = Shortcut(
                    code: keyCode,
                    modifierFlags: Self.carbonToCocoaFlags(UInt32(hotkey.modifiers)),
                    characters: nil,
                    charactersIgnoringModifiers: nil
                )
            }
        }

        return control
    }

    func updateNSView(_ nsView: RecorderControl, context: Context) {
        // No-op: prefsKey is immutable per instance, and state changes are driven
        // by user interaction within RecorderControl + its delegate.
    }

    /// Convert Carbon modifier flags to Cocoa NSEvent.ModifierFlags.
    private static func carbonToCocoaFlags(_ carbonFlags: UInt32) -> NSEvent.ModifierFlags {
        var flags = NSEvent.ModifierFlags()
        if carbonFlags & UInt32(cmdKey) != 0 { flags.insert(.command) }
        if carbonFlags & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbonFlags & UInt32(controlKey) != 0 { flags.insert(.control) }
        if carbonFlags & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        return flags
    }

    final class Coordinator: NSObject, RecorderControlDelegate {
        let prefsKey: String

        init(prefsKey: String) {
            self.prefsKey = prefsKey
        }

        func recorderControlDidEndRecording(_ recorder: RecorderControl) {
            let hotkey: Hotkey
            if let shortcut = recorder.objectValue {
                hotkey = Hotkey(
                    keyCode: Int32(shortcut.carbonKeyCode),
                    modifiers: Int32(shortcut.carbonModifierFlags)
                )
            } else {
                hotkey = Hotkey(keyCode: -1, modifiers: -1)
            }
            UserDefaults.standard.set(hotkey.plistRepresentation(), forKey: prefsKey)
        }
    }
}
