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

#import "Hotkey.h"

@implementation Hotkey

@synthesize keyCode;
@synthesize modifiers;

- (id)initWithKeyCode: (int)mKeyCode modifiers: (int)mModifiers;
{
	self = [super init];
	keyCode = mKeyCode;
	modifiers = mModifiers;
	return self;
}

- (id)initWithPlistRepresentation: (id)plist
{
	self = [super init];
	
	if(!plist || ![plist count]) {
		keyCode = -1;
		modifiers = -1;
	}
	else {
		keyCode = [[plist objectForKey: @"keyCode"] intValue];
		if(keyCode <= 0) {
			keyCode = -1;
		}
		
		modifiers = [[plist objectForKey: @"modifiers"] intValue];
		if(modifiers <= 0) {
			modifiers = -1;
		}
	}
	
	return self;
}

- (id)plistRepresentation
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt: keyCode], @"keyCode",
			[NSNumber numberWithInt: modifiers], @"modifiers",
			nil];
}

@end
