# Plan: Make Gas Mask Build and Run with Xcode 26.2

## Summary

Gas Mask is a legacy pure Objective-C macOS app that compiles successfully with Xcode 26.2 (Swift 6.2.3) when code signing is disabled, but **crashes at launch** due to a missing RPATH for Sparkle.framework. Two additional bundled frameworks are non-functional on modern macOS: CrashReportSender.framework (PowerPC-era, unloadable) and ShortcutRecorder.framework (x86_64-only, crashes on arm64 when the Hotkeys preference pane is opened). This plan fixes all layers: the launch crash, the Hotkeys pane crash, dead code removal, code signing for Xcode IDE builds, and the broken "Launch at Login" feature.

Research file: `research/xcode-build-compatibility.md`

## Requirements

### Functional
- `./build-arm.sh` and `./build.sh` produce an app that launches successfully on arm64 macOS
- Gas Mask.app opens and is fully usable — including the Hotkeys preference pane
- "Launch at Login" preference works on modern macOS
- Xcode IDE can build the project without requiring a specific developer certificate

### Non-Functional
- Deployment target: minimum macOS 13.0 (required for SMAppService; also clears the Xcode 26.2 deployment target warning)
- No linker errors or architecture mismatch errors in the build output

### Out of Scope
- Replacing Carbon APIs in `GlobalHotkeys.m` (Carbon.framework is present and linked on macOS 26.2)
- Modernizing `RegexKitLite.m` (OSSpinLock warnings, still functional)
- Updating `MAAttachedWindow.m` deprecated APIs
- Upgrading Sparkle from 1.27.1 to 2.x (breaking API change; Sparkle 1.27.1 builds fine as universal binary)
- Automated tests (no test infrastructure exists in the project)

## Technical Approach

The project has five concrete problems to fix, ordered by impact:

1. **Missing LC_RPATH** — the binary links to `@rpath/Sparkle.framework/Versions/A/Sparkle` but has no `LC_RPATH` entry. Adding `LD_RUNPATH_SEARCH_PATHS = "@executable_path/../Frameworks"` to both targets' build settings fixes the launch crash.

2. **CrashReportSender.framework** — dead code (only a `#pragma mark CrashReportSenderDelegate` comment remains). The binary is PowerPC-only. Remove all references from the project file and delete the framework directory.

3. **ShortcutRecorder.framework (x86_64-only)** — the bundled 1.x framework has no arm64 slice. The Hotkeys preference pane uses `SRRecorderControl` (IBOutlet) and `SRRecorderCell` (XIB actionCell). Plan: add **ShortcutRecorder 3.x** as an SPM dependency, update `Preferences.xib` to remove the `SRRecorderCell` references (removed in SR3), update `PreferenceController.m` source, and remove the bundled framework.

4. **Code signing & deployment target** — the two target-level build configs (Gas Mask and Launcher, each with Debug and Release) contain `CODE_SIGN_IDENTITY = "Mac Developer"` and `DEVELOPMENT_TEAM = D5473R5948`. The project-level configs (C01FCF4F Debug, C01FCF50 Release) contain only warnings and do not need code signing changes, but the Release project config has `OTHER_CODE_SIGN_FLAGS = "--deep"` which should also be removed. Deployment target appears only in the 4 target configs.

5. **LoginItem (LSSharedFileList)** — deprecated since 10.11 and silently failing on modern macOS. The current implementation registers `Launcher.app` (a helper that sleeps 1s then reopens the main app) as the login item. The `SMAppService` approach registers the main app directly; the Launcher.app helper is still retained in the bundle (it is used by other re-launch logic, not just login items).

### ShortcutRecorder 3.x Migration Details

ShortcutRecorder 3.x SPM package: `https://github.com/Kentzo/ShortcutRecorder.git` (use `from: "3.4.0"`).

**Critical XIB change**: SR1 used `SRRecorderCell` as the `actionCell` of the `SRRecorderControl`. SR3 removed the cell entirely. The `Preferences.xib` must be edited (XML) to remove the three `<actionCell key="cell" ... customClass="SRRecorderCell"/>` elements (lines 166, 188, 219 of the XIB). The `SRRecorderControl` itself remains and retains the same class name.

**API changes from SR1 to SR3**:

| SR1 | SR3 |
|-----|-----|
| `KeyCombo` struct `{code, flags}` | `SRShortcut` object |
| `SRMakeKeyCombo(code, flags)` | `[SRShortcut shortcutWithCode:modifierFlags:]` |
| `setKeyCombo:` | `setObjectValue:` (or `.shortcut` property) |
| `keyCombo` returning `KeyCombo` | `.shortcut` returning `SRShortcut *` |
| `carbonToCocoaFlags:` | not needed — SR3 stores Cocoa flags natively |
| `cocoaToCarbonFlags:` | use `SRCocoaModifierFlagsToCarbonModifierFlags()` from SR3 headers |
| `shortcutRecorder:keyComboDidChange:` | `shortcutRecorderDidEndRecording:` |

**Critical**: `Hotkey` objects store **Carbon modifier flags** in NSUserDefaults (because `GlobalHotkeys.m` passes them directly to `RegisterEventHotKey()`). When reading a saved shortcut from NSUserDefaults, Carbon flags must be converted to Cocoa flags for SR3. When the user sets a new shortcut via SR3, Cocoa flags must be converted back to Carbon flags before saving to `Hotkey`. SR3 provides `SRCocoaModifierFlagsToCarbonModifierFlags()` and `SRCarbonModifierFlagsToCocoaModifierFlags()` for these conversions.

## Implementation Tasks

### Task 1: Add LD_RUNPATH_SEARCH_PATHS to fix the launch crash
**Files**: `Gas Mask.xcodeproj/project.pbxproj`
**Description**: Add `LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks")` to the build settings for:
- Gas Mask target Debug config (C01FCF4B, lines ~1107–1191)
- Gas Mask target Release config (C01FCF4C, lines ~1194–1218)
- Launcher target Debug config (3579F0D0, lines ~1104–1140) — defensive only, Launcher doesn't link Sparkle
- Launcher target Release config (3579F0D1, lines ~1141–1163) — same

Also remove `"OTHER_CODE_SIGN_FLAGS[sdk=*]" = "--deep"` from the project-level Release config (C01FCF50, line 1283).
**Acceptance criteria**:
- [x] `otool -l "Gas Mask.app/Contents/MacOS/Gas Mask" | grep -A1 LC_RPATH` shows `@executable_path/../Frameworks`
- [x] Running `./build-arm.sh` and then opening the resulting app no longer crashes with "Library not loaded: Sparkle"

### Task 2: Remove CrashReportSender.framework and dead Sparkle file reference
**Files**: `Gas Mask.xcodeproj/project.pbxproj`, `Frameworks/CrashReportSender.framework/` (delete)
**Description**: Remove all references to CrashReportSender.framework from the project file:
- Remove the `PBXBuildFile` entry `354DDD0E114EBC9700DB76D7` (CrashReportSender.framework in CopyFiles)
- Remove `354DDD0E114EBC9700DB76D7` from the CopyFiles build phase list (line 160)
- Remove the `PBXFileReference` `354DDD08114EBC8000DB76D7`
- Remove `354DDD08114EBC8000DB76D7` from the PBXGroup (line 414)
- Delete the `Frameworks/CrashReportSender.framework` directory from disk

Also clean up the dead Sparkle reference while here:
- Remove `PBXFileReference` `3556CEDF10D6B68C00C7301E` (points to non-existent `Frameworks/Sparkle.framework`)
- Remove `3556CEDF10D6B68C00C7301E` from the Frameworks PBXGroup (line 417)

Also delete the old IB plugin from disk:
- Delete `Dependencies/ShortcutRecorder.ibplugin/` directory
**Acceptance criteria**:
- [x] `grep CrashReport "Gas Mask.xcodeproj/project.pbxproj"` returns no results
- [x] `Frameworks/CrashReportSender.framework` directory does not exist
- [x] `Dependencies/ShortcutRecorder.ibplugin` directory does not exist
- [x] Project still builds successfully

### Task 3: Fix code signing and deployment target in project file
**Files**: `Gas Mask.xcodeproj/project.pbxproj`
**Description**: Update the four target-level configurations (Gas Mask Debug, Gas Mask Release, Launcher Debug, Launcher Release):
- Change `CODE_SIGN_IDENTITY = "Mac Developer"` → `CODE_SIGN_IDENTITY = ""`
- Remove `DEVELOPMENT_TEAM = D5473R5948`
- Add `CODE_SIGNING_REQUIRED = NO`
- Add `CODE_SIGNING_ALLOWED = NO`
- Change `MACOSX_DEPLOYMENT_TARGET = 10.12` → `MACOSX_DEPLOYMENT_TARGET = 13.0`

The project-level configurations (C01FCF4F Debug, C01FCF50 Release) do not have CODE_SIGN_IDENTITY or DEPLOYMENT_TARGET and require no changes beyond the `OTHER_CODE_SIGN_FLAGS` removal handled in Task 1.
**Acceptance criteria**:
- [x] `xcodebuild -project "Gas Mask.xcodeproj" -scheme "Gas Mask"` succeeds without "No signing certificate" errors
- [x] No "MACOSX_DEPLOYMENT_TARGET is set to 10.12" warning in build output
- [x] `grep "D5473R5948" "Gas Mask.xcodeproj/project.pbxproj"` returns nothing

### Task 4: Add ShortcutRecorder 3.x via SPM and remove bundled framework
**Files**: `Gas Mask.xcodeproj/project.pbxproj`, `Frameworks/ShortcutRecorder.framework/` (delete)
**Description**:
1. Add ShortcutRecorder 3.x as an SPM dependency in project.pbxproj — add `XCRemoteSwiftPackageReference` and `XCSwiftPackageProductDependency` entries following the same pattern as the existing Sparkle entries (lines 1321–1337). Use:
   - `repositoryURL = "https://github.com/Kentzo/ShortcutRecorder.git"`
   - `requirement = { kind = upToNextMajorVersion; minimumVersion = "3.4.0" }`
2. Add a `PBXBuildFile` for the new ShortcutRecorder SPM product in the Frameworks build phase (following the Sparkle pattern at line 384)
3. Remove the bundled ShortcutRecorder references from project.pbxproj:
   - `PBXBuildFile` `3556CE8410D6B3CF00C7301E` (ShortcutRecorder.framework in Frameworks)
   - `PBXBuildFile` `3556CEA110D6B44A00C7301E` (ShortcutRecorder.framework in CopyFiles)
   - `PBXFileReference` `3556CE8310D6B3CF00C7301E`
   - Group reference `3556CE8310D6B3CF00C7301E`
   - References from both the Frameworks build phase and CopyFiles build phase
4. Delete `Frameworks/ShortcutRecorder.framework/` directory from disk
**Acceptance criteria**:
- [x] `Frameworks/ShortcutRecorder.framework` directory does not exist
- [x] ShortcutRecorder 3.4.0+ resolves successfully in Package.resolved
- [x] Project compiles (source code update is Task 5)

### Task 5a: Update Preferences.xib for ShortcutRecorder 3.x
**Files**: `Preferences.xib`
**Description**: Remove the three `SRRecorderCell` `<actionCell>` elements from the XIB (lines 166, 188, 219). SR3's `SRRecorderControl` is cell-less. Edit the XML directly:
- For each `<control ... customClass="SRRecorderControl">` block, remove the child `<actionCell key="cell" ... customClass="SRRecorderCell"/>` element entirely
- The `SRRecorderControl` element itself and its `id` attribute must be preserved (it's referenced by IBOutlet connections elsewhere in the NIB)

Verify the NIB compiles: `ibtool --compile /dev/null Preferences.xib` should produce no fatal errors.
**Acceptance criteria**:
- [x] `grep SRRecorderCell Preferences.xib` returns nothing
- [x] `ibtool --compile /dev/null Preferences.xib` exits with 0 (verified with temp output path)

### Task 5b: Update PreferenceController.m for ShortcutRecorder 3.x API
**Files**: `Source/PreferenceController.h`, `Source/PreferenceController.m`
**Description**: Update Hotkeys section of PreferenceController to use SR3 API.

In `PreferenceController.m`:

**`initHotkeys` method** — replace SR1 `setKeyCombo:SRMakeKeyCombo(code, flags)` pattern:
```objc
// SR1 (old):
[activatePreviousHotkey setKeyCombo:SRMakeKeyCombo([hotkey keyCode],
    [activatePreviousHotkey carbonToCocoaFlags:[hotkey modifiers]])];
// SR3 (new):
[activatePreviousHotkey setObjectValue:[SRShortcut shortcutWithCode:[hotkey keyCode]
    modifierFlags:SRCarbonModifierFlagsToCocoaModifierFlags([hotkey modifiers])
    characters:nil charactersIgnoringModifiers:nil]];
```
Apply the same pattern to `activateNextHotkey` and `updateHotkey`.

**Delegate method** — replace SR1 `shortcutRecorder:keyComboDidChange:` with SR3 `shortcutRecorderDidEndRecording:`:
```objc
// SR3:
- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder {
    SRShortcut *shortcut = aRecorder.objectValue;
    Hotkey *hotkey = [[Hotkey alloc] initWithKeyCode:shortcut.keyCode
        modifiers:SRCocoaModifierFlagsToCarbonModifierFlags(shortcut.modifierFlags)];
    NSString *prefKey;
    if (aRecorder == activatePreviousHotkey) { prefKey = ActivatePreviousFilePrefKey; }
    else if (aRecorder == activateNextHotkey) { prefKey = ActivateNextFilePrefKey; }
    else { prefKey = UpdateAndSynchronizePrefKey; }
    [[[Preferences instance] defaults] setValue:[hotkey plistRepresentation] forKey:prefKey];
}
```

Update the import from `<ShortcutRecorder/SRRecorderControl.h>` to `@import ShortcutRecorder;` (SR3 module).

In `PreferenceController.h`: Update the forward declaration `@class SRRecorderControl` if needed and remove any `KeyCombo`-specific protocol conformance.

Note: `Hotkey.m` and `GlobalHotkeys.m` do **not** need changes — they continue to store and use Carbon modifier flags as before.
**Acceptance criteria**:
- [x] Project compiles without SR1 API errors (`SRMakeKeyCombo`, `KeyCombo`, `carbonToCocoaFlags` not found)
- [ ] Opening Preferences → Hotkeys panel shows three recorder controls without crashing
- [ ] Setting a hotkey in the Hotkeys pane saves to NSUserDefaults
- [ ] The registered hotkey fires the correct action when pressed

### Task 6: Fix LoginItem — replace LSSharedFileList with SMAppService
**Files**: `Source/LoginItem.h`, `Source/LoginItem.m`
**Description**: Replace the deprecated `LSSharedFileList` implementation with `SMAppService`:
- Add `@import ServiceManagement;` (framework is already linked via system)
- `enabled` getter → `[SMAppService mainAppService].status == SMAppServiceStatusEnabled`
- `setEnabled:YES` → `[[SMAppService mainAppService] registerAndReturnError:&error]`; log or show alert on error
- `setEnabled:NO` → `[[SMAppService mainAppService] unregisterAndReturnError:&error]`; log on error
- Remove the private category and all `LSSharedFileList*` / `CFURLRef` code
- Remove the `url` and `loginItems` private methods — SMAppService registers the caller app, not a path

Note: The Launcher.app helper is NOT affected by this change. Launcher.app remains in the bundle and is still used by the "reopen after login" startup flow (it sleeps 1s and reopens the main app). Only the mechanism for registering a login item changes from `LSSharedFileList` (Launcher.app URL) to `SMAppService.mainAppService` (main app self-registration).
**Acceptance criteria**:
- [x] `grep LSSharedFileList Source/LoginItem.m` returns nothing
- [x] Project builds without LSSharedFileList deprecation warnings in LoginItem.m
- [ ] "Launch at Login" toggle in Preferences → General saves the preference
- [ ] On macOS 13+, enabling "Launch at Login" results in Gas Mask appearing in System Settings → General → Login Items

## Testing Strategy

### Manual Testing (performed after each task)

After Task 1:
1. `./build-arm.sh` → `** BUILD SUCCEEDED **`
2. Open `~/Library/Developer/Xcode/DerivedData/Gas_Mask-.../Build/Products/Debug/Gas Mask.app` → app launches (menu bar icon appears)

After Task 5b:
3. Open Preferences → Hotkeys → no crash, three recorder controls visible
4. Record a hotkey → verify it fires the correct action

After Task 6:
5. Open Preferences → General → toggle "Launch at Login" on → check System Settings → General → Login Items shows Gas Mask

### Build verification command
```bash
./build-arm.sh 2>&1 | tail -5
# Expected: ** BUILD SUCCEEDED **
```

## Risks and Considerations

- **ShortcutRecorder XIB NSUnarchiver**: Even after removing `SRRecorderCell` XML elements, NSUnarchiver may encounter compatibility issues decoding old SR1 control state. If the Hotkeys pane still crashes after Task 5a/5b, the SRRecorderControl instances in `Preferences.xib` should be deleted and recreated manually in Interface Builder with SR3 installed.

- **SR3 in pure ObjC project via SPM**: SR3 is an Objective-C framework distributed via SPM. It should integrate without Swift runtime requirements. If SPM integration fails due to the old project format (`objectVersion = 52`), the alternative is to download a pre-built SR3 `.framework` binary with arm64 support and place it in `Frameworks/`, updating the project file to point to it.

- **SMAppService without App Sandbox**: `SMAppService.mainAppService` works for unsigned/non-sandboxed apps in development. Registration may silently succeed but the system may show a privacy prompt to the user on first use. This is expected behavior on macOS 13+.

- **Stale old LSSharedFileList login item**: Users with the old version installed may have a stale login item for Launcher.app in their login items list. The new `SMAppService` does not remove it. If needed, add migration code in `applicationDidFinishLaunching:` to detect the old Launcher.app login item and display instructions to remove it manually.

- **SR3 modifier flag functions**: `SRCarbonModifierFlagsToCocoaModifierFlags()` and `SRCocoaModifierFlagsToCarbonModifierFlags()` are part of SR3's `SRKeyBindingTransformer.h` or `SRCommon.h`. Verify these are available in the version pulled via SPM; if not, use a simple inline conversion (`cmdKey` ↔ `NSEventModifierFlagCommand` etc.).
