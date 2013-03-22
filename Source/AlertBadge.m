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

#import "AlertBadge.h"
#import "Error.h"
#import "InfoBubble.h"
#import "RemoteHosts.h"
#import "ListController.h"


@implementation AlertBadge

- (id) initWithRemoteHosts:(RemoteHosts*)remoteHosts
{
	self = [super init];
	
	[self addTrackingArea:[[NSTrackingArea alloc] initWithRect:[self frame]
													    options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
														  owner:self
													   userInfo:nil]];

	icon = [NSImage imageNamed: @"Alert.png"];
	rolloverIcon = [NSImage imageNamed: @"Alert_rollover.png"];
	
	[self setActiveIcon:icon];
	
	hosts = remoteHosts;
	
	return self;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[self setActiveIcon:rolloverIcon];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[self setActiveIcon:icon];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSString *title;
	
	Error *error = [hosts error];
	switch ([error type]) {
		case NetworkOffline:
			title = @"No Internet connection";
			break;
		case FileNotFound:
			title = @"Hosts file not found";
			break;
		case ServerNotFound:
			title = @"Server not found";
			break;
		case BadContentType:
			title = @"Bad content";
			break;
		case InvalidMobileMeAccount:
			title = @"Invalid Mobile Me account";
			break;
		default:
			title = @"Warning";
			break;
	}
	
    infoBubble = [InfoBubble new];
	[infoBubble setTitle:title];
	if ([error description]) {
		[infoBubble setDescription:[error description]];
	}
	if ([error url]) {
		[infoBubble setURL:[error url]];
    }
	[[ListController defaultInstance] showInfoBubble:infoBubble forHosts:hosts];
}
	
@end
