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

#import "ExtendedNSString.h"
#import "IP.h"

#define kSpecialLocalhostPrefix @"fe80::1%"
#define kUnicharZeroLocation 48

@interface IP ()
-(NSRange) invalidVersion4Range:(NSRange)ipRange;
-(NSRange) invalidVersion6Range:(NSRange)ipRange;
@end

@implementation IP


@synthesize isVersion4;
@synthesize isVersion6;
@synthesize invalidRange;

-(id) initWithString:(NSString*)string
{
	self = [super init];
	contents = string;
	
	return self;
}

-(void) setRange:(NSRange)range
{
	isVersion4 = NO;
	isVersion6 = NO;
	invalidRange = [self invalidVersion4Range:range];
	
	if (!isVersion4) {
		invalidRange = [self invalidVersion6Range:range];
	}	
}

-(BOOL) isValid
{
	return invalidRange.length == 0;
}

/*
 This method is optimized for speed, no NSStrings are created and no
 methods are called. This code could be difficult to follow.
 */
-(NSRange) invalidVersion4Range:(NSRange)ipRange
{
	NSRange fullRange = NSMakeRange(0, ipRange.length);
	
	if (ipRange.length > 15 || ipRange.length < 6) {
		return fullRange;
	}
	
	NSCharacterSet *validCharacters = [NSCharacterSet decimalDigitCharacterSet];
	
	int groups = 0;
	BOOL groupContainsInvalidCharacters = NO;
	int groupValue = 0;
	int lastSeparatorLocation = ipRange.location-1;
	int end = NSMaxRange(ipRange);
	int difference;
	
	for (int i=ipRange.location; i<end; i++) {
		unichar characher = [contents characterAtIndex:i];
		
		if (characher == '.' || i == end-1) {
			// Empty group
			if (i != end-1 && lastSeparatorLocation == i-1) {
				return fullRange;
			}
			
			// Last characher can't be dot
			if (characher == '.' && i == end-1) {
				return fullRange;
			}
			
			groups++;
			if (groups > 4) {
				return fullRange;
			}
			
			// Last characher
			if (i == end-1) {
				if (![validCharacters characterIsMember:characher] || i-lastSeparatorLocation > 3) {
					groupContainsInvalidCharacters = YES;
				}
				else if (i-lastSeparatorLocation == 3) {
					groupValue += (int)characher-kUnicharZeroLocation;
					if (groupValue > 256) {
						groupContainsInvalidCharacters = YES;
					}
				}
			}
			
			difference = i-lastSeparatorLocation;
			if (groupContainsInvalidCharacters || difference > 4) {
				int length;
				if (i == end-1) {
					length = difference;
				}
				else {
					length = difference-1;
				}
				return NSMakeRange(lastSeparatorLocation-ipRange.location+1, length);
			}
			
			lastSeparatorLocation = i;
			groupValue = 0;
		}
		else if (![validCharacters characterIsMember:characher]) {
			groupContainsInvalidCharacters = YES;
		}
		// Calculate value of the group
		else if (i-lastSeparatorLocation <= 3) {
			int multiplier = 1;
			int position = i-lastSeparatorLocation;
			if (position == 1) {
				multiplier = 100;
			} else if (position == 2) {
				multiplier = 10;
			}
			int number = (int)characher-kUnicharZeroLocation;
			
			groupValue += number*multiplier;
			if (i-lastSeparatorLocation == 3 && groupValue > 256) {
				groupContainsInvalidCharacters = YES;
			}
		}
	}
	
	if (groups != 4) {
		return fullRange;
	}
	
	isVersion4 = YES;
	return NSMakeRange(0, 0);
}

-(NSRange) invalidVersion6Range:(NSRange)ipRange
{
	NSString *ip = [contents substringWithRange:ipRange];
	int textLength = [ip length];
	
	NSRange fullRange = NSMakeRange(0, textLength);
	if (textLength > 39) {
		return fullRange;
	}
	
	if ([ip hasPrefix:kSpecialLocalhostPrefix]) {
		isVersion6 = YES;
		return NSMakeRange(0, 0);
	}
	
	NSArray *parts = [ip componentsSeparatedByString: @"::"];
	
	if ([parts count] > 2) {
		return fullRange;
	}
	
	NSRange range = NSMakeRange(0, 0);
	int groupsCount = 0;
	int pos = 0;
	
	for (NSString *part in parts) {
		NSArray *groups = [part componentsSeparatedByString: @":"];
		for (NSString *group in groups) {
			groupsCount++;
			
			if ((groupsCount > 7 && [parts count] != 1) || groupsCount > 8) {
				return fullRange;
			}
			
			int groupLength = [group length];
			if (![group holdsHexadecimalValue] || groupLength > 4) {
				if (range.length == 0) {
					range = NSMakeRange(pos, groupLength);
				}
				else {
					return fullRange;
				}
			}
			
			pos += groupLength+1;
		}
		
		pos++;
	}
	
	if ([parts count] == 1 && groupsCount != 8) {
		return fullRange;
	}
	
	isVersion6 = YES;
	return range;
}

@end
