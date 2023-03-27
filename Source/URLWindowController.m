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

#import "URLWindowController.h"
#import "HostsMainController.h"
#import "RemoteHosts.h"
#import "RemoteHostsController.h"
#import "Network.h"

@implementation URLWindowController

@synthesize canAdd;

- (id)init
{
	self = [super init];
	
    [[NSBundle mainBundle] loadNibNamed:@"URLSheet" owner:self topLevelObjects:nil];
	
	[warningLabel bind:@"hidden" toObject:[Network defaultInstance] withKeyPath:@"online" options:nil];
	[warningImage bind:@"hidden" toObject:[Network defaultInstance] withKeyPath:@"online" options:nil];
	
	return self;
}

- (NSWindow*)window
{
	return window;
}

- (IBAction)cancel:(id)sender
{
	[window orderOut:self];
    [NSApp endSheet:window];
}

- (IBAction)add:(id)sender
{
	[window orderOut:self];
    [NSApp endSheet:window];
	
	NSURL *url = [NSURL URLWithString:[urlField stringValue]];
	
	if ([[HostsMainController defaultInstance] hostsFileWithURLExists:url]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Unable to Add"];
        [alert setInformativeText:@"Hosts file with specified URL already exists."];
		[alert runModal];
	}
	else {
		[[HostsMainController defaultInstance] createHostsFromURL:[NSURL URLWithString:[urlField stringValue]] forControllerClass:[RemoteHostsController class]];
	}
	
}

#pragma mark - NSTextField Delegate

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSString *rawUrl = [urlField stringValue];
	NSURL *url = [NSURL URLWithString:rawUrl];
	BOOL urlIsValid = ([rawUrl hasPrefix:@"http://"] || [rawUrl hasPrefix:@"https://"]) && url != nil;
	
	if (urlIsValid != canAdd) {
		[self willChangeValueForKey:@"canAdd"];
		canAdd = urlIsValid;
		[self didChangeValueForKey:@"canAdd"];
	}
}

@end
