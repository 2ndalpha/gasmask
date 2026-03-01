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

#import "Util.h"


@implementation Util

+ (void) flushDirectoryServiceCache
{
	logDebug(@"Flushing Directory Service Cache");
	NSTask *task = [[NSTask alloc] init];
	task.launchPath = @"/usr/bin/dscacheutil";
	task.arguments = @[@"-flushcache"];
	task.terminationHandler = ^(NSTask *t) {
		if (t.terminationStatus != 0) {
			logDebug(@"dscacheutil failed with status %d", t.terminationStatus);
		}
	};
	[task launch];
}

+ (BOOL) isPre10_10
{
    return ( NSAppKitVersionNumber < NSAppKitVersionNumber10_10 );
}
@end