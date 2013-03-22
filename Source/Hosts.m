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

#import "Hosts.h"
#import "FileUtil.h"

@interface Hosts (Private)
- (NSString*)readContentsFromDisk;
@end

@implementation Hosts

@synthesize path;
@synthesize editable;
@synthesize exists;

- (id)initWithPath:(NSString*)pathValue
{
	self = [super init];
	path = pathValue;
	active = NO;
	saved = YES;
	enabled = YES;
	editable = YES;
	exists = YES;
	return self;
}

-(NSString *)contents
{
	if (contents == nil) {
		logDebug(@"Loading contents for file \"%@\"", [self name]);
		contents = [self readContentsFromDisk];
	}
	if (contents == nil) {
		contents = @"";
	}
	return contents;
}

- (NSString*)contentsOnDisk
{
    return [self readContentsFromDisk];
}

-(void) setContents:(NSString*)newContentsValue
{
	[self setSaved:NO];
	if (newContentsValue == nil) {
		newContentsValue = @"";
	}
	contents = newContentsValue;
}

- (NSString*) name
{
	return [[path lastPathComponent] stringByDeletingPathExtension];
}

- (void)setName:(NSString*)name
{
	// Do nothing
}

- (NSString*)fileName
{
	return [path lastPathComponent];
}

- (void) setSaved: (BOOL) _saved
{
	if (saved == _saved) {
		return;
	}
	saved = _saved;
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:HostsNodeNeedsUpdateNotification object:self];
}

- (BOOL) saved
{
	return saved;
}

- (void) save
{
	[contents writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	[self setSaved:YES];
}

- (void) setActive:(BOOL) _active
{
	if (active == _active) {
		return;
	}
	active = _active;
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:HostsNodeNeedsUpdateNotification object:self];
}

- (BOOL) active
{
	return active;
}

- (BOOL)enabled
{
	return enabled;
}

- (void)setEnabled:(BOOL)_enabled
{
	if (enabled != _enabled) {
		enabled = _enabled;
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:HostsNodeNeedsUpdateNotification object:self];
	}
}

- (Error*)error
{
	return error;
}

- (void)setError:(Error*)newErrorValue
{
	if (error != newErrorValue) {
        error = newErrorValue;
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:HostsNodeNeedsUpdateNotification object:self];
	}
}


- (BOOL)selectable
{
	return [super selectable] && enabled;
}

- (NSString*)type
{
	return @"Local";
}

@end


@implementation Hosts (Private)

- (NSString*)readContentsFromDisk
{
    return [NSString stringWithContentsOfFile: [self path] encoding:NSUTF8StringEncoding error:NULL];
}

@end
