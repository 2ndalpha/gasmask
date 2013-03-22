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

#import "BadgeManager.h"
#import "Badge.h"
#import "Map.h"

@interface BadgeManager (Private)

- (id)initWithCreator:(SEL)creator target:(id)t;

@end


@implementation BadgeManager

+ (id)badgeManagerWithCreator:(SEL)creator target:(id)t
{
	return [[self alloc] initWithCreator:creator target:t];
}

- (Badge*)getBadgeForObject:(id)object
{
	Badge *badge;
	if ([badges haveObjectForKey:object]) {
		badge = (Badge*)[badges objectForKey:object];
	}
	else {
		SuppressPerformSelectorLeakWarning(badge = [target performSelector:action]);
		[badges addObject:badge forKey:object];
	}
	
	return badge;
}

- (void)removeBadgeForObject:(id)object
{
	if ([badges haveObjectForKey:object]) {
		Badge *badge = (Badge*)[badges objectForKey:object];
		[badge removeFromSuperview];
		[badges removeObjectForKey:object];
	}
}

@end

@implementation BadgeManager (Private)

- (id)initWithCreator:(SEL)creator target:(id)t
{
	self = [super init];
	action = creator;
	target = t;
	badges = [Map new];
	
	return self;
	
}

@end

