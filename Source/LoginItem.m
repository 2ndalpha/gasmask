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

#import "LoginItem.h"

#import <ServiceManagement/ServiceManagement.h>

@implementation LoginItem

-(BOOL) enabled
{
	return [SMAppService mainAppService].status == SMAppServiceStatusEnabled;
}

-(void) setEnabled:(BOOL)enable
{
	NSError *error = nil;
	if (enable) {
		[[SMAppService mainAppService] registerAndReturnError:&error];
		if (error) {
			logDebug(@"Failed to register login item: %@", error);
		}
	} else {
		[[SMAppService mainAppService] unregisterAndReturnError:&error];
		if (error) {
			logDebug(@"Failed to unregister login item: %@", error);
		}
	}
}

@end
