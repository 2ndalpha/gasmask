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

#import "LocalHostsController.h"
#import "LocalHostsManager.h"
#import "Preferences.h"
#import "FileUtil.h"

#define kDefaultHostsFileName @"Hosts File"
#define kHostsDefaultFile @"default.hst"

@interface LocalHostsController (Private)

- (NSString*)constructPath:(NSString*)name;
- (NSString*)defaultHostsContents;

@end



@implementation LocalHostsController

- (id)init
{
	self = [super init];
	
	manager = [[LocalHostsManager alloc] initWithHostsController:self];
	
	return self;
}

- (NSString*) name
{
	return @"Local";
}

- (NSString *)groupName
{
	return @"LOCAL";
}

- (void)loadFiles
{
	logDebug(@"Loading local hosts");
	
	NSString *activeHostsFilePath = [Preferences activeHostsFile];
	
	NSDirectoryEnumerator *enumerator  = [[NSFileManager defaultManager] enumeratorAtPath:  [FileUtil localHostFilesDirectory]];
	NSString *file;
	while (file = [enumerator nextObject]) {
		if ([[file pathExtension] isEqualTo:HostsFileExtension]) {
			
			Hosts *hosts = [[Hosts alloc] initWithPath: [[FileUtil localHostFilesDirectory] stringByAppendingString:file]];
			
			logDebug(@"Loaded file: \"%@\"", file);
			
			if ([activeHostsFilePath isEqualTo:[hosts path]]) {
				[hosts setActive:YES];
			}
			
			[hostsFiles addObject:hosts];
            		// grossly sorting array every time we add a host?  Probably there is a better way.
            		NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
            		[hostsFiles sortUsingDescriptors:[NSArray arrayWithObject:sort]];
		}
	}
}

- (Hosts*)createNewHostsFile
{
	return [self createNewHostsFileWithContents:[self defaultHostsContents]];
}

- (Hosts*)createNewHostsFileWithContents:(NSString*)contents
{
	Hosts *hosts = [[Hosts alloc] initWithPath: [self constructPath:[self generateName:kDefaultHostsFileName]]];
	[hosts setContents:contents];
	[hosts save];
	
	[hostsFiles addObject:hosts];
	
	return hosts;
}

- (Hosts*)createHostsFileWithName:(NSString*)name contents:(NSString*)contents
{
	Hosts *hosts = [[Hosts alloc] initWithPath: [self constructPath:[self generateName:name]]];
	[hosts setContents:contents];
	[hosts save];
	
	[hostsFiles addObject:hosts];
	
	return hosts;	
}

- (Hosts*)createHostsFromURL:(NSURL*)url
{
	NSString *name = [self generateName:[url host]];
	Hosts *hosts = [[Hosts alloc] initWithPath: [self constructPath:name]];
	[hosts setEnabled:NO];
	[hosts setEditable:NO];
	[hosts setExists:NO];
	
	[hostsFiles addObject:hosts];
	
	[manager initializeHosts:hosts url:url];
	
	return hosts;
}

- (BOOL)canCreateHostsFromLocalURL:(NSURL*)url
{
	for (int i=0; i<[[self hostsFiles] count]; i++) {
		Hosts *hosts = [[self hostsFiles] objectAtIndex:i];
		NSURL *hostsURL = [NSURL fileURLWithPath:[hosts path]];
		if ([hostsURL isEqual:url]) {
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)canCreateHostsFromURL:(NSURL*)url
{
	return YES;
}

- (Hosts*)createHostsFromLocalURL:(NSURL*)url
{
	NSString *baseName = [[url lastPathComponent] stringByDeletingPathExtension];
	NSString *name = [self generateName:baseName];
	
	Hosts *hosts = [[Hosts alloc] initWithPath: [self constructPath:name]];
	NSString *contents = contents = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
	[hosts setContents:contents];
	[hosts save];
	
	[hostsFiles addObject:hosts];
	
	return hosts;		
}

@end

@implementation LocalHostsController (Private)

- (NSString*)constructPath:(NSString*)name
{
	return [self constructPath:[FileUtil localHostFilesDirectory] withName:name];
}

- (NSString*)defaultHostsContents
{
	NSString *path = [[NSBundle mainBundle] pathForResource:kHostsDefaultFile ofType:nil];
	return [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error:NULL];
}

@end

