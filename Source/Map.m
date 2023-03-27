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

#import "Map.h"

// TODO: Remove and use NSDictionary


@implementation Map

- (id)init
{
	self = [super init];
	keys = [NSMutableArray new];
	objects = [NSMutableArray new];
	
	return self;
}

- (void)addObject:(NSObject*)object forKey:(NSObject*)key;
{
	[keys addObject:key];
	[objects addObject:object];
}

- (BOOL)haveObjectForKey:(NSObject*)key
{
	NSEnumerator *enumerator = [keys objectEnumerator];
	NSObject *keyInArray;
	while (keyInArray = [enumerator nextObject]) {
		if ([keyInArray isEqual:key]) {
			return YES;
		}
	}
	return NO;
}

- (NSObject*)objectForKey:(NSObject*)key
{
	for (int i=0; i<[keys count]; i++) {
		if ([key isEqual:[keys objectAtIndex:i]]) {
			return [objects objectAtIndex:i];
		}
	}
	return nil;
}

- (void)removeObjectForKey:(NSObject*)key
{
	[objects removeObjectIdenticalTo:[self objectForKey:key]];
	[keys removeObjectIdenticalTo:key];
}

@end
