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

#import "Cell.h"
#import "Hosts.h"
#import "RemoteHosts.h"
#import "CombinedHosts.h"
#import "HostsGroup.h"
#import "SyncingArrowsBadge.h"
#import "AlertBadge.h"
#import "OfflineBadge.h"
#import "BadgeManager.h"
#import "ListController.h"
#import "HostsListView.h"

#define kIconImageSize		16.0
#define kImageOriginXOffset 3
#define kImageOriginYOffset 1

#define kActiveImageXOffset 32

#define kTextOriginXOffset	4
#define kTextOriginYOffset	2
#define kTextHeightAdjust	4

#define kImageSize 13
#define kRightImageArea 22

CGFloat const kWidthOfProgressIndicator = 16.0f;

@interface Cell(Private)

- (void)drawActiveIconWithFrame:(NSRect)cellFrame;
- (void)drawUnsavedIconWithFrame:(NSRect)cellFrame;

- (void)drawIconRight:(NSImage*)icon withFrame:(NSRect)cellFrame;

- (NSRect)textFrame:(NSRect)cellFrame;
- (NSRect)fileIconFrame:(NSRect)cellFrame icon:(NSImage*)icon;
- (NSRect)rightIconFrame:(NSRect)cellFrame;

- (void)cleanUpForHosts:(NSNotification *)notification;
@end

@interface Cell(Badge)
- (void)placeBadge:(Badge*)badge inFrame:(NSRect)cellFrame view:(NSView *)controlView;

- (AlertBadge*)createAlertBadge;
- (void)placeAlertBadgeInFrame:(NSRect)cellFrame view:(NSView *)controlView;
- (void)removeAlertBadge;

- (SyncingArrowsBadge*)createSyncArrowsBadge;
- (void)placeSyncArrowsBadgeInFrame:(NSRect)cellFrame view:(NSView *)controlView;
- (void)removeSyncArrowsBadge;

- (void)placeOfflineBadgeInFrame:(NSRect)cellFrame view:(NSView *)controlView;
- (OfflineBadge*)createOfflineBadge;
- (void)removeOfflineBadge;

@end


@implementation Cell

- (id)init
{
	self = [super init];
	
    [self setTruncatesLastVisibleLine:YES];
	[self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9) {
        localFileIcon = [NSImage imageNamed: @"Local File.png"];
        remoteFileIcon = [NSImage imageNamed: @"Remote old.png"];
        remoteDisabledFileIcon = [NSImage imageNamed: @"Remote_disabled.png"];
        combinedFileIcon = [NSImage imageNamed: @"Combined_File.png"];
    }
    else {
        localFileIcon = [NSImage imageNamed: @"Local File yosemite.tiff"];
        remoteFileIcon = [NSImage imageNamed: @"Remote yosemite.tiff"];
        remoteDisabledFileIcon = [NSImage imageNamed: @"Remote yosemite.tiff"];
        combinedFileIcon = [NSImage imageNamed: @"Combined_File_yosemite.tiff"];
    }

	activeIcon = [NSImage imageNamed: @"Activated"];
	unsavedIcon = [NSImage imageNamed: @"Blue Dot"];
	
	syncingArrowsBadgeManager = [BadgeManager badgeManagerWithCreator:@selector(createSyncArrowsBadge) target:self];
	alertBadgeManager = [BadgeManager badgeManagerWithCreator:@selector(createAlertBadge) target:self];
	offlineBadgeManager = [BadgeManager badgeManagerWithCreator:@selector(createOfflineBadge) target:self];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(cleanUpForHosts:) name:HostsFileRemovedNotification object:nil];
	
	return self;
}

- (void)setItem:(Hosts*)i
{
	item = i;
	offline = [item isKindOfClass:[HostsGroup class]] && ![(HostsGroup*)item online];
}

- (void)removeAllBadges
{
	[self removeAlertBadge];
	[self removeOfflineBadge];
	[self removeSyncArrowsBadge];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	if (!item) {
		return;
	}
	if ([item isGroup]) {
		HostsGroup *group = (HostsGroup*)item;
        if ([[group children] count] == 0) {
            return;
        }
		
		if (offline) {
			[self placeOfflineBadgeInFrame:cellFrame view:controlView];
		}
		else {
			[self removeOfflineBadge];
		}
		
		if ([group synchronizing]) {
			[self placeSyncArrowsBadgeInFrame:cellFrame view:controlView];
		}
		else {
			[self removeSyncArrowsBadge];
		}
		
		if ([item error] != nil) {
			[self placeAlertBadgeInFrame:cellFrame view:controlView];
		}
		else {
			[self removeAlertBadge];
		}
		
		[super drawWithFrame:cellFrame inView:controlView];
		return;
	}
	
	NSImage *image;
	[self setEnabled:YES];
	
	if (![item enabled]) {
		[self setEnabled:NO];
	}
	
	if ([item isKindOfClass:[RemoteHosts class]]) {
		image = [item enabled] ? remoteFileIcon : remoteDisabledFileIcon;
	}
    else if ([item isKindOfClass:[CombinedHosts class]]) {
        image = combinedFileIcon;
    }
	else {
		image = localFileIcon;
	}
	
	NSRect frame = [self fileIconFrame:cellFrame icon:image];
	[image drawInRect:frame fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
	[super drawWithFrame:[self textFrame:cellFrame] inView:controlView];
	
	if ([item active]) {
		[self drawActiveIconWithFrame:cellFrame];
	}
	
	if (![item saved]) {
		[self drawUnsavedIconWithFrame:cellFrame];
	}
	
	if ([item error] != nil) {
		[self placeAlertBadgeInFrame:cellFrame view:controlView];
	}
	else {
		[self removeAlertBadge];
	}
}

- (NSRect)titleRectForBounds:(NSRect)cellRect
{	
	NSRect newFrame = cellRect;
	
	int xOffset = kImageOriginXOffset + kIconImageSize + 4;
	newFrame.origin.x += xOffset;
	newFrame.origin.y += kTextOriginYOffset;
	newFrame.size.height -= kTextHeightAdjust;
	newFrame.size.width -= xOffset;
	
	if (![item saved] || [item error] != nil) {
		newFrame.size.width -= kRightImageArea;
	}
	
	return newFrame;
}

- (NSCellHitResult) hitTestForEvent: (NSEvent *) event inRect: (NSRect) cellFrame ofView: (NSView *) controlView
{
	NSPoint point = [controlView convertPoint:[event locationInWindow] fromView:nil];
	
	if (([item error] != nil || offline) && NSMouseInRect(point, [self rightIconFrame:cellFrame], [controlView isFlipped])) {
		return NSCellHitTrackableArea;
	}
	else if (NSMouseInRect(point, [self textFrame:cellFrame], [controlView isFlipped])) {
		return NSCellHitEditableTextArea;
	}
	
	return NSCellHitContentArea;
}

- (BOOL) trackMouse: (NSEvent *) event inRect: (NSRect) cellFrame ofView: (NSView *) controlView untilMouseUp: (BOOL) flag
{
	return YES;
}


- (void)editWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject event:(NSEvent*)theEvent
{
	NSRect textFrame = [self titleRectForBounds:aRect];
	[super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject start:(long)selStart length:(NSInteger)selLength
{
	NSRect textFrame = [self titleRectForBounds:aRect];
	[super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

@end

@implementation Cell(Private)

- (void)drawActiveIconWithFrame:(NSRect)cellFrame
{
	NSSize imageSize = [activeIcon size];
	NSRect frame;
	NSDivideRect(cellFrame, &frame, &cellFrame, imageSize.width, NSMinXEdge);
	
	frame.size = imageSize;
	frame.origin.x -= imageSize.width + 1;
	frame.origin.y += ceil((cellFrame.size.height - imageSize.height) / 2);
	
	[activeIcon drawInRect:frame fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}

- (void)drawUnsavedIconWithFrame:(NSRect)cellFrame
{
	[self drawIconRight:unsavedIcon withFrame:cellFrame];
}

- (void)drawIconRight:(NSImage*)icon withFrame:(NSRect)cellFrame
{
	NSRect frame = [self rightIconFrame:cellFrame];
	[icon drawInRect:frame fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}

- (NSRect)textFrame:(NSRect)cellFrame
{
	NSRect frame = cellFrame;
	frame.origin.x += kTextOriginXOffset + kIconImageSize;
	frame.origin.y += kTextOriginYOffset;
	frame.size.height -= kTextHeightAdjust;
	frame.size.width -= frame.origin.x;
	
	return frame;
}

- (NSRect)fileIconFrame:(NSRect)cellFrame icon:(NSImage*)icon
{
	NSSize imageSize = [icon size];
	NSRect frame;
	NSDivideRect(cellFrame, &frame, &cellFrame, imageSize.width, NSMinXEdge);
	
	frame.size = imageSize;
    frame.origin.x += 2;
	frame.origin.y += ceil((cellFrame.size.height - imageSize.height) / 2);
	
	return frame;
}

- (NSRect)rightIconFrame:(NSRect)cellFrame
{	
	NSSize iconSize = NSMakeSize(kImageSize, kImageSize);
	NSRect frame;
	NSDivideRect(cellFrame, &frame, &cellFrame, iconSize.width, NSMaxXEdge);
	frame.size = iconSize;
	frame.origin.y += ceil((cellFrame.size.height - iconSize.height) / 2);
	
	return frame;
}

- (void)cleanUpForHosts:(NSNotification *)notification
{
	Hosts *hosts = item;
	item = [notification object];
	
	[self removeSyncArrowsBadge];
	[self removeAlertBadge];
	
	item = hosts;
}

@end

@implementation Cell (Badge)

- (void)placeBadge:(Badge*)badge inFrame:(NSRect)cellFrame view:(NSView *)controlView
{
	NSSize size;
	NSRect frame;
	
	size = [badge frame].size;
	NSDivideRect(cellFrame, &frame, &cellFrame, size.width, NSMaxXEdge);
	frame.size = size;
	
	[badge setFrame:frame];
	[controlView addSubview:badge];
}

#pragma mark Alert

- (AlertBadge*)createAlertBadge
{
	return [[AlertBadge alloc] initWithRemoteHosts:(RemoteHosts*)item];
}

- (void)placeAlertBadgeInFrame:(NSRect)cellFrame view:(NSView *)controlView
{
	Badge *badge = [alertBadgeManager getBadgeForObject:item];
	[self placeBadge:badge inFrame:cellFrame view:controlView];
}

- (void)removeAlertBadge
{
	[alertBadgeManager removeBadgeForObject:item];
}

#pragma mark Syncing Arrows

- (SyncingArrowsBadge*)createSyncArrowsBadge
{
	SyncingArrowsBadge *badge = [SyncingArrowsBadge new];
	[badge start];
	return badge;
}

- (void)placeSyncArrowsBadgeInFrame:(NSRect)cellFrame view:(NSView *)controlView
{	
	Badge *badge = [syncingArrowsBadgeManager getBadgeForObject:item];
	[self placeBadge:badge inFrame:cellFrame view:controlView];
}

- (void)removeSyncArrowsBadge
{
	[syncingArrowsBadgeManager removeBadgeForObject:item];
}

#pragma mark Offline

- (void)placeOfflineBadgeInFrame:(NSRect)cellFrame view:(NSView *)controlView
{
	Badge *badge = [offlineBadgeManager getBadgeForObject:item];
	[self placeBadge:badge inFrame:cellFrame view:controlView];

}

- (OfflineBadge*)createOfflineBadge
{
	return [[OfflineBadge alloc] initWithHosts:item];
}

- (void)removeOfflineBadge
{
	[offlineBadgeManager removeBadgeForObject:item];
}

@end

