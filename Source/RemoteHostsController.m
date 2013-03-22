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

#import "RemoteHostsController.h"
#import "Preferences.h"
#import "FileUtil.h"
#import "RemoteHosts.h"
#import "RemoteHostsManager.h"

@interface RemoteHostsController (Private)

- (NSString*)constructPath:(NSString*)name;

@end

@implementation RemoteHostsController

- (id)init
{
	self = [super init];
	
	manager = [[RemoteHostsManager alloc] initWithHostsController:self];
	
	[self enableGroupOfflineBadge];
	
	return self;
}

- (NSString*) name
{
	return @"Remote";
}

- (NSString *)groupName
{
	return @"REMOTE";
}

- (void)loadFiles
{
	logDebug(@"Loading remote hosts");
	
	NSString *activeHostsFilePath = [Preferences activeHostsFile];
	
	NSDirectoryEnumerator *enumerator  = [[NSFileManager defaultManager] enumeratorAtPath:  [FileUtil remoteHostFilesDirectory]];
	NSString *file;
	while (file = [enumerator nextObject]) {
		if ([[file pathExtension] isEqualTo:HostsFileExtension]) {
			
			RemoteHosts *hosts = [[RemoteHosts alloc] initWithPath: [[FileUtil remoteHostFilesDirectory] stringByAppendingString:file]];
			if ([activeHostsFilePath isEqualTo:[hosts path]]) {
				[hosts setActive:YES];
			}
			
			[hostsFiles addObject:hosts];
		}
	}
	
	[manager loadRemoteHostsProperties];
	[manager startUpdater];
}

- (BOOL)hostsFileWithURLExists:(NSURL*)url
{
	for (RemoteHosts *hosts in hostsFiles) {
		if ([[hosts url] isEqual:url]) {
			return YES;
		}
	}
	return NO;
}

- (Hosts*)createHostsFromURL:(NSURL*)url
{
	if ([self hostsFileWithURLExists:url]) {
		return nil;
	}
	
	NSString *name = [self generateName:[url host]];
	
	RemoteHosts *hosts = [[RemoteHosts alloc] initWithPath: [self constructPath:name]];
	[hosts setUrl:url];
	[hosts setEnabled:NO];
	[hosts setExists:NO];
	
	[hostsFiles addObject:hosts];
	
	[manager initializeHosts:hosts url:[hosts url]];
	
	return hosts;
}

- (BOOL)canCreateHostsFromURL:(NSURL*)url
{
	for (int i=0; i<[[self hostsFiles] count]; i++) {
		RemoteHosts *hosts = [[self hostsFiles] objectAtIndex:i];
		if ([[hosts url] isEqual:url]) {
			return NO;
		}
	}
	
	return YES;
}

@end

@implementation RemoteHostsController (Private)

- (NSString*)constructPath:(NSString*)name
{
	return [self constructPath:[FileUtil remoteHostFilesDirectory] withName:name];
}

@end
