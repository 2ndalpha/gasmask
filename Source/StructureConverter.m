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

#import "StructureConverter.h"
#import "PrivilegedActions.h"
#import "FileUtil.h"
#import "Preferences.h"

#define Version04DataDirectory @"/etc/gasmask/"
#define HostsOriginalLocation @"/etc/hosts"

@interface StructureConverter(Private)
- (BOOL)isVersion04Structure;
- (BOOL)isOriginalStructure;
- (void)restoreOriginalHostsFile;
- (void)remove04DataDirectory;
- (void)copy04FilesToDataDirectory;
- (void)createDataFolders;
- (void)createDataFolder:(NSString*)path;
- (void)copyOriginalHostsFileToDataDirectory;
@end

@implementation StructureConverter

- (id)init
{
	self = [super init];
	return self;
}

- (void)convertToCurrent
{
	BOOL originalStructure = [self isOriginalStructure];
	
	[self createDataFolders];
	
	if ([self isVersion04Structure]) {
		logDebug(@"Has version 0.4 structure");
		
		[PrivilegedActions authorizeWithPrompt:@"Gas Mask needs to convert data from version 0.4.\n"];
		
		if (![PrivilegedActions authorized]) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Unable to Convert From Version 0.4"];
            [alert setInformativeText:@"Gas Mask is unable to convert data from version 0.4 without root privileges. Gas Mask is closing."];
			[alert runModal];
			[[NSApplication sharedApplication] terminate:self];
		}
		
		[self restoreOriginalHostsFile];
		[self copy04FilesToDataDirectory];
		[self remove04DataDirectory];
	}
	else if (originalStructure) {
		logDebug(@"Original structure");
		[self copyOriginalHostsFileToDataDirectory];
	}
}

@end

@implementation StructureConverter(Private)

- (BOOL)isVersion04Structure
{
	NSFileManager *manager = [NSFileManager defaultManager];
	return [manager fileExistsAtPath:Version04DataDirectory];
}

- (BOOL)isOriginalStructure
{
	NSFileManager *manager = [NSFileManager defaultManager];
	return ![manager fileExistsAtPath:[FileUtil dataDirectory]];
}

- (void)restoreOriginalHostsFile
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *source = [manager destinationOfSymbolicLinkAtPath:HostsOriginalLocation error:nil];
	
	if (source == nil) {
		[self copyOriginalHostsFileToDataDirectory];
	}
	else {
		[PrivilegedActions removeFile:HostsOriginalLocation];
		[PrivilegedActions copyFile:source to:HostsOriginalLocation];
	}
}

- (void)remove04DataDirectory
{
	[PrivilegedActions removeFile:Version04DataDirectory];
}

- (void)copy04FilesToDataDirectory
{
	NSDirectoryEnumerator *enumerator  = [[NSFileManager defaultManager] enumeratorAtPath: Version04DataDirectory];
	NSString *file;
	NSFileManager *manager = [NSFileManager defaultManager];
	
	while (file = [enumerator nextObject]) {
		logDebug(@"File: %@", file);
		NSString *source = [Version04DataDirectory stringByAppendingString:file];
		NSString *destination = [[FileUtil localHostFilesDirectory] stringByAppendingString:file];
		destination = [destination stringByAppendingPathExtension:HostsFileExtension];

		[manager copyItemAtPath:source toPath:destination error:nil];
	}
}

- (void)createDataFolders
{	
	[self createDataFolder:[FileUtil localHostFilesDirectory]];
	[self createDataFolder:[FileUtil remoteHostFilesDirectory]];
    [self createDataFolder:[FileUtil combinedHostsFilesDirectory]];
}

- (void)createDataFolder:(NSString*)path
{
	NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:path]) {
		logDebug(@"Creating directory \"%@\"", path);
		[manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
	}
}

- (void)copyOriginalHostsFileToDataDirectory
{
	NSMutableString *destination = [NSMutableString new];
	[destination appendString:[FileUtil localHostFilesDirectory]];
	[destination appendString:@"Original File."];
	[destination appendString:HostsFileExtension];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager copyItemAtPath:HostsOriginalLocation toPath:destination error:nil];
	
	[Preferences setActiveHostsFile:destination];
}

@end
