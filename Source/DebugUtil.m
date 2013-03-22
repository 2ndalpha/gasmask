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

#import "DebugUtil.h"

#include <mach/mach.h>
#include <mach/mach_time.h>

double machTimerMillisMult = -1;

@implementation DebugUtil

+ (uint64_t)startTimer
{	
	return mach_absolute_time();
}

+ (void)endTimerAndLog:(uint64_t)startTime
{
	uint64_t endTime = mach_absolute_time();

	if (machTimerMillisMult == -1) {
		mach_timebase_info_data_t info;
		mach_timebase_info(&info);
		machTimerMillisMult = (double)info.numer / ((double)info.denom * 1000000.0);
	}
	
	logDebug(@"Time: %f ms", (endTime - startTime) * machTimerMillisMult);
}

@end
