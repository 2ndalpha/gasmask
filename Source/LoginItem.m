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


@interface LoginItem (Private)
-(void) enable;
-(void) disable;
-(LSSharedFileListRef) loginItems;
-(CFURLRef) url;
-(LSSharedFileListItemRef) itemRef;
@end 

@implementation LoginItem

-(BOOL) enabled
{
	return [self itemRef] != nil;
}

-(void) setEnabled:(BOOL)enable
{
	if (enable) {
		[self enable];
	}
	else {
		[self disable];
	}
}

@end

@implementation LoginItem (Private)

-(void) enable
{
	logDebug(@"URL: %@", [self url]);
	LSSharedFileListInsertItemURL([self loginItems],
								  kLSSharedFileListItemLast,
								  (CFStringRef)@"Gas Mask",
								  NULL,
								  [self url],
								  NULL,
								  NULL);
}

-(void) disable
{
	LSSharedFileListItemRef itemRef = [self itemRef];
	if (itemRef != nil) {
		LSSharedFileListItemRemove([self loginItems], itemRef);
	}
}

-(LSSharedFileListRef) loginItems
{
	return LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
}

-(CFURLRef) url
{
	NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/Launcher.app"];
	return (__bridge CFURLRef)[NSURL fileURLWithPath:path];
}

-(LSSharedFileListItemRef) itemRef
{
	UInt32 seedValue;
	NSArray *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot([self loginItems], &seedValue);
	NSURL *bundleUrl = (NSURL *)[self url];
	LSSharedFileListItemRef result = nil;
	
	for (id item in loginItemsArray) {
		LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)item;
		CFURLRef url;
		
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
			if ([[(__bridge NSURL *)url path] isEqualToString: [bundleUrl path]]) {
				result = itemRef;
				break;
			}
		}
	}
	
	return result;
}

@end
