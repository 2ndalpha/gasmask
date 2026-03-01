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

#import "HostsMainController.h"
#import "LocalHostsController.h"
#import "RemoteHostsController.h"
#import "CombinedHostsController.h"
#import "Pair.h"

#import "Hosts.h"
#import "HostsGroup.h"
#import "Preferences.h"

@interface HostsMainController (Private)

- (void)addGroups;
- (void)updateFilesCount;
- (NSObject<HostsControllerProtocol>*) hostsControllerForFile:(Hosts*)hosts;
- (NSIndexPath*)hostsIndexPath:(Hosts*)hosts;

- (Hosts*)previousHostsFile:(Hosts*)hosts;
- (Hosts*)nextHostsFile:(Hosts*)hosts;

/**
 Returns neighbour hosts file.
 Acts like <code>nextHostsFile</code>, except when
 hosts file is the last one, it returns previous hosts file.
 **/
- (Hosts*)neighbourHostsFile:(Hosts*)hosts;

- (void)addHostsFile:(Hosts*)hosts forController:(NSObject<HostsControllerProtocol>*)controller;

- (BOOL)createHostsFromURL:(NSURL*)url forController:(NSObject<HostsControllerProtocol>*)controller;

- (BOOL)createHostsFromLocalURL:(NSURL*)url forController:(NSObject<HostsControllerProtocol>*)controller;

- (NSObject<HostsControllerProtocol>*)hostsControllerForHostsGroup:(HostsGroup*)hostsGroup;

- (NSObject<HostsControllerProtocol>*)hostsControllerForControllerClass:(Class)controllerClass;

@end

@implementation HostsMainController

static VDKQueue* queue = nil;
static HostsMainController *sharedInstance = nil;

+ (HostsMainController*)defaultInstance
{
	return sharedInstance;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (!self || sharedInstance) {
        return self;
    }
    controllers = [NSArray arrayWithObjects:
                   [LocalHostsController new],
                   [RemoteHostsController new],
                   [CombinedHostsController new],
                   nil];

    for (int i=0; i<[controllers count]; i++) {
        [[controllers objectAtIndex:i] setDelegate:self];
    }

    queue = [[VDKQueue alloc] init];
    [queue setDelegate:self];
    [self startTrackingFileChanges];

    filesCount = 0;

    sharedInstance = self;

    return self;
}

- (id)awakeAfterUsingCoder:(NSCoder *)decoder
{
    if (sharedInstance && sharedInstance != self) {
        return sharedInstance;
    }
    return [super awakeAfterUsingCoder:decoder];
}

- (void)load
{
	[self addGroups];
	
	for (int i=0; i<[controllers count]; i++) {
		NSObject<HostsControllerProtocol> *controller = [controllers objectAtIndex:i];
		
		[controller loadFiles];
		
		for (int j=0; j<[[controller hostsFiles] count]; j++) {
			NSIndexPath *indexPath = [[NSIndexPath indexPathWithIndex:i] indexPathByAddingIndex:j];
			[self insertObject:[[controller hostsFiles] objectAtIndex:j] atArrangedObjectIndexPath:indexPath];
		}
	}
	
	[self updateFilesCount];
	logInfo(@"All hosts files are loaded");
    [[NSNotificationCenter defaultCenter] postNotificationName:ActivateFileNotification object:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationName:AllHostsFilesLoadedFromDiskNotification object:nil];
}

#pragma mark -
#pragma mark Creating

- (IBAction)createNewHostsFile:(id)sender
{
	logDebug(@"Creating new hosts file");
	
	for (int i=0; i<[controllers count]; i++) {
		NSObject<HostsControllerProtocol> *controller = [controllers objectAtIndex:i];
		
		Hosts *hosts = [controller createNewHostsFile];
		
		if (hosts != nil) {
			[self addHostsFile:hosts forController:controller];
			
			logDebug(@"Renaming created hosts file");
			NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
			[nc postNotificationName:HostsFileShouldBeRenamedNotification object:hosts];
            [nc postNotificationName:HostsFileCreatedNotification object:hosts];
			
			break;
		}
	}
	
	[self updateFilesCount];
}

- (IBAction)createCombinedHostsFile:(id)sender
{
    logDebug(@"Creating combined hosts file");
    
    NSObject<HostsControllerProtocol> *controller = [self hostsControllerForControllerClass:[CombinedHostsController class]];
    Hosts *hosts = [controller createNewHostsFile];
    
    if (hosts != nil) {
        [self addHostsFile:hosts forController:controller];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:HostsFileCreatedNotification object:hosts];
    }
    
    [self updateFilesCount];
}

- (void)createNewHostsFileWithContents:(NSString*)contents
{
	for (int i=0; i<[controllers count]; i++) {
		NSObject<HostsControllerProtocol> *controller = [controllers objectAtIndex:i];
		
		Hosts *hosts = [controller createNewHostsFileWithContents:contents];
		
		if (hosts != nil) {
			[self addHostsFile:hosts forController:controller];
			break;
		}
	}
	
	[self updateFilesCount];
}

- (BOOL)createHostsFromURL:(NSURL*)url toGroup:(HostsGroup*)group
{	
	logDebug(@"Creating hosts from URL to group: %@", group);
	return [self createHostsFromURL:url forController:[self hostsControllerForHostsGroup:group]];
}

- (BOOL)createHostsFromURL:(NSURL*)url forControllerClass:(Class)controllerClass
{
	logDebug(@"Creating hosts from URL for controller: %@", controllerClass);
	return [self createHostsFromURL:url forController:[self hostsControllerForControllerClass:controllerClass]];
}

- (BOOL)createHostsFromLocalURL:(NSURL*)url toGroup:(HostsGroup*)group
{
	logDebug(@"Creating hosts from local URL to group: %@", group);
	return [self createHostsFromLocalURL:url forController:[self hostsControllerForHostsGroup:group]];
}

- (BOOL)createHostsFromLocalURL:(NSURL*)url forControllerClass:(Class)controllerClass
{
	logDebug(@"Creating hosts from local for controller: %@", controllerClass);
	return [self createHostsFromLocalURL:url forController:[self hostsControllerForControllerClass:controllerClass]];
}

- (BOOL)rename:(Hosts*)hosts to:(NSString*)name
{
	
	NSObject<HostsControllerProtocol> *controller = [self hostsControllerForFile:hosts];
	BOOL renameSuccessful = [controller rename:hosts to:name];
	
	if (!renameSuccessful) {
		logDebug(@"Failed to rename");
		return NO;
	}
	
	logDebug(@"Renamed hosts file to: \"%@\"", [hosts name]);
	
	if ([hosts isEqual:[self activeHostsFile]]) {
		logDebug(@"Changing active hosts path to: \"%@\"", [hosts path]);
		[Preferences setActiveHostsFile:[hosts path]];
	}
	
	return YES;
}

#pragma mark Saving

-(IBAction)saveSelected:(id)sender
{
	logDebug(@"Saving selected hosts file");
	Hosts *hosts = [self selectedHosts];
	[self saveHosts:hosts];
}

- (void)save:(id)sender
{
	Hosts *hosts = [sender representedObject];
	[self saveHosts:hosts];
}

- (void)saveHosts:(Hosts*)hosts
{
    [self stopTrackingFileChanges];
	NSObject<HostsControllerProtocol> *controller = [self hostsControllerForFile:hosts];
	[controller saveHosts:hosts];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:HostsFileSavedNotification object:hosts];
    [self startTrackingFileChanges];
}

#pragma mark -
#pragma mark Removing

- (BOOL)canRemoveFiles
{
	return filesCount > 1;
}

- (void)remove:(id)sender
{
	[self removeHostsFile:[sender representedObject] moveToTrash:NO];
}

- (void)removeSelectedHostsFile:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Remove file?"];
    [alert setInformativeText:@"Are you sure you want to remove the file?\nYou can not undo it."];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [self removeHostsFile:[self selectedHosts] moveToTrash:NO];
    }
}

- (void)removeHostsFile:(Hosts*)hosts moveToTrash:(BOOL)moveToTrash
{
	logDebug(@"Removing hosts file: \"%@\"", [hosts name]);
	
	Hosts *nextHosts = [self neighbourHostsFile:hosts];
	
	if ([hosts active]) {
		[self activateHostsFile:nextHosts];
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:HostsFileWillBeRemovedNotification object:hosts];
	
	[self removeObjectAtArrangedObjectIndexPath:[self hostsIndexPath:hosts]];
	
	NSObject<HostsControllerProtocol> *controller = [self hostsControllerForFile:hosts];
	[controller removeHostsFile:hosts moveToTrash:moveToTrash];
	
	[nc postNotificationName:HostsFileRemovedNotification object:hosts];
	
	[self updateFilesCount];
	
	[nc postNotificationName:HostsFileShouldBeSelectedNotification object:nextHosts];
}

#pragma mark -
#pragma mark Activating

- (void)activate:(id)sender
{
	[self activateHostsFile:[sender representedObject]];
}

- (IBAction)activateSelected:(id)sender
{
	[self activateHostsFile:[self selectedHosts]];
}

- (Hosts*)activatePrevious
{
	logDebug(@"Activating previous hosts file");
	
	Hosts *hosts = [self activeHostsFile];
	
	for (int i=0; i<[[self allHostsFiles] count]; i++) {
		hosts = [self previousHostsFile:hosts];
		
		if ([hosts exists]) {
			[self activateHostsFile:hosts];
			return hosts;
		}
	}
	
	return nil;
}

- (Hosts*)activateNext
{
	logDebug(@"Activating next hosts file");
	
	Hosts *hosts = [self activeHostsFile];
	
	for (int i=0; i<[[self allHostsFiles] count]; i++) {
		hosts = [self nextHostsFile:hosts];
		
		if ([hosts exists]) {
			[self activateHostsFile:hosts];
			return hosts;
		}
	}
	
	return nil;
}

- (void)activateHostsFile:(Hosts*)hosts
{
	logDebug(@"Activating: \"%@\"", [hosts name]);
    [self stopTrackingFileChanges];
	
	Hosts *activeHostsFile = [self activeHostsFile];
	
	NSObject<HostsControllerProtocol> *controller = [self hostsControllerForFile:hosts];
	BOOL newActivated = [controller activateHostsFile:hosts];
	
	if (newActivated) {
		[activeHostsFile setActive:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:ActivateFileNotification object:NULL];
	}
    [self startTrackingFileChanges];
}

#pragma mark -
#pragma mark Moving

- (void)move:(Hosts*)hosts to:(HostsGroup*)group
{
	NSObject<HostsControllerProtocol> *oldController = [self hostsControllerForFile:hosts];
	NSObject<HostsControllerProtocol> *newController = [self hostsControllerForHostsGroup:group];
	
	Hosts * newHosts = [newController createHostsFileWithName:[hosts name] contents:[hosts contents]];
	
	[self addHostsFile:newHosts forController:newController];
	
	if ([hosts active]) {
		[self activateHostsFile:newHosts];
	}
	
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:HostsFileRemovedNotification object:hosts];
	
	[self removeObjectAtArrangedObjectIndexPath:[self hostsIndexPath:hosts]];
	
	[oldController removeHostsFile:hosts moveToTrash:NO];
}

- (void)move:(Hosts*)hosts toControllerClass:(Class)controllerClass
{
	HostsGroup *group = [[self hostsControllerForControllerClass:controllerClass] hostsGroup];
	[self move:hosts to:group];
}

#pragma mark -
#pragma Tracking Changes

- (void)startTrackingFileChanges
{
    // Listening for writes only doesn't cover when the file
    // gets moved and relinked, so we need to listen for
    // VDKQueueNotifyDefault.  It also doesn't cover when the
    // file gets replaced by tools like Junos PulseVPN which restores
    // the file upon VPN connection close.
    [queue addPath:HostsFileLocation notifyingAbout:(VDKQueueNotifyAboutWrite | VDKQueueNotifyAboutDelete)];
}

- (void)stopTrackingFileChanges
{
    [queue removePath:HostsFileLocation];
}

#pragma mark -
#pragma mark General

- (Hosts*)activeHostsFile
{
	for (int i=0; i<[controllers count]; i++) {
		NSObject<HostsControllerProtocol> *controller = [controllers objectAtIndex:i];
		Hosts *hosts = [controller activeHostsFile];
		if (hosts != nil) {
			return hosts;
		}
	}
	
	return nil;
}

- (Hosts*)selectedHosts
{
	return [[self selectedObjects] lastObject];
}

- (void)selectHosts:(Hosts *)hosts
{
	NSIndexPath *path = [self hostsIndexPath:hosts];
	if (path) {
		// Defer to next run loop iteration so the tree controller
		// finishes any in-flight insert/remove before we change selection.
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setSelectionIndexPath:path];
		});
	}
}

- (NSArray*)allHostsFilesGrouped
{
	int nrControllers = [controllers count];
	
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:nrControllers];
	
	for (int i=0; i<nrControllers; i++) {
		NSObject<HostsControllerProtocol> *controller = [controllers objectAtIndex:i];
		
		[array addObject:[Pair pairWithLeft:[controller name] right:[controller hostsFiles]]];
		
	}
	
	return array;
}

- (NSArray*)allHostsFiles
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSObject<HostsControllerProtocol> *controller in controllers) {
        [array addObjectsFromArray:[controller hostsFiles]];
    }
    
    return array;
}

- (int)filesCount
{
	return filesCount;
}

- (BOOL)hostsFileWithURLExists:(NSURL*)url
{
	for (int i=0; i<[controllers count]; i++) {
		NSObject<HostsControllerProtocol> *controller = [controllers objectAtIndex:i];
		
		if ([controller hostsFileWithURLExists:url]) {
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)hostsFilesExistForControllerClass:(Class)controllerClass
{
	NSObject<HostsControllerProtocol> *controller = [self hostsControllerForControllerClass:controllerClass];
	return [[controller hostsFiles] count] > 0;
}

- (BOOL)canCreateHostsFromLocalURL:(NSURL*)url toGroup:(HostsGroup*)group
{
	NSObject<HostsControllerProtocol> *controller = [self hostsControllerForHostsGroup:group];
	return [controller canCreateHostsFromLocalURL:url];
}

- (BOOL)canCreateHostsFromURL:(NSURL*)url toGroup:(HostsGroup*)group
{
	NSObject<HostsControllerProtocol> *controller = [self hostsControllerForHostsGroup:group];
	return [controller canCreateHostsFromURL:url];
}

- (BOOL)hostsFileWithLocalURLExists:(NSURL*)url
{
	return [self hostsFileWithLocalURL:url] != nil;
}

- (Hosts*)hostsFileWithLocalURL:(NSURL*)url
{
	for (int i=0; i<[controllers count]; i++) {
		NSObject<HostsControllerProtocol> *controller = [controllers objectAtIndex:i];
		
		for (int j=0; j<[[controller hostsFiles] count]; j++) {
			Hosts *hosts = [[controller hostsFiles] objectAtIndex:j];
			
			NSURL *hostsURL = [NSURL fileURLWithPath:[hosts path]];
			if ([hostsURL isEqual:url]) {
				return hosts;
			}
		}
	}
	
	return nil;
}

-(void) VDKQueue:(VDKQueue *)queue receivedNotification:(NSString*)noteName forPath:(NSString*)fpath
{
    // VDKQueue is notifying me too often, so filter out what we really want
    if (!([noteName isEqualToString:VDKQueueDeleteNotification] || ( [noteName isEqualTo:VDKQueueWriteNotification]) )) {
        return;
    }
    logDebug(@"External application has changed the hosts file, restoring file");
    
    if (![Preferences overrideExternalModifications]) {
        logDebug(@"Restoring not enabled, aborting");
        return;
    }
    
    Hosts *activeHosts = [self activeHostsFile];
    if (activeHosts == nil) {
        logDebug(@"No active hosts file, can't restore");
        return;
    }

    [self stopTrackingFileChanges];
    NSObject<HostsControllerProtocol> *controller = [self hostsControllerForFile:activeHosts];
	BOOL success = [controller restoreHostsToOriginalLocation:activeHosts];
    [self startTrackingFileChanges];

    if (!success) {
        logWarn(@"Failed to restore file");
        return;
    }

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:RestoredHostsFileNotification object:nil];
}

#pragma mark -
#pragma mark HostsControllerDelegateProtocol

- (void)newHostsFileAdded:(Hosts*)hosts controller:(NSObject<HostsControllerProtocol>*)controller
{
	[self addHostsFile:hosts forController:controller];
	[self updateFilesCount];
}

- (void)hostsFileRemoved:(Hosts*)hosts controller:(NSObject<HostsControllerProtocol>*)controller
{
	int index = [controllers indexOfObject:controller];
	NSArray *files = [[[self content] objectAtIndex:index] children];
	
	int i;
	for (i=0; i<[files count]; i++) {
		if ([[files objectAtIndex:i] isEqual:hosts]) {
			break;
		}
	}
	
	NSIndexPath *indexPath = [[NSIndexPath indexPathWithIndex:index] indexPathByAddingIndex:i];
	[self removeObjectAtArrangedObjectIndexPath:indexPath];
	
	[self updateFilesCount];
}

@end

@implementation HostsMainController (Private)

- (void)addGroups
{
	logDebug(@"Adding groups");
	for (int i=0; i<[controllers count]; i++) {
		HostsGroup *hostsGroup = [[controllers objectAtIndex:i] hostsGroup];
		[self insertObject:hostsGroup atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:i]];
		
	}
}

- (void)updateFilesCount
{
	int count = 0;
	for (int i=0; i<[controllers count]; i++) {
		count += [[[controllers objectAtIndex:i] hostsFiles] count];
	}
	
	[self willChangeValueForKey:@"filesCount"];
	[self willChangeValueForKey:@"canRemoveFiles"];
	
	filesCount = count;
	
	[self didChangeValueForKey:@"filesCount"];
	[self didChangeValueForKey:@"canRemoveFiles"];
}

- (NSObject<HostsControllerProtocol>*) hostsControllerForFile:(Hosts*)hosts
{
	for (int i=0; i<[controllers count]; i++) {
		NSObject<HostsControllerProtocol> *controller = [controllers objectAtIndex:i];
		
		for (int j=0; j<[[controller hostsFiles] count]; j++) {
			Hosts *hosts2 = [[controller hostsFiles] objectAtIndex:j];
			if ([hosts isEqual:hosts2]) {
				return controller;
			}
		}
	}
	
	logError(@"Could not find controller for hosts file: \"%@\"", [hosts name]);
	return nil;
}

- (NSIndexPath*)hostsIndexPath:(Hosts*)hosts
{
	for (int i=0; i<[controllers count]; i++) {
		NSObject<HostsControllerProtocol> *controller = [controllers objectAtIndex:i];
		
		for (int j=0; j<[[controller hostsFiles] count]; j++) {
			Hosts *hosts2 = [[controller hostsFiles] objectAtIndex:j];
			if ([hosts isEqual:hosts2]) {
				return [[NSIndexPath indexPathWithIndex:i] indexPathByAddingIndex:j];
			}

		}
		
	}

	logError(@"Could not find index path for hosts file: \"%@\"", [hosts name]);
	return nil;
}

#pragma mark -
#pragma mark File change listener

- (Hosts*)previousHostsFile:(Hosts*)hosts
{
	NSArray *hostsFiles = [self allHostsFiles];

	for (int i=0; i<[hostsFiles count]; i++) {
		Hosts *hosts2 = [hostsFiles objectAtIndex:i];
		if ([hosts2 isEqual:hosts]) {
			if (i == 0) {
				return [hostsFiles lastObject];
			}
			return [hostsFiles objectAtIndex:i-1];
		}
	}
	
	logError(@"Could not find previous hosts file for: \"%@\"", [hosts name]);
	return nil;
}

- (Hosts*)nextHostsFile:(Hosts*)hosts
{
	NSArray *hostsFiles = [self allHostsFiles];
	
	for (int i=0; i<[hostsFiles count]; i++) {
		Hosts *hosts2 = [hostsFiles objectAtIndex:i];
		
		if ([hosts2 isEqual:hosts]) {
			if ([hostsFiles count] == i+1) {
				return [hostsFiles objectAtIndex:0];
			}
			return [hostsFiles objectAtIndex:i+1];
		}
	}
	
	logError(@"Could not find next hosts file for: \"%@\"", [hosts name]);
	return nil;
}

- (Hosts*)neighbourHostsFile:(Hosts*)hosts
{
	NSArray *hostsFiles = [self allHostsFiles];
	
	for (int i=0; i<[hostsFiles count]; i++) {
		Hosts *hosts2 = [hostsFiles objectAtIndex:i];
		
		if ([hosts2 isEqual:hosts]) {
			if ([hostsFiles count] == i+1) {
				return [hostsFiles objectAtIndex:i-1];
			}
			return [hostsFiles objectAtIndex:i+1];
		}
	}
	
	logError(@"Could not find neighbour hosts file for: \"%@\"", [hosts name]);
	return nil;
}

- (void)addHostsFile:(Hosts*)hosts forController:(NSObject<HostsControllerProtocol>*)controller
{
	int index = [controllers indexOfObject:controller];
	
	NSIndexPath *indexPath = [[NSIndexPath indexPathWithIndex:index] indexPathByAddingIndex:[[controller hostsFiles] count]-1];
	[self insertObject:hosts atArrangedObjectIndexPath:indexPath];
}

- (BOOL)createHostsFromURL:(NSURL*)url forController:(NSObject<HostsControllerProtocol>*)controller
{
	Hosts *hosts = [controller createHostsFromURL:url];
	
	if (hosts == nil) {
		return NO;
	}
	
	[self addHostsFile:hosts forController:controller];
	
	[self updateFilesCount];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:HostsFileCreatedNotification object:hosts];
	
	return YES;
}

- (BOOL)createHostsFromLocalURL:(NSURL*)url forController:(NSObject<HostsControllerProtocol>*)controller
{
	Hosts *hosts = [controller createHostsFromLocalURL:url];
	if (hosts == nil) {
		return NO;
	}
	
	[self addHostsFile:hosts forController:controller];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:HostsFileCreatedNotification object:hosts];
	
	[self updateFilesCount];
	
	return YES;
}

- (NSObject<HostsControllerProtocol>*)hostsControllerForHostsGroup:(HostsGroup*)hostsGroup
{
	int i;
	NSArray *groups = [self content];
	for (i=0; i<[groups count]; i++) {
		if ([[groups objectAtIndex:i] isEqual:hostsGroup]) {
			break;
		}
	}
	
	return [controllers objectAtIndex:i];
}

- (NSObject<HostsControllerProtocol>*)hostsControllerForControllerClass:(Class)controllerClass
{
	int index = -1;
	for (int i=0; i<[controllers count]; i++) {
		if ([[controllers objectAtIndex:i] isKindOfClass:controllerClass]) {
			index = i;
			break;
		}
	}
	
	return [controllers objectAtIndex:index];
}

@end
