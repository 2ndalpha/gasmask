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

#import "HostsListView.h"
#import "HostsListViewMenu.h"
#import "HostsGroup.h"
#import "Hosts.h"
#import "Cell.h"

#define kColumnIdName @"NameColumn"

@interface HostsListView (Private)

- (void)hideEmptyHostsGroups;

@end


@implementation HostsListView


@synthesize showEmptyHostsGroups;

- (void)awakeFromNib
{    
	[self registerForDraggedTypes:@[NSPasteboardTypeString, NSPasteboardTypeFileURL]];
	[self setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
	[self setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];

	[self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	
	NSTableColumn *tableColumn = [self tableColumnWithIdentifier:kColumnIdName];
	cell = [[Cell alloc] init];
	[cell setEditable:YES];
	[tableColumn setDataCell:cell];
	
}


- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    int row = [self rowAtPoint:point];
	
	if (row == -1) {
		return nil;
	}
	
	Hosts *hosts = [[self itemAtRow:row] representedObject];
	if (![hosts selectable]) {
		return nil;
	}
	
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	
	return [[HostsListViewMenu alloc] initWithHosts:hosts];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	return YES;
}

/* Removes all badges from HostGroup items.
 It is needed because item with no height will not be redrawn and bages
 would not be removed.
 */
- (void)removeBadgesFromGroups
{
	for (int i=0; i<[self numberOfRows]; i++) {
		Hosts *hosts = (Hosts*)[[self itemAtRow:i] representedObject];
		if ([hosts isKindOfClass:[HostsGroup class]]) {
			
			[cell setItem:hosts];
			[cell removeAllBadges];
			
		}
	}
}

#pragma mark -
#pragma mark NSDraggingSource

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	// Dragged item ended up in Trash
    if (operation == NSDragOperationDelete) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:DraggedFileShouldBeRemovedNotification object:nil];
    }
	else {
        [super draggedImage:image endedAt:screenPoint operation:operation];
    }
}

#pragma mark -
#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
	// Unhide empty hosts groups
	showEmptyHostsGroups = YES;
	[self reloadData];

	return [super draggingEntered:sender];
}

- (void)draggingEnded:(id < NSDraggingInfo >)sender
{
	[self hideEmptyHostsGroups];
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	[self hideEmptyHostsGroups];
	[super draggingExited:sender];
}

@end

@implementation HostsListView (Private)

- (void)hideEmptyHostsGroups
{
	if (showEmptyHostsGroups) {
		showEmptyHostsGroups = NO;
		
		[self removeBadgesFromGroups];
        [self reloadData];
	}
}

@end

