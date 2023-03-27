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
#import "NSImage+Additions.h"
#import "Util.h"


@implementation SyncingArrowsBadge

- (id)init
{
	self = [super init];
	return self;
}

- (void)start
{
	timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval).03 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
}

- (void)updateImage
{
    NSImage *img = [NSImage imageWithSystemSymbolName:@"arrow.triangle.2.circlepath" accessibilityDescription:@"Syncing Arrow"];

    //rotate clockwise, so we continuously count down from 360 to 0 degrees
    NSUInteger rotation = 360 - 4*i;
    if (rotation == 0) {
        i = 0;
    }
    else {
        i++;
    }
    
    [img rotate:rotation];
	[self setActiveIcon:img];
}

@end
