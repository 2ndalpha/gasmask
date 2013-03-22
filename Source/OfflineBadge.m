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

#import "OfflineBadge.h"
#import "InfoBubble.h"
#import "ListController.h"
#import "Hosts.h"


@implementation OfflineBadge

- (id)initWithHosts:(Hosts*)hostsValue
{
	self = [super init];
	icon = [NSImage imageNamed: @"Offline.png"];
	rolloverIcon = [NSImage imageNamed: @"Offline_rollover.png"];
	hosts = hostsValue;

	[self addTrackingArea:[[NSTrackingArea alloc] initWithRect:[self frame]
													    options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
														  owner:self
													   userInfo:nil]];
	
	[self setActiveIcon:icon];
	
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
	InfoBubble *infoBubble = [InfoBubble new];
	[infoBubble setTitle:@"No Internet connection"];
	[infoBubble setDescription:@"Can't update hosts files because you are not connected to the Internet."];
	[[ListController defaultInstance] showInfoBubble:infoBubble forHosts:hosts];
}

@end
