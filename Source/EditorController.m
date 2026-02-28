/***************************************************************************
 *   Copyright (C) 2009-2010 by Clockwise   *
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

#import "EditorController.h"
#import "Preferences.h"
#import "ExtendedNSSplitView.h"
#import "Gas_Mask-Swift.h"

#define SplitViewMinWidth 140
#define SplitViewMaxWidth 300
#define SplitViewDefaultWidth 160


@implementation EditorController

- (void)awakeFromNib
{	
	[editorWindow setContentBorderThickness: [splitView frame].origin.y forEdge: NSMinYEdge];
	[[filesCountTextField cell] setBackgroundStyle: NSBackgroundStyleRaised];

	[readOnlyIconView setToolTip:@"Hosts file can not be modified"];
    
    int dividerIndex = 0;
    CGFloat position = [splitView positionOfDividerAtIndex:dividerIndex];
    if (position > SplitViewMaxWidth) {
        [splitView setPosition:SplitViewDefaultWidth ofDividerAtIndex:dividerIndex];
    }

    [SidebarInstaller installIn:splitView];
}

#pragma mark - Split View Delegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex;
{
    return proposedMinimumPosition + SplitViewMinWidth;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex;
{
    return SplitViewMaxWidth;
}

- (void)splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect newFrame = [sender frame];
	NSView *left = [[sender subviews] objectAtIndex:0];
	NSRect leftFrame = [left frame];
	NSView *right = [[sender subviews] objectAtIndex:1];
	NSRect rightFrame = [right frame];
	
	CGFloat dividerThickness = [sender dividerThickness];
	
	leftFrame.size.height = newFrame.size.height;
	
	rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
	rightFrame.size.height = newFrame.size.height;
	rightFrame.origin.x = leftFrame.size.width + dividerThickness;
	
	[left setFrame:leftFrame];
	[right setFrame:rightFrame];
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return NO;
}

#pragma mark - NSWindow Delegate

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[Preferences setShowEditorWindow:YES];
}

- (BOOL)windowShouldClose:(id)sender
{
	[Preferences setShowEditorWindow:NO];
	return YES;
}

@end
