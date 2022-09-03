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

#import "Preferences.h"

@implementation Preferences

static Preferences *sharedInstance = nil;

+ (Preferences *)instance
{
	if (!sharedInstance) {
		sharedInstance = [self new];
	}
    
	return sharedInstance;
}

+(BOOL)showNameInStatusBar
{
    return [[[self instance] defaults] boolForKey:ShowNameInStatusBarKey];
}

+ (BOOL)overrideExternalModifications
{
    return [[[self instance] defaults] boolForKey:OverrideExternalModificationsPrefKey];
}

+ (void)setActiveHostsFile:(NSString *)path
{
	[[[self instance] defaults] setObject:path forKey:ActiveHostsFilePrefKey];
}

+ (NSString *)activeHostsFile
{
	return [[[self instance] defaults] stringForKey:ActiveHostsFilePrefKey];
}

+ (void)setShowEditorWindow:(BOOL)show
{
	[[[self instance] defaults] setBool:show forKey:ShowEditorWindowPrefKey];
}

+ (BOOL)showEditorWindow
{
	return [[[self instance] defaults] boolForKey:ShowEditorWindowPrefKey];
}

- (id)init {
    if (sharedInstance) {
        return sharedInstance;
    }
    if (self = [super init]) {
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
		[[NSUserDefaults standardUserDefaults] registerDefaults:dict];
		
		return self;
	}
    return sharedInstance;
}

@end
