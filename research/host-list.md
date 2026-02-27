# Research: Host List Feature

*Researched on: 2026-02-27*

## Overview

The host list is the left-side sidebar in Gas Mask's Editor window. It uses a cell-based `NSOutlineView` (legacy macOS API, deprecated since macOS 10.10) driven by `NSTreeController` bindings, with a custom `NSTextFieldCell` subclass (`Cell`) for rendering. The entire feature has **zero automated test coverage** — no XCTest target exists in the project at all. Several deprecated APIs are actively used (`NSStringPboardType`, `NSFilenamesPboardType`, `willDisplayCell:`, `NSCompositeSourceOver`), any of which may silently fail or crash on macOS 26.

## Key Files

| File | Role |
|------|------|
| `Source/HostsListView.h/.m` | Custom `NSOutlineView` subclass — drag registration, source-list highlight, cell setup |
| `Source/ListController.h/.m` | `NSOutlineViewDelegate` — group detection, selection, row height, drag/drop, rename |
| `Source/Cell.h/.m` | Custom `NSTextFieldCell` — draws file icon, active checkmark, unsaved dot, badges |
| `Source/HostsMainController.h/.m` | `NSTreeController` subclass — manages the tree (3 groups × N files), file CRUD |
| `Source/AbstractHostsController.h/.m` | Shared base for Local/Remote/Combined controllers |
| `Source/LocalHostsController.h/.m` | Loads `.hst` files from disk; creates/renames/removes local files |
| `Source/Node.h/.m` | Base model: `children`, `leaf`, `isGroup`, `selectable` (all `@synthesize`) |
| `Source/Hosts.h/.m` | Represents one hosts file: `path`, `contents`, `active`, `saved`, `enabled`, `exists`, `error` |
| `Source/HostsGroup.h/.m` | Section header node: `name`, `online`, `synchronizing`; `isGroup=YES`, `selectable=NO` |
| `Source/BadgeManager.h/.m` | Creates/tracks Badge subview instances per-host, cleans up on removal |
| `Source/Cell.m` (Badge category) | Places `AlertBadge`, `SyncingArrowsBadge`, `OfflineBadge` as `NSView` subviews |
| `Editor.xib` | NIB wiring — NSOutlineView ↔ ListController (delegate/datasource), column binding `arrangedObjects.name` → HostsMainController |

## Architecture & Data Flow

### Tree Structure (NSTreeController)

```
HostsMainController (NSTreeController subclass)
  content: NSArray of root HostsGroup objects
    [0] LocalGroup  (HostsGroup, isGroup=YES, selectable=NO)
          children[0] Hosts("work.hst")
          children[1] Hosts("default.hst")
    [1] RemoteGroup (HostsGroup)
          children[0] RemoteHosts("ads.hst")
    [2] CombinedGroup (HostsGroup)
          children[]  (empty — hidden if no drag in progress)
```

`childrenKeyPath = "children"`, `leafKeyPath = "leaf"` — both are KVC-synthesized on `Node`.

### Load sequence

```
ApplicationController.applicationWillFinishLaunching
  → HostsMainController.load
    → addGroups()           — insertObject:hostsGroup at [0],[1],[2]
    → LocalHostsController.loadFiles()   — scans disk, populates hostsFiles
    → insertObject:hostsFile at [0,0],[0,1]…  (updates group.children via KVC)
    → RemoteHostsController.loadFiles()  → insertObject at [1,0]…
    → CombinedHostsController.loadFiles()→ insertObject at [2,0]…
  → postNotificationName: ActivateFileNotification

ListController.awakeFromNib
  → expandAllItems()        — [list expandItem:] for every row
  → selectActiveHostsFile() — scans rows, selects row where hosts.active==YES
```

### Render pipeline (cell-based — DEPRECATED API)

```
NSOutlineView requests row display
  → ListController.outlineView:willDisplayCell:forTableColumn:item:
       [(Cell*)cell setItem:[item representedObject]]
  → Cell.drawWithFrame:inView:
       if isGroup → draw badges (offline/syncing/alert) on group
       else       → draw file icon + text + active checkmark + unsaved dot
```

**`willDisplayCell:forTableColumn:item:` is a cell-based delegate method** deprecated in macOS 10.10. If it is not called (e.g., because macOS 26 drops cell-based rendering support), `cell.item` is never set and all drawing is done with `item = nil`, which crashes or draws nothing.

### Notification-driven updates

| Notification | Handler | Action |
|---|---|---|
| `HostsNodeNeedsUpdateNotification` | `ListController.updateItem:` | `reloadItem:` for that row |
| `SynchronizingStatusChangedNotification` | same | same |
| `HostsFileShouldBeRenamedNotification` | `renameHostsFile:` | `editColumn:0 row:…` |
| `HostsFileShouldBeSelectedNotification` | `selectHostsFile:` | `selectRowIndexes:` |
| `DraggedFileShouldBeRemovedNotification` | `deleteDraggedHostsFile:` | calls `hostsController.removeHostsFile:` |
| `HostsFileWillBeRemovedNotification` | `handleHostsFileRemoval:` | runs poof animation |

## Patterns & Conventions

- Pure Objective-C, modules disabled — use `#import` not `@import`
- Singleton pattern via `static sharedInstance` in both `ListController` and `HostsMainController`
- All model mutation goes through `HostsMainController` which posts NSNotifications for side effects
- `NSTreeController` insertions use `insertObject:atArrangedObjectIndexPath:` — this also updates model's `children` array via `mutableArrayValueForKey:`
- Images are loaded by name (`[NSImage imageNamed:]`) from the main bundle; all needed files are in `Resources/Images/` and referenced in `project.pbxproj`
- Badges (`AlertBadge`, `OfflineBadge`, `SyncingArrowsBadge`) are `NSView` subclasses added as subviews of the outline view by `Cell`

## Dependencies

### Internal
- `HostsMainController` → `LocalHostsController`, `RemoteHostsController`, `CombinedHostsController`
- `ListController` → `HostsMainController`, `HostsListView`, `Cell`
- `Cell` → `Hosts`, `RemoteHosts`, `CombinedHosts`, `HostsGroup`, `BadgeManager`, badge classes

### External / System
- `AppKit` — `NSOutlineView`, `NSTreeController`, `NSCell`, `NSNotificationCenter`
- `VDKQueue` (bundled 3rd-party) — file change monitoring for `/etc/hosts`
- Images: all `.png`/`.tiff` files in `Resources/Images/`, added to `Copy Bundle Resources` build phase

### No test infrastructure
- No XCTest target in `Gas Mask.xcodeproj`
- `Tests/` directory contains only `IP4 Syntax Tests.hst` — a hosts file, not a test file

## Constraints & Risks

### 1. Cell-based NSOutlineView (highest risk)
`NSCell`-based table/outline views were deprecated in macOS 10.10 and the entire pipeline (`willDisplayCell:`, `NSTextFieldCell` subclass, `setDataCell:`) may be silently dropped in macOS 26. If `willDisplayCell:` is not called, `cell.item` stays nil → crash in `drawWithFrame:` at `[item isGroup]`.

### 2. Deprecated pasteboard types
`NSStringPboardType` and `NSFilenamesPboardType` (used in `HostsListView.awakeFromNib` and `ListController`) were deprecated in macOS 10.13. They are aliased to `NSPasteboardTypeString` / `NSPasteboardTypeFileURL`, but newer macOS may stop registering drag types for them.

### 3. `NSCompositeSourceOver` deprecated
Used in `Cell.m` for all image drawing. It's aliased to `NSCompositingOperationSourceOver` since macOS 10.12. Low risk but generates deprecation warnings.

### 4. No error handling for nil `item` in Cell
`Cell.drawWithFrame:` calls `[item isGroup]` at the very first line without a nil guard. If `item` is nil (e.g., because `willDisplayCell:` was never called), this crashes.

### 5. NSTreeController `childrenKeyPath` KVC mutation
`HostsMainController.insertObject:atArrangedObjectIndexPath:` relies on KVC to update the `children` array on model objects. `Node.children` is a plain `NSArray` (`@synthesize`). For mutable KVC proxy insertion to work, the receiver needs either `insertObject:inChildrenAtIndex:` methods OR a KVO-compliant setter. The absence of `insertObject:inChildrenAtIndex:` means the KVC proxy will call `setChildren:` on every insert — functional but inefficient, and may silently fail if KVO isn't set up correctly on a macOS 26 release.

### 6. `BadgeManager` memory / view lifecycle
Badges are added as subviews of the NSOutlineView (`[controlView addSubview:badge]`) inside `drawWithFrame:`. They are never removed when cells scroll off-screen, only when `removeBadge` is called. On scroll-heavy lists this accumulates views. More critically: if the same cell is drawn for a different row (cell reuse in NSOutlineView), the old badge is still attached to the view at the wrong position.

### 7. `NSAlertStyle` deprecated constants
`NSWarningAlertStyle` used in `removeSelectedHostsFile:` — replaced by `NSAlertStyleWarning`. Causes compile warnings.

## Open Questions

1. **What exactly is broken?** The user reports the host list is broken but hasn't described the symptom — empty list, crash, no icons, no selection? A crash log or symptom description is needed to narrow root cause.
2. **macOS version in use?** macOS 26.x (as indicated by Xcode 26.2). Have cell-based NSTableView/NSOutlineView APIs been removed or does `willDisplayCell:` still fire?
3. **Is the NSTreeController binding still wired correctly in Editor.xib?** The `arrangedObjects.name` binding to `HostsMainController` on the table column could be broken if the NIB was touched during the Xcode fix work.
4. **Does `expandAllItems` run before the tree is populated?** `ListController.awakeFromNib` calls `expandAllItems`, but if `HostsMainController.load` hasn't been called yet (it's called from `applicationWillFinishLaunching`), there are no rows and the expand is a no-op. This is a timing issue that could leave the list unexpanded.
5. **Does `selectActiveHostsFile` run before `load`?** Same concern — could log "No active item to select!" and leave nothing selected.
