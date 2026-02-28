import XCTest
import MASShortcut
@testable import Gas_Mask

/// Tests for MASShortcutView configuration matching what ShortcutRecorderView sets up.
///
/// NSViewRepresentable.Context cannot be constructed in unit tests, so we verify
/// the MASShortcutView configuration directly — this is the same code path that
/// ShortcutRecorderView.makeNSView executes.
final class ShortcutRecorderViewTests: XCTestCase {

    func testPrefsKeyConstants_matchExpectedValues() {
        XCTAssertEqual(ActivatePreviousFilePrefKey, "activatePreviousHotkey")
        XCTAssertEqual(ActivateNextFilePrefKey, "activateNextHotkey")
        XCTAssertEqual(UpdateAndSynchronizePrefKey, "updateAndSynchronizeHotkey")
    }

    func testView_configuredWithKeyAndStyle() {
        let key = "testKey"
        let view = MASShortcutView()
        view.setAssociatedUserDefaultsKey(key, withTransformerName: MASDictionaryTransformerName)
        view.style = .texturedRect

        XCTAssertEqual(view.associatedUserDefaultsKey, key)
        XCTAssertEqual(view.style, .texturedRect)
    }

    func testView_nilShortcutByDefault() {
        let view = MASShortcutView()
        XCTAssertNil(view.shortcutValue, "Fresh MASShortcutView should have nil shortcutValue")
    }

    func testView_readsShortcutFromUserDefaults() {
        let key = "testReadKey_\(UUID().uuidString)"

        // Write a shortcut to UserDefaults in dictionary format.
        let shortcut = MASShortcut(keyCode: Int(kVK_F1),
                                   modifierFlags: [.command, .shift])
        let transformer = ValueTransformer(forName: .init(rawValue: MASDictionaryTransformerName))
        let encoded = transformer?.reverseTransformedValue(shortcut)
        UserDefaults.standard.set(encoded, forKey: key)

        let view = MASShortcutView()
        view.setAssociatedUserDefaultsKey(key, withTransformerName: MASDictionaryTransformerName)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(view.shortcutValue, "View should read shortcut from UserDefaults")
        XCTAssertEqual(view.shortcutValue?.keyCode, Int(kVK_F1))

        UserDefaults.standard.removeObject(forKey: key)
    }

    func testView_clearingWritesEmptyDictionary() {
        let key = "testClearKey_\(UUID().uuidString)"

        // Write a shortcut first.
        let shortcut = MASShortcut(keyCode: Int(kVK_F2),
                                   modifierFlags: [.command])
        let transformer = ValueTransformer(forName: .init(rawValue: MASDictionaryTransformerName))
        let encoded = transformer?.reverseTransformedValue(shortcut)
        UserDefaults.standard.set(encoded, forKey: key)

        let view = MASShortcutView()
        view.setAssociatedUserDefaultsKey(key, withTransformerName: MASDictionaryTransformerName)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(view.shortcutValue, "Precondition: shortcut should be set")

        // Clear the shortcut.
        view.shortcutValue = nil
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        // MASShortcutView writes an empty dictionary when cleared (via MASDictionaryTransformer).
        // MASShortcutBinder treats this as "no shortcut" and unregisters the hotkey.
        let stored = UserDefaults.standard.dictionary(forKey: key)
        XCTAssertNotNil(stored, "Key should still exist after clearing")
        XCTAssertTrue(stored?.isEmpty ?? false,
                      "Cleared shortcut should be stored as empty dictionary")

        UserDefaults.standard.removeObject(forKey: key)
    }
}
