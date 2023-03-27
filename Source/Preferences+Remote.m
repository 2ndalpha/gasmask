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

#import "Preferences+Remote.h"


@implementation Preferences (Remote)

+ (NSDictionary*)remoteHostsFilesProperties
{
	NSObject *object = [[[self instance] defaults] objectForKey:RemoteHostsFilesPrefKey];
	if (object == nil) {
		return [NSDictionary new];
	}
	
	return (NSDictionary*)object;
}

+ (void)setRemoteHostsFilesProperties:(NSDictionary*)properties
{
	[[[self instance] defaults] setObject:properties forKey:RemoteHostsFilesPrefKey];
}

+ (NSUInteger)remoteHostsUpdateInterval
{
	return [[[self instance] defaults] integerForKey:RemoteHostsUpdateIntervalPrefKey];
}

+ (void)setRemoteHostsUpdateInterval:(int)interval
{
	[[[self instance] defaults] setInteger:interval forKey:RemoteHostsUpdateIntervalPrefKey];
}

@end
