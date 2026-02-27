# Plan: Host List Tests and Fix

## Summary

The host list (left-side `NSOutlineView` sidebar) in Gas Mask is broken due to a **timing bug** where `expandAllItems` and `selectActiveHostsFile` are called in `ListController.awakeFromNib` before `HostsMainController.load` has populated the tree. The list renders with empty/collapsed groups. Secondary issues include nil-crash risk in `Cell.drawWithFrame:` and several deprecated API warnings. This plan adds an XCTest unit test target, writes tests for the model and controller layer to catch regressions, fixes the identified bugs, and integrates the test run into GitHub Actions CI.

Research file: `research/host-list.md`

## Requirements

### Functional
- Host list shows all groups (LOCAL / REMOTE / COMBINED) and their files, expanded, on app launch
- Active hosts file is selected in the list on launch
- No crash when drawing list cells
- `xcodebuild test` passes all tests

### Non-Functional
- Tests run in CI on every push (GitHub Actions `macos-15` runner)
- Test target uses the `BUNDLE_LOADER` pattern (injects into the Gas Mask app binary; no source file duplication)
- Deprecated API warnings eliminated from the host list files

### Out of Scope
- Migrating from cell-based to view-based `NSOutlineView` rendering (deferred)
- `BadgeManager` view lifecycle / scroll-off-screen memory issue (deferred)
- Integration tests for `loadFiles` (requires `FileUtil` dependency injection refactor, deferred)
- Remote and Combined hosts controllers (Local only for file loading tests)
- `namesOfPromisedFilesDroppedAtDestination:forDraggedItems:` — deprecated in macOS 12, has `// TODO` comment in `ListController.m`. Replacing with modern `NSFilePromiseProvider` is a separate task.
- Migrating `ListController.init` to add `removeObserver:` in `dealloc` — `ListController` is a singleton that lives for the entire app lifetime; observer cleanup is not necessary in practice.

## Technical Approach

### Root Cause: Timing Bug

`ListController.awakeFromNib` fires when `Editor.xib` is loaded — before `applicationWillFinishLaunching` calls `HostsMainController.load`. At that point the NSTreeController content is empty, so `expandAllItems` iterates zero rows and `selectActiveHostsFile` logs "No active item to select!". After `load` runs and items are inserted, the outline view refreshes via KVO but stays collapsed.

**Fix**: In `ListController`, register for `AllHostsFilesLoadedFromDiskNotification` (already defined in the prefix header, never posted) and call `expandAllItems` + `selectActiveHostsFile` there. Remove both calls from `awakeFromNib`. In `HostsMainController.load`, post this notification after all files are inserted.

### Test Target: BUNDLE_LOADER

The test bundle uses `BUNDLE_LOADER = $(TEST_HOST)` where `TEST_HOST` is the built Gas Mask app. This makes all app symbols available to tests without recompiling source files into the test target. Only the test `.m` files are compiled in the test target.

In CI, `xcodebuild test` builds the Gas Mask app as a dependency before injecting the test bundle. The app starts headlessly (no `/etc/hosts` write, no privilege prompts) because no hosts file is activated during tests.

### Deprecated API Fixes

| Old | New | File |
|-----|-----|------|
| `NSStringPboardType` | `NSPasteboardTypeString` | `HostsListView.m`, `ListController.m` |
| `NSFilenamesPboardType` | `NSPasteboardTypeFileURL` | `HostsListView.m` |
| `NSCompositeSourceOver` | `NSCompositingOperationSourceOver` | `Cell.m` |
| `NSWarningAlertStyle` | `NSAlertStyleWarning` | `HostsMainController.m` |

## Implementation Tasks

### Task 1: Fix the timing bug in ListController
**Files**: `Source/ListController.m`, `Source/HostsMainController.m`
**Description**:
In `HostsMainController.m`: replace the `ActivateFileNotification` post at the end of `load` with an **additional** `AllHostsFilesLoadedFromDiskNotification` post (keep `ActivateFileNotification` too, as it's handled by other observers):
```objc
// At the very end of -load, add:
[[NSNotificationCenter defaultCenter]
    postNotificationName:AllHostsFilesLoadedFromDiskNotification object:nil];
```
In `ListController.m`:
1. In `-init`, add a new observer:
```objc
[nc addObserver:self selector:@selector(hostsFilesLoaded:)
         name:AllHostsFilesLoadedFromDiskNotification object:nil];
```
2. Add the handler method (in the Private category):
```objc
- (void)hostsFilesLoaded:(NSNotification *)notification {
    [self expandAllItems];
    [self selectActiveHostsFile];
}
```
3. In `-awakeFromNib`, **remove** the two calls:
```objc
// REMOVE these two lines:
// [self expandAllItems];
// [self selectActiveHostsFile];
```
**Acceptance criteria**:
- [x] `awakeFromNib` no longer calls `expandAllItems` or `selectActiveHostsFile`
- [x] `hostsFilesLoaded:` is registered as an observer in `-init`
- [x] `HostsMainController.load` posts `AllHostsFilesLoadedFromDiskNotification` after all files are inserted
- [ ] App launches and shows all groups expanded with their files listed

### Task 2: Add nil guard in Cell.drawWithFrame:
**Files**: `Source/Cell.m`
**Description**:
Add a nil guard at the very start of `drawWithFrame:inView:` to prevent a crash if `item` is nil (e.g., during cell reuse or if `willDisplayCell:` is not called):
```objc
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView {
    if (!item) {
        return;
    }
    // ... existing code
}
```
**Acceptance criteria**:
- [x] `drawWithFrame:inView:` returns early when `item` is nil
- [x] No crash when cells are drawn

### Task 3: Fix deprecated API warnings
**Files**: `Source/HostsListView.m`, `Source/ListController.m`, `Source/Cell.m`, `Source/HostsMainController.m`
**Description**:
Replace all deprecated constants with their modern equivalents:

In `HostsListView.m` (`awakeFromNib`):
```objc
// Old:
[self registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];
// New:
[self registerForDraggedTypes:@[NSPasteboardTypeString, NSPasteboardTypeFileURL]];
```
Note: `NSFilenamesPboardType` was a plist-array of file paths, while `NSPasteboardTypeFileURL` (`public.file-url`) is a single-URL UTI. The reading code in `ListController.urlFromPasteBoard:` already iterates `NSPasteboardItem` objects and reads `kFileURLType = @"public.file-url"` directly, so the reading path is unaffected. However, Finder may use different drag UTIs — verify with a manual drag-from-Finder test after this change (see Testing Strategy).

In `ListController.m` (`writeItems:toPasteboard:`):
```objc
// Old:
[pboard setString:[hosts contents] forType:NSStringPboardType];
// New:
[pboard setString:[hosts contents] forType:NSPasteboardTypeString];
```

In `ApplicationController.m` (reads from pasteboard in URL handling):
```objc
// Old:
NSString *data = [pboard stringForType:NSStringPboardType];
// New:
NSString *data = [pboard stringForType:NSPasteboardTypeString];
```

In `Cell.m` — replace all 3 occurrences of `NSCompositeSourceOver` with `NSCompositingOperationSourceOver`.

In `HostsMainController.m` (`removeSelectedHostsFile:`):
```objc
// Old:
[alert setAlertStyle:NSWarningAlertStyle];
// New:
[alert setAlertStyle:NSAlertStyleWarning];
```

**Acceptance criteria**:
- [x] `grep -r "NSStringPboardType\|NSFilenamesPboardType\|NSCompositeSourceOver\|NSWarningAlertStyle" Source/` returns nothing
- [ ] Project builds without deprecation warnings in the modified files
- [ ] Manual: drag a `.hst` file from Finder onto the host list sidebar — file is accepted (same as before the change)

### Task 4: Add XCTest target to project.pbxproj
**Files**: `Gas Mask.xcodeproj/project.pbxproj`, `Gas Mask.xcodeproj/xcshareddata/xcschemes/Gas Mask.xcscheme`
**Description**:
Use a Python script (`scripts/add-test-target.py`) to add the test target to `project.pbxproj`. The script inserts:

1. **PBXFileReference** entries for each test `.m` file (UUIDs `AA1B2C3D4E5F000100000010`–`…0015`) and the test bundle product (`…0020`)
2. **PBXBuildFile** entries for each test source
3. **PBXGroup** `GasMaskTests` (`AA1B2C3D4E5F000100000031`) under the existing `Tests` group
4. **PBXSourcesBuildPhase** (`AA1B2C3D4E5F000100000005`) listing the test sources
5. **PBXFrameworksBuildPhase** (`AA1B2C3D4E5F000100000006`) — empty (XCTest linked automatically via BUNDLE_LOADER)
6. **PBXResourcesBuildPhase** (`AA1B2C3D4E5F000100000007`) — empty
7. **PBXNativeTarget** `"Gas Mask Tests"` (`AA1B2C3D4E5F000100000001`)
   - `productType = "com.apple.product-type.bundle.unit-test"`
   - Points to build config list `AA1B2C3D4E5F000100000004`
8. **XCBuildConfiguration** Debug (`AA1B2C3D4E5F000100000002`) and Release (`AA1B2C3D4E5F000100000003`) with:
   ```
   BUNDLE_LOADER = "$(TEST_HOST)";
   CODE_SIGN_IDENTITY = "";
   CODE_SIGNING_ALLOWED = NO;
   CODE_SIGNING_REQUIRED = NO;
   FRAMEWORK_SEARCH_PATHS = ("$(inherited)", "$(PLATFORM_DIR)/Developer/Library/Frameworks");
   GCC_PRECOMPILE_PREFIX_HEADER = YES;
   GCC_PREFIX_HEADER = Gas_Mask_Prefix.pch;
   MACOSX_DEPLOYMENT_TARGET = 13.0;
   PRODUCT_BUNDLE_IDENTIFIER = "ee.clockwise.gmask.tests";
   PRODUCT_NAME = "Gas Mask Tests";
   SDKROOT = macosx;
   TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Gas Mask.app/Contents/MacOS/Gas Mask";
   ```
9. **XCConfigurationList** (`AA1B2C3D4E5F000100000004`)
10. Add `AA1B2C3D4E5F000100000001` to the project's `targets` array

Instead of creating a new scheme, **add the test bundle as a `<TestableReference>` inside the existing `Gas Mask.xcscheme`'s empty `<Testables>` block**. This is the conventional approach for `BUNDLE_LOADER` test targets — the app target is already in the BuildAction and serves as the test host. The updated `TestAction` block:
```xml
<Testables>
  <TestableReference
     skipped = "NO">
     <BuildableReference
        BuildableIdentifier = "primary"
        BlueprintIdentifier = "AA1B2C3D4E5F000100000001"
        BuildableName = "Gas Mask Tests.xctest"
        BlueprintName = "Gas Mask Tests"
        ReferencedContainer = "container:Gas Mask.xcodeproj">
     </BuildableReference>
  </TestableReference>
</Testables>
```
The app target is already in the scheme's BuildAction (`buildForTesting = "YES"`), so it will be built before the test bundle. No separate scheme file is needed. CI uses `xcodebuild test -scheme "Gas Mask"`.

Also add the test target to the BuildAction entries:
```xml
<BuildActionEntry
   buildForTesting = "YES"
   buildForRunning = "NO"
   buildForProfiling = "NO"
   buildForArchiving = "NO"
   buildForAnalyzing = "YES">
   <BuildableReference
      BuildableIdentifier = "primary"
      BlueprintIdentifier = "AA1B2C3D4E5F000100000001"
      BuildableName = "Gas Mask Tests.xctest"
      BlueprintName = "Gas Mask Tests"
      ReferencedContainer = "container:Gas Mask.xcodeproj">
   </BuildableReference>
</BuildActionEntry>
```

**Acceptance criteria**:
- [x] `xcodebuild build-for-testing -project "Gas Mask.xcodeproj" -scheme "Gas Mask" -destination "platform=macOS" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` succeeds
- [x] Test bundle appears at `$(BUILT_PRODUCTS_DIR)/Gas Mask Tests.xctest`
- [x] `Gas Mask.xcscheme` `<Testables>` block contains the test bundle reference
- [x] Python script validates that no generated UUID conflicts with an existing UUID in `project.pbxproj` before writing

### Task 5: Write test files
**Files**: `Tests/GasMaskTests/NodeTests.m`, `Tests/GasMaskTests/HostsTests.m`, `Tests/GasMaskTests/HostsGroupTests.m`, `Tests/GasMaskTests/AbstractHostsControllerTests.m`
**Description**:
Create the `Tests/GasMaskTests/` directory and write four test files. All imports use `#import <XCTest/XCTest.h>` plus the app headers (available via BUNDLE_LOADER).

#### NodeTests.m
```objc
@interface NodeTests : XCTestCase @end
@implementation NodeTests
- (void)testDefaultChildren { XCTAssertEqual(0, [[[[Node alloc] init] children] count]); }
- (void)testDefaultLeaf     { XCTAssertTrue([[[Node alloc] init] leaf]); }
- (void)testDefaultIsGroup  { XCTAssertFalse([[[Node alloc] init] isGroup]); }
- (void)testDefaultSelectable { XCTAssertTrue([[[Node alloc] init] selectable]); }
@end
```

#### HostsTests.m
Tests: `name` derivation, `setActive:` notification, `setSaved:` notification, `setEnabled:` notification, `selectable` toggling.
```objc
- (void)testNameFromPath { /* initWithPath:/tmp/work.hst → name == "work" */ }
- (void)testSetActivePostsNotification { /* observe HostsNodeNeedsUpdateNotification */ }
- (void)testSetSavedPostsNotification { /* same */ }
- (void)testSetEnabledPostsNotification { /* same */ }
- (void)testSelectableIsFalseWhenDisabled { /* setEnabled:NO → selectable == NO */ }
- (void)testSelectableIsTrueWhenEnabled { /* setEnabled:YES → selectable == YES */ }
- (void)testActiveNoopWhenSameValue { /* setActive:YES fires notification once; setActive:YES again → no second notification (guard: `if (active == _active) return`) */ }
```

#### HostsGroupTests.m
```objc
- (void)testInitSetsIsGroup { /* hostsGroup.isGroup == YES */ }
- (void)testInitSetsSelectable { /* hostsGroup.selectable == NO */ }
- (void)testInitSetsLeaf { /* hostsGroup.leaf == NO */ }
- (void)testInitSetsOnline { /* hostsGroup.online == YES */ }
- (void)testInitSetsSynchronizing { /* hostsGroup.synchronizing == NO */ }
- (void)testSynchronizingPostsNotification { /* observe SynchronizingStatusChangedNotification */ }
- (void)testSynchronizingNoopWhenSameValue { /* setSynchronizing:NO twice → fires once */ }
- (void)testOnlinePostsHostsNodeNotification { /* observe HostsNodeNeedsUpdateNotification; note: in source, notification is posted BEFORE online ivar is updated (known ordering issue in HostsGroup.m) — do not assert group.online inside the notification handler */ }
```

#### AbstractHostsControllerTests.m
Test via `LocalHostsController` (concrete subclass):
```objc
- (void)testGenerateName_noDuplicate { /* returns prefix unchanged */ }
- (void)testGenerateName_withOneDuplicate { /* second file → "Name 2" */ }
- (void)testGenerateName_withTwoDuplicates { /* "Name 2" taken → "Name 3" */ }
```
**Acceptance criteria**:
- [x] All 4 test files compile as part of the `Gas Mask Tests` target
- [x] `xcodebuild test` runs and all tests pass (38 tests)
- [x] Tests cover: Node defaults, Hosts notifications/selectable, HostsGroup init/notifications, AbstractHostsController.generateName

### Task 6: Update GitHub Actions CI
**Files**: `.github/workflows/push.yml`
**Description**:
Add a `test` job that runs `xcodebuild test` on the `Gas Mask Tests` scheme. The existing `build` job runs first (builds for both architectures); the `test` job can run independently:

```yaml
name: "on-push"
on:
  - push
jobs:
  build:
    name: Build
    runs-on: macos-15
    steps:
    - uses: actions/checkout@v4
    - name: Resolve packages          # fix: was missing from original build job
      run: xcodebuild -project "Gas Mask.xcodeproj" -resolvePackageDependencies
    - name: Build
      run: ./build.sh

  test:
    name: Test
    runs-on: macos-15
    steps:
    - uses: actions/checkout@v4
    - name: Resolve packages
      run: xcodebuild -project "Gas Mask.xcodeproj" -resolvePackageDependencies
    - name: Test
      run: |
        xcodebuild test \
          -project "Gas Mask.xcodeproj" \
          -scheme "Gas Mask" \
          -destination "platform=macOS" \
          CODE_SIGN_IDENTITY="" \
          CODE_SIGNING_REQUIRED=NO \
          CODE_SIGNING_ALLOWED=NO
```

Changes vs. the existing workflow:
- `build` job: adds the `-resolvePackageDependencies` step (fixes a latent issue — was missing before)
- `test` job: new job, uses the existing `"Gas Mask"` scheme with tests wired into it (no separate test scheme needed)
- Both jobs run in parallel on every push

**Acceptance criteria**:
- [ ] A new `test` job appears in GitHub Actions on every push (verified on next push)
- [ ] Test job passes on `macos-15` runner with `xcodebuild test -scheme "Gas Mask"` (verified on next push)
- [x] `build` and `test` jobs run in parallel (no `needs:` dependency between them)
- [x] `build` job now includes `resolvePackageDependencies` step

## Testing Strategy

### Unit Tests (Tasks 4–5)
- `NodeTests` — 4 property default tests
- `HostsTests` — 7 tests for name derivation, notification posting, selectable toggling
- `HostsGroupTests` — 8 tests for init properties and notification behaviour
- `AbstractHostsControllerTests` — 3 tests for `generateName:` logic

### Manual Verification (after Tasks 1–3)
1. Launch Gas Mask → all 3 section headers visible, all child files listed under them, expanded
2. One file is highlighted/selected (the currently active hosts file)
3. Switch active files → list updates correctly
4. Add/remove a file → list updates correctly
5. **Drag a `.hst` file from Finder onto the LOCAL group** → file is added (verifies `NSPasteboardTypeFileURL` registration works for Finder drags)

### CI Verification
- Push a commit → GitHub Actions shows both `Build` and `Test` jobs pass

## Risks and Considerations

- **`BUNDLE_LOADER` in CI**: The app starts headlessly during `xcodebuild test`. On GitHub Actions there is no `/etc/hosts` write risk because no hosts file is activated. If the runner's sandbox blocks `VDKQueue` kqueue setup, the app may log an error but tests still pass.
- **SPM package resolution in CI**: `xcodebuild test` requires SPM packages resolved. The `-resolvePackageDependencies` step handles this. The `macos-15` runner has network access to fetch Sparkle and ShortcutRecorder.
- **`willDisplayCell:` future removal**: The cell-based rendering will eventually be removed from AppKit. When that happens, the list will stop rendering. This plan adds nil guards and fixes the immediate bugs but does NOT migrate to view-based rendering. Add that as a follow-up task.
- **`Gas Mask Tests.xcscheme` must be shared**: The xcscheme must be placed in `xcshareddata/xcschemes/` (not user-specific `xcuserdata`) so that `xcodebuild -scheme` finds it in CI without an interactive Xcode session.
- **Task ordering**: Task 4 (project.pbxproj) must complete before Task 5 (test files) because the test files need to be referenced in the project. Tasks 1–3 and 4–5 can proceed in parallel.
