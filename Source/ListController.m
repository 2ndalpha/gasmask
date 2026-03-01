/***************************************************************************
 *   Copyright (C) 2009-2012 by Clockwise   *
 *   copyright@clockwise.ee   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

#import "ListController.h"
#import "HostsListView.h"
#import "Node.h"
#import "Cell.h"
#import "Hosts.h"
#import "HostsGroup.h"
#import "RemoteHosts.h"
#import "HostsMainController.h"

#define kFileURLType @"public.file-url"
#define kTextType @"public.utf8-plain-text"

#define kHostsHeight 20.0
#define kEmptyHostsGroupHeight 0.1

@interface ListController (Private)
- (void)hostsFilesLoaded:(NSNotification *)notification;
- (void)selectActiveHostsFile;
- (void)expandAllItems;
- (NSString*)urlFromPasteBoard:(NSPasteboard*)pasteboard;
- (BOOL)allowToDropTo:(Hosts*)target;
- (int)indexOfHosts:(Hosts*)hosts;
@end

@implementation ListController

static ListController *sharedInstance = nil;

+ (ListController*)defaultInstance
{
	return sharedInstance;
}

- (id)init
{
    if (sharedInstance) {
        return sharedInstance;
    }
	if (self = [super init]) {
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(updateItem:) name:HostsNodeNeedsUpdateNotification object:nil];
		[nc addObserver:self selector:@selector(updateItem:) name:SynchronizingStatusChangedNotification object:nil];
		[nc addObserver:self selector:@selector(renameHostsFile:) name:HostsFileShouldBeRenamedNotification object:nil];
		[nc addObserver:self selector:@selector(selectHostsFile:) name:HostsFileShouldBeSelectedNotification object:nil];
		[nc addObserver:self selector:@selector(deleteDraggedHostsFile:) name:DraggedFileShouldBeRemovedNotification object:nil];
		[nc addObserver:self selector:@selector(hostsFilesLoaded:) name:AllHostsFilesLoadedFromDiskNotification object:nil];
		
		sharedInstance = self;
	}
    return sharedInstance;
}

- (void)awakeFromNib
{
	[self expandAllItems];
	[self selectActiveHostsFile];
}

- (void)deactivate
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateItem:(NSNotification *)notification
{
	int index = [self indexOfHosts:[notification object]];
	[list reloadItem:[list itemAtRow:index]];
}

- (Hosts*) selectedHosts
{
	return [[list itemAtRow:[list selectedRow]] representedObject];
}

@end

@implementation ListController (Private)

- (void)hostsFilesLoaded:(NSNotification *)notification
{
	[self expandAllItems];
	[self selectActiveHostsFile];
}

- (void)selectActiveHostsFile
{
	for (int i=0; i<[list numberOfRows]; i++) {
		Hosts *hosts = [[list itemAtRow:i] representedObject];
		if ([hosts active]) {
			
			logInfo(@"Selecting active item: %@", [hosts name]);
			NSIndexSet *idx = [[NSIndexSet alloc] initWithIndex:i];
			[list selectRowIndexes:idx byExtendingSelection:NO];
			
			return;
		}
	}
	logWarn(@"No active item to select!");
}

- (void)renameHostsFile:(NSNotification *)notification
{
	[list editColumn:0 row:[self indexOfHosts:[notification object]] withEvent:nil select:YES];
}

- (void)selectHostsFile:(NSNotification *)notification
{
	int index = [self indexOfHosts:[notification object]];
	NSIndexSet *idx = [[NSIndexSet alloc] initWithIndex:index];
	[list selectRowIndexes:idx byExtendingSelection:NO];
}

- (void)deleteDraggedHostsFile:(NSNotification *)notification
{
	if ([hostsController canRemoveFiles]) {
		[hostsController removeHostsFile:draggedHosts moveToTrash:YES];
		draggedHosts = nil;
	}
}

- (void)expandAllItems
{
	logDebug(@"Expanding all items");
	for (int i=0; i<[list numberOfRows]; i++) {
		[list expandItem:[list itemAtRow:i]];
	}
}


#pragma mark -
#pragma mark NSOutlineView delegate

-(BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item
{
	return [[item representedObject] isGroup];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
	return [[item representedObject] selectable];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
	return NO;
}

- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{	
	[(Cell*)cell setItem:[item representedObject]];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	Hosts *hosts = [item representedObject];
	if (![list showEmptyHostsGroups] && [hosts isMemberOfClass:[HostsGroup class]] && [[hosts children] count] == 0) {
		return kEmptyHostsGroupHeight;
	}

	return kHostsHeight;
}

#pragma mark -
#pragma mark Drag and Drop

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	Hosts *hosts = [[items objectAtIndex:0] representedObject];
	if ([hosts isKindOfClass:[HostsGroup class]]) {
		return NO;
	}
	
	[pboard setString:[hosts contents] forType:NSPasteboardTypeString];
	draggedHosts = hosts;
	
	return YES;
}

/*
 Proposing data for dropping.
 */
- (NSDragOperation)outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex
{
	Hosts *destinationHosts = [item representedObject];
	if (destinationHosts == nil) {
		return NSDragOperationNone;
	}
	
	// Data is dragged from external application
	if ([info draggingSource] == nil) {
		
		NSString *rawURL = [self urlFromPasteBoard:[info draggingPasteboard]];
		
		// URL is dragged to the list
		if (rawURL) {
			
			id target = item;
			if (![destinationHosts isMemberOfClass:[HostsGroup class]]) {
				target = [list parentForItem:item];
			}
			
			NSURL *url = [NSURL URLWithString:rawURL];
			// Local URL
			if ([url isFileURL]) {
				if (![[rawURL pathExtension] isEqual:HostsFileExtension]) {
					return NSDragOperationNone;
				}
				
				if (![hostsController canCreateHostsFromLocalURL:url toGroup:(HostsGroup*)[target representedObject]]) {
					return NSDragOperationNone;
				}
			}
			// Remote URL
			else {
				if (![hostsController canCreateHostsFromURL:url toGroup:(HostsGroup*)[target representedObject]]) {
					return NSDragOperationNone;
				}
			}
			
			[list setDropItem:target dropChildIndex:NSOutlineViewDropOnItemIndex];
			
			return NSDragOperationGeneric;
		}
		
		return NSDragOperationNone;
	}
	
	NSDragOperation result = NSDragOperationGeneric;
	
	id target = item;
	if ([destinationHosts isMemberOfClass:[Hosts class]]) {
		target = [list parentForItem:item];
	}
	
	if ([info draggingSource] == list) {
		if (![self allowToDropTo:destinationHosts]) {
			return NSDragOperationNone;
		}
	}
	
	[list setDropItem:target dropChildIndex:NSOutlineViewDropOnItemIndex];
	
	return result;
}

/*
 Actually droping data.
 */
- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex
{	

	if ([info draggingSource] == list) {
		[hostsController move:draggedHosts to:[item representedObject]];
		draggedHosts = nil;
		return YES;
	}
	
	NSString *rawURL = [self urlFromPasteBoard:[info draggingPasteboard]];
	if (rawURL) {
		NSURL *url = [NSURL URLWithString:rawURL];
		HostsGroup *group = [item representedObject];
		
		// Local URL
		if ([url isFileURL]) {
			return [hostsController createHostsFromLocalURL:url toGroup:group];
		}
		// WEB URL
		else {
			logDebug(@"Creating from URL \"%@\" to group \"%@\"", [url absoluteString], group);
			
			return [hostsController createHostsFromURL:url toGroup:group];
		}
	}
	
	return NO;
}


- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items
{
	// TODO
	logDebug(@"PROMISE!");
	return nil;
}

- (NSString*)urlFromPasteBoard:(NSPasteboard*)pasteboard
{
	for (NSPasteboardItem *item in [pasteboard pasteboardItems]) {
		if ([[item types] containsObject:kFileURLType]) {
			return [item stringForType:kFileURLType];
		}
	}
	
	for (NSPasteboardItem *item in [pasteboard pasteboardItems]) {
		if ([[item types] containsObject:kTextType]) {
			NSString *text = [item stringForType:kTextType];
			NSURL *url = [NSURL URLWithString:text];
			if (url && [url scheme] != nil) {
				return text;
			}
		}
	}
	
	return nil;
}

- (BOOL)allowToDropTo:(Hosts*)target
{
	if ([draggedHosts isMemberOfClass:[RemoteHosts class]]) {
		if ([target isMemberOfClass:[Hosts class]] && [draggedHosts exists]) {
			return YES;
		}
	}
	return NO;
}

- (int)indexOfHosts:(Hosts*)hosts
{
	for (int i=0; i<[list numberOfRows]; i++) {
		Hosts *obj = [[list itemAtRow:i] representedObject];
		if ([obj isEqual:hosts]) {
			return i;
		}
	}
	
	return -1;
}

@end
