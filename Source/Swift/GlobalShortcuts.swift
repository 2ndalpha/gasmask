import Foundation
import MASShortcut

/// Registers global keyboard shortcuts using `MASShortcutBinder`.
///
/// Replaces the old `GlobalHotkeys` ObjC class that used the Carbon Event Manager directly.
/// Call `GlobalShortcuts.shared` once at app launch to register all hotkeys.
@objc final class GlobalShortcuts: NSObject {
    @objc static let shared = GlobalShortcuts()

    private override init() {
        super.init()
        guard let binder = MASShortcutBinder.shared() else { return }
        binder.bindingOptions = [
            NSBindingOption.valueTransformerName.rawValue: MASDictionaryTransformerName
        ]

        let nc = NotificationCenter.default
        // Notification names from Gas_Mask_Prefix.pch lines 42–44 (not importable in Swift)
        binder.bindShortcut(withDefaultsKey: ActivatePreviousFilePrefKey) {
            nc.post(name: .init("activatePreviousFileNotification"), object: nil)
        }
        binder.bindShortcut(withDefaultsKey: ActivateNextFilePrefKey) {
            nc.post(name: .init("activateNextFileNotification"), object: nil)
        }
        binder.bindShortcut(withDefaultsKey: UpdateAndSynchronizePrefKey) {
            nc.post(name: .init("updateAndSynchronizeNotification"), object: nil)
        }
    }
}
