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

+ (BOOL) flushDirectoryServiceCache
{
	logDebug(@"Flushing Directory Service Cache");
	NSArray *arguments = [NSArray arrayWithObject:@"-flushcache"];
	NSTask * task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/dscacheutil" arguments:arguments];
	[task waitUntilExit];
	return [task terminationStatus] == 0;
}

+ (BOOL) restartDNSResponder
{
    logDebug(@"Restarting mDNSResponder");
    __block BOOL completed;
    
    NSURL* scriptURL = [[NSBundle mainBundle] URLForResource:@"RestartDNSResponder" withExtension:@"scpt"];
    NSError* error;
    NSUserAppleScriptTask* task = [[NSUserAppleScriptTask alloc] initWithURL:scriptURL error:&error];
        [task executeWithAppleEvent:nil completionHandler:^(NSAppleEventDescriptor *result, NSError *error) {
            if (task) {
                completed = YES;
                logDebug(@"Restarted mDNSResponder");
            } else {
                completed = NO;
                logDebug(@"Restarting mDNSResponder failed");
            }
        }];
    
    return completed;
}

+ (BOOL) isDarkMode
{
    NSAppearance *appearance = NSAppearance.currentAppearance;
    return appearance.name == NSAppearanceNameDarkAqua;
}

@end
