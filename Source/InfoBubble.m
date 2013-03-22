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

#import "MAAttachedWindow.h"

#import "InfoBubble.h"

@interface InfoBubble (Private)

- (void)setOnlyTitleMode;

@end



@implementation InfoBubble

- (id)init
{
	self = [super initWithNibName:@"InfoBubbleView" bundle:nil];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(closeKeyWindow:) name:NSWindowDidResignKeyNotification object:nil];
	[nc addObserver:self selector:@selector(closeWindow:) name:NSApplicationWillResignActiveNotification object:nil];
	
	return self;
}

- (void)dealloc
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
}

- (void)closeWindow:(NSNotification *)notification
{
	if (!closed) {
		closed = YES;
		[[NSApp mainWindow] removeChildWindow:window];
	}
}

- (void)closeKeyWindow:(NSNotification *)notification
{
	if (window == [notification object] && !closed) {
		[self closeWindow:notification];
	}
}

- (void)show:(NSPoint)p
{
	point = p;
	[self loadView];
}

- (void)awakeFromNib
{
	if (title) {
		[titleField setStringValue:title];
		
		if (!description) {
			[self setOnlyTitleMode];
		}
	}
	
	[self setDescription:description];
	
	if (!url) {
		[openInBrowserButton setHidden:YES];
		
		// Resize view
		NSRect frame = [[self view] frame];
		frame.size.height -= [openInBrowserButton frame].size.height;
		[[self view] setFrame:frame];
	}
	
	window = [[MAAttachedWindow alloc] initWithView:[self view] 
									attachedToPoint:point
										   inWindow:[NSApp mainWindow]
											 onSide:MAPositionRight
										 atDistance:2.0];
	[window setViewMargin:15.0];
	[[NSApp mainWindow] addChildWindow:window ordered:NSWindowAbove];
	[window makeKeyWindow];
	[window setReleasedWhenClosed:YES];
}

- (void)setTitle:(NSString*)newTitle
{
	title = newTitle;
	if (titleField) {
		[titleField setStringValue:title];
	}
}

- (void)setDescription:(NSString*)newDescription
{
	if (newDescription) {
		description = newDescription;
		if (descriptionField) {
			
			// Resize
			NSRect bounds = NSMakeRect(0, 0, [descriptionField frame].size.width, 99999);
			[descriptionField setStringValue:description];
			
			float requiredHeight = [[descriptionField cell] cellSizeForBounds:bounds].height;
			
			NSRect frame = [descriptionField frame];
			
			float difference = requiredHeight - frame.size.height;
			float y = frame.origin.y;
			y -= difference;
			
			frame.origin.y = y;
			frame.size.height = requiredHeight;
			
			[descriptionField setFrame:frame];
			
			// Resize view
			frame = [[self view] frame];
			frame.size.height += difference;
			[[self view] setFrame:frame];
		}
	}
	else {
		description = nil;
		if (descriptionField) {
			// Resize view
			NSRect frame = [[self view] frame];
			frame.size.height -= [descriptionField frame].size.height + 10;
			[[self view] setFrame:frame];
			[descriptionField setHidden:YES];
		}
	}

}

- (void)setURL:(NSURL*)newURL
{
	url = newURL;
}

- (IBAction)openInBrowser:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:url];
}

@end

@implementation InfoBubble (Private)

- (void)setOnlyTitleMode
{
	NSFont *font = [titleField font];
	font = [[NSFontManager sharedFontManager] convertFont: font toHaveTrait: NSUnboldFontMask];
	[titleField setFont:font];
}

@end

