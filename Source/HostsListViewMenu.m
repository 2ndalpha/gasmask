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

#import "HostsListViewMenu.h"
#import "HostsMainController.h"
#import "Hosts.h"
#import "RemoteHosts.h"
#import "LocalHostsController.h"


@implementation HostsListViewMenu

- (id)initWithHosts:(Hosts*)hosts
{
	self = [self init];
	[self setAutoenablesItems:NO];
	
	HostsMainController *controller = [HostsMainController defaultInstance];
	NSMenuItem *item;
	
	if (![hosts saved]) {
		item = [[NSMenuItem alloc] initWithTitle:@"Save" action:@selector(save:) keyEquivalent:@""];
		[item setRepresentedObject:hosts];
		[item setTarget:controller];
		[self addItem:item];
	}
	
	if (![hosts active]) {
		item = [[NSMenuItem alloc] initWithTitle:@"Activate" action:@selector(activate:) keyEquivalent:@""];
		[item setRepresentedObject:hosts];
		[item setEnabled:[hosts exists]];
		[item setTarget:controller];
		[self addItem:item];
	}
	
	item = [[NSMenuItem alloc] initWithTitle:@"Show In Finder" action:@selector(showInFinder:) keyEquivalent:@""];
	[item setRepresentedObject:hosts];
	[item setTarget:self];
	[item setEnabled:[hosts exists]];
	[self addItem:item];
	
	if ([controller canRemoveFiles]) {
		item = [[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(remove:) keyEquivalent:@""];
		[item setRepresentedObject:hosts];
		[item setTarget:controller];
		[self addItem:item];
	}
	
	if ([hosts isMemberOfClass:[RemoteHosts class]]) {
		[self addItem:[NSMenuItem separatorItem]];
		
		item = [[NSMenuItem alloc] initWithTitle:@"Move to Local" action:@selector(moveToLocal:) keyEquivalent:@""];
		[item setRepresentedObject:hosts];
		[item setTarget:self];
		[item setEnabled:[hosts exists]];
		[self addItem:item];

		[self addItem:[NSMenuItem separatorItem]];
		
		item = [[NSMenuItem alloc] initWithTitle:@"Open in Browser" action:@selector(openInBrowser:) keyEquivalent:@""];
		[item setRepresentedObject:hosts];
		[item setTarget:self];
		[self addItem:item];
	}
	
	return self;
}

- (IBAction)openInBrowser:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[[sender representedObject] url]];
}

- (IBAction)showInFinder:(id)sender
{
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSString *path = [[sender representedObject] path];
	[workspace selectFile: path inFileViewerRootedAtPath:nil];
}

- (IBAction)moveToLocal:(id)sender
{
	[[HostsMainController defaultInstance] move:[sender representedObject] toControllerClass:[LocalHostsController class]];
}

@end
