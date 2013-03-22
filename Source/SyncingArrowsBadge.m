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

#import "SyncingArrowsBadge.h"


@implementation SyncingArrowsBadge

- (id)init
{
	self = [super init];
	
	images = [[NSArray alloc] initWithObjects:
				 [NSImage imageNamed: @"Syncing_arrows1.png"],
				 [NSImage imageNamed: @"Syncing_arrows2.png"],
				 [NSImage imageNamed: @"Syncing_arrows3.png"],
				 [NSImage imageNamed: @"Syncing_arrows4.png"],
				 [NSImage imageNamed: @"Syncing_arrows5.png"],
				 [NSImage imageNamed: @"Syncing_arrows6.png"],
				 nil];
	
	return self;
}

- (void)start
{
	timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).09 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
}

- (void)updateImage
{
	if (index < 5) {
		index++;
	}
	else {
		index = 0;
	}
	[self setActiveIcon:[images objectAtIndex:index]];
}

@end
