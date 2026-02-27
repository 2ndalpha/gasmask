# Research: Making Gas Mask Build with Current Xcode

*Researched on: 2026-02-27*

## Overview

Gas Mask is a pure Objective-C macOS app targeting 10.12+. The project compiles and links successfully with Xcode 26.2 (Swift 6.2.3) when code signing is disabled, which the existing build scripts already do. However, the built app **crashes at launch** due to a missing RPATH for Sparkle.framework. Additionally, two bundled third-party frameworks (ShortcutRecorder, CrashReportSender) are x86_64-only or PPC-era and will not function on arm64. Deployment target 10.12 triggers a warning (minimum is now 10.13).

## Key Files

| File | Role |
|------|------|
| `Gas Mask.xcodeproj/project.pbxproj` | Main project config — code signing, deployment targets, framework references |
| `build.sh` | Universal build (arm64 + x86_64), already disables code signing |
| `build-arm.sh` | arm64-only build, already disables code signing |
| `Frameworks/ShortcutRecorder.framework` | Bundled framework for hotkey UI — **x86_64/i386 only, no arm64** |
| `Frameworks/CrashReportSender.framework` | Bundled crash reporter — **PPC-era (ppc_7400/i386 only), completely non-functional** |
| `Source/GlobalHotkeys.m` | Uses deprecated Carbon hotkey APIs (`EventHotKeyRef`, `InstallApplicationEventHandler`) |
| `Source/LoginItem.m` | Uses deprecated `LSSharedFileList` APIs (deprecated since macOS 10.11) |
| `Source/PreferenceController.m` | Imports and uses `ShortcutRecorder/SRRecorderControl.h` |
| `Source/3rd Party/RegexKitLite.m` | Uses deprecated `OSSpinLock` APIs |
| `Source/3rd Party/MAAttachedWindow.m` | Uses deprecated `NSDisableScreenUpdates`, `convertBaseToScreen:` |
| `Gas_Mask_Prefix.pch` | Precompiled header — function declarations without prototypes (warnings) |
| `Gas Mask.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | Sparkle 1.27.1 via SPM |

## Architecture & Data Flow

### Build Process

1. `xcodebuild` with `CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO` (already in build scripts)
2. Compiler: clang, pure Objective-C, ARC enabled
3. SPM resolves Sparkle 1.27.1 (universal binary, arm64 + x86_64) ✅
4. Build **succeeds** — binary is arm64 (when `-arch arm64` is used)
5. Frameworks are copied into `Gas Mask.app/Contents/Frameworks/`

### Runtime Crash (Current State)

```
dyld: Library not loaded: @rpath/Sparkle.framework/Versions/A/Sparkle
Reason: no LC_RPATH's found
```

The binary links against `@rpath/Sparkle.framework/Versions/A/Sparkle` but has **no LC_RPATH entries** in the binary, so dyld cannot find Sparkle at runtime. The app crashes immediately at launch.

### Architecture Issues

| Framework | Architectures | Status |
|-----------|--------------|--------|
| `Sparkle.framework` (SPM) | x86_64 + arm64 | ✅ OK |
| `ShortcutRecorder.framework` (bundled) | x86_64 + i386 only | ❌ No arm64 |
| `CrashReportSender.framework` (bundled) | ppc_7400 + i386 only | ❌ PowerPC era, unusable |

ShortcutRecorder is **not dynamically linked** (not in `otool -L` output) — only linked at compile time via headers. At runtime, the framework is present in the bundle but dyld may fail to load it on arm64.

## Patterns & Conventions

- 100% Objective-C (no Swift)
- ~66 source files + 66 header files
- ARC enabled project-wide
- XIB-based UI (AboutBox.xib, Editor.xib, Preferences.xib, URLSheet.xib)
- Notifications for inter-component communication
- Precompiled header (`Gas_Mask_Prefix.pch`) for common imports

## Dependencies

### Internal Build Configuration
- **Team ID**: D5473R5948 — `CODE_SIGN_IDENTITY = "Mac Developer"` is hardcoded; certificate not on this machine
- **Deployment target**: 10.12 (warning: min supported is 10.13 in Xcode 26.2)
- **Xcode objectVersion**: 52 (old project format)

### Frameworks
- **Sparkle 1.27.1** (SPM, from github.com/sparkle-project/Sparkle@1.27.1) — universal binary, builds fine
- **ShortcutRecorder** (bundled in `Frameworks/`, pre-SPM era) — x86_64/i386 only
- **CrashReportSender** (bundled in `Frameworks/`) — PowerPC/i386 only, circa 2006
- **Carbon.framework** (system) — used only in `GlobalHotkeys.m`
- **libicucore.dylib** (system) — used by RegexKitLite

## Constraints & Risks

### Blocking Issues (App Won't Launch)

1. **Missing LC_RPATH for Sparkle**: Binary links to `@rpath/Sparkle.framework/Versions/A/Sparkle` but the binary has no `LC_RPATH` entry. Needs `@executable_path/../Frameworks` added to `LD_RUNPATH_SEARCH_PATHS` in Xcode build settings.

2. **CrashReportSender.framework is PPC-only**: The framework (ppc_7400/i386) cannot be loaded on modern macOS at all. Needs to be removed from the project.

### Non-Blocking Build Issues

3. **Deployment target 10.12**: Xcode 26.2 warns that minimum is 10.13. Should be raised to at least 10.13.

4. **Code signing**: `CODE_SIGN_IDENTITY = "Mac Developer"` with team ID D5473R5948 requires that specific certificate installed locally. Build scripts work around this with `CODE_SIGN_IDENTITY=""`, but Xcode IDE won't build without reconfiguring.

### Runtime Issues (App Will Partially Break)

5. **ShortcutRecorder.framework is x86_64-only**: Opening the Preferences → Hotkeys panel will likely crash on arm64 Macs unless running under Rosetta 2. Needs to be replaced with a modern arm64 build of ShortcutRecorder (or migrated to another library like KeyboardShortcuts).

6. **Carbon hotkey APIs** (`GlobalHotkeys.m`): `EventHotKeyRef`, `InstallApplicationEventHandler`, `GetEventParameter` from Carbon. Carbon.framework IS present on macOS 26.2 (`/System/Library/Frameworks/Carbon.framework`) and the build links to it, but these APIs are deprecated and may have behavioral issues.

7. **LSSharedFileList** (`LoginItem.m`): APIs deprecated since 10.11. On modern macOS, "Launch at Login" functionality will likely silently fail. Should migrate to `SMAppService` (requires macOS 13.0+).

### Warnings (Code Quality)

- `RegexKitLite.m`: `OSSpinLock` → should use `os_unfair_lock`
- `MAAttachedWindow.m`: `NSDisableScreenUpdates`, `convertBaseToScreen:`, `NSBorderlessWindowMask` all deprecated
- `URLWindowController.m`: `alertWithMessageText:defaultButton:...` deprecated since 10.10
- `StructureConverter.m`: same deprecated alert API
- `PrivilegedActions.m`: `AuthorizationExecuteWithPrivileges` deprecated since 10.7
- `Gas_Mask_Prefix.pch` + `main.m`: function declarations without prototype (C89-style)

## Open Questions

1. **Does ShortcutRecorder actually crash on arm64?** The framework is not in `otool -L` output, suggesting the linker handled it differently. Needs runtime testing of the Hotkeys preference pane specifically.

2. **What macOS version to target?** Moving login items to `SMAppService` requires 13.0+. Is there a reason to keep 10.12/10.13 support?

3. **Is RegexKitLite still needed?** It's the only user of `libicucore` and `OSSpinLock`. Could be replaced by `NSRegularExpression`.

4. **Why is CrashReportSender.framework still in the project?** The source code only has a delegate protocol stub in `ApplicationController.m`. It appears to be dead code — safe to remove?

5. **Sparkle 1.27.1 vs Sparkle 2.x**: Sparkle 2 has breaking API changes. Is upgrading desired?
