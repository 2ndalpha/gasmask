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

#import "CombinedHostsController.h"
#import "CombinedHosts.h"
#import "FileUtil.h"
#import "Preferences.h"

#define kDefaultCombinedHostsFileName @"Combined Hosts File"

@interface CombinedHostsController (Private)

- (NSString*)constructPath:(NSString*)name;
- (NSArray*)hostsFilesContaining:(Hosts*)hosts;
- (IBAction)hostsFileRemoved:(NSNotification *)notification;
- (IBAction)hostsFileRenamed:(NSNotification *)notification;
- (IBAction)hostsFileSaved:(NSNotification *)notification;

@end

@implementation CombinedHostsController

-(id)init
{
    self = [super init];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(hostsFileRemoved:) name:HostsFileRemovedNotification object:nil];
    [nc addObserver:self selector:@selector(hostsFileRenamed:) name:HostsFileRenamedNotification object:nil];
    [nc addObserver:self selector:@selector(hostsFileSaved:) name:HostsFileSavedNotification object:nil];
    
    return self;
}

- (void)loadFiles
{
	logDebug(@"Loading combined hosts");
    
    NSString *activeHostsFilePath = [Preferences activeHostsFile];
    NSArray *allHostsFiles = [[HostsMainController defaultInstance] allHostsFiles];
	
	NSDirectoryEnumerator *enumerator  = [[NSFileManager defaultManager] enumeratorAtPath:  [FileUtil combinedHostsFilesDirectory]];
	NSString *file;
	while (file = [enumerator nextObject]) {
		if ([[file pathExtension] isEqualTo:HostsFileExtension]) {
			
            NSString *path = [[FileUtil combinedHostsFilesDirectory] stringByAppendingString:file];
			Hosts *hosts = [[CombinedHosts alloc] initWithPath: path allHostsFiles:allHostsFiles];
			
			logDebug(@"Loaded file: \"%@\"", file);
			
			if ([activeHostsFilePath isEqualTo:[hosts path]]) {
				[hosts setActive:YES];
			}
			
			[hostsFiles addObject:hosts];
		}
	}
}

- (NSString*) name
{
	return @"Combined";
}

- (NSString *)groupName
{
	return @"COMBINED";
}

- (Hosts*)createNewHostsFile
{
    Hosts *hosts = [[CombinedHosts alloc] initWithPath: [self constructPath:[self generateName:kDefaultCombinedHostsFileName]]];
    [hosts setEditable:NO];
    [hosts save];
	
	[hostsFiles addObject:hosts];
	
	return hosts;
}

@end

@implementation CombinedHostsController (Private)

- (NSString*)constructPath:(NSString*)name
{
	return [self constructPath:[FileUtil combinedHostsFilesDirectory] withName:name];
}

- (NSArray*)hostsFilesContaining:(Hosts*)hosts
{
    NSMutableArray *result = [NSMutableArray new];
    
    for (CombinedHosts *combinedHosts in hostsFiles) {
        for (Hosts *innerHosts in [combinedHosts hostsFiles]) {
            if ([hosts isEqualTo:innerHosts]) {
                [result addObject:combinedHosts];
            }
        }
    }
    
    return result;
}

- (IBAction)hostsFileRemoved:(NSNotification *)notification
{
    Hosts *removedHosts = [notification object];
    
    for (CombinedHosts *hosts in [self hostsFilesContaining:removedHosts]) {
        logDebug(@"Hosts file \"%@\" removed from combined hosts file \"%@\"", [removedHosts name], [hosts name]);
        [hosts removeHostsFile:removedHosts];
        [hosts save];
    }
}

- (IBAction)hostsFileRenamed:(NSNotification *)notification
{
    Hosts *renamedHosts = [notification object];
    
    for (CombinedHosts *hosts in [self hostsFilesContaining:renamedHosts]) {
        logDebug(@"Hosts file \"%@\" renamed in combined hosts file \"%@\"", [renamedHosts name], [hosts name]);
        [hosts hostsFileRenamed:renamedHosts];
        [hosts save];
    }
}

- (IBAction)hostsFileSaved:(NSNotification *)notification
{
    Hosts *savedHosts = [notification object];
    for (CombinedHosts *hosts in [self hostsFilesContaining:savedHosts]) {
        logDebug(@"Hosts file \"%@\" saved in combined hosts file \"%@\"", [savedHosts name], [hosts name]);
        [hosts hostsFileSaved:savedHosts];
        [hosts save];
        
        if ([hosts active]) {
            [self saveHostsFileToOriginalLocation:hosts];
        }
    }
}

@end
