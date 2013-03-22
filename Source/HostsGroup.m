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

#import "HostsGroup.h"


@implementation HostsGroup

- (id)initWithName:(NSString*)groupName
{
	self = [super init];
	name = groupName;
	online = YES;
	synchronizing = NO;
	selectable = NO;
	[self setIsGroup:YES];
	[self setLeaf:NO];
	
	return self;
}

- (NSString*)description
{
	return name;
}

- (BOOL)synchronizing
{
	return synchronizing;
}

- (void)setSynchronizing:(BOOL)newSynchronizingValue
{
	if (synchronizing != newSynchronizingValue) {
		synchronizing = newSynchronizingValue;
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:SynchronizingStatusChangedNotification object:self];
	}
}

- (NSString*) name
{
	return name;
}

- (BOOL)online
{
	return online;
}

- (void)setOnline:(BOOL)newOnlineValue
{
	if (online != newOnlineValue) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:HostsNodeNeedsUpdateNotification object:self];
		online = newOnlineValue;
	}
}

@end
