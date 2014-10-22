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

#import "Menulet.h"
#import "Hosts.h"
#import "HostsMainController.h"
#import "HostsMenu.h"


@implementation Menulet

- (void)awakeFromNib
{	
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setHighlightMode:YES];
	[statusItem setEnabled:YES];
	[statusItem setToolTip:@"Gas Mask"];
	[statusItem setTitle:@""];
	[statusItem setAction:@selector(showMenu:)];
	[statusItem setTarget:self];
	
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"menuIcon" ofType:@"tiff"];
	NSImage *icon = [[NSImage alloc] initWithContentsOfFile:path];
    [icon setTemplate:YES];
	
	[statusItem setImage:icon];
}

-(IBAction)showMenu:(id)sender
{	
	HostsMenu *menu = [[HostsMenu alloc] initWithExtras];
	[statusItem popUpStatusItemMenu:menu];
}

@end