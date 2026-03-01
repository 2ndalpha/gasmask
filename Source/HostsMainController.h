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

#import "Hosts.h"
#import "HostsGroup.h"
#import "VDKQueue.h"

#define HostsFileShouldBeRenamedNotification @"HostsFileShouldBeRenamedNotification"
#define HostsFileWillBeRemovedNotification @"HostsFileWillBeRemovedNotification"

@protocol HostsControllerProtocol;


@protocol HostsControllerDelegateProtocol

- (void)newHostsFileAdded:(Hosts*)hosts controller:(NSObject<HostsControllerProtocol>*)controller;
- (void)hostsFileRemoved:(Hosts*)hosts controller:(NSObject<HostsControllerProtocol>*)controller;

@end

@protocol HostsControllerProtocol

- (void)setDelegate:(NSObject<HostsControllerDelegateProtocol>*)delegateValue;
- (NSString*)name;
- (HostsGroup*)hostsGroup;
- (void)loadFiles;
- (NSArray*)hostsFiles;
- (Hosts*)activeHostsFile;

/**
 Creates new hosts file.
 If controller returns <code>nil</code>, it does not support creating new hosts files.
 **/
- (Hosts*)createNewHostsFile;
- (Hosts*)createNewHostsFileWithContents:(NSString*)contents;
- (Hosts*)createHostsFileWithName:(NSString*)name contents:(NSString*)contents;
- (Hosts*)createHostsFromLocalURL:(NSURL*)url;

- (void)saveHosts:(Hosts*)hosts;
- (BOOL)rename:(Hosts*)hosts to:(NSString*)name;
- (void)removeHostsFile:(Hosts*)hosts moveToTrash:(BOOL)moveToTrash;
- (BOOL)activateHostsFile:(Hosts*)hosts;

/** Rewrites /etc/hosts file with contents of hosts file on the disk */
- (BOOL)restoreHostsToOriginalLocation:(Hosts*)hosts;

- (BOOL)hostsFileWithURLExists:(NSURL*)url;
- (Hosts*)createHostsFromURL:(NSURL*)url;

- (Hosts*)hostsFileByFileName:(NSString*)name;

- (BOOL)canCreateHostsFromLocalURL:(NSURL*)url;
- (BOOL)canCreateHostsFromURL:(NSURL*)url;

@end

@interface HostsMainController : NSTreeController<HostsControllerDelegateProtocol, VDKQueueDelegate> {
	@private
	NSArray *controllers;
	int filesCount;
}

+ (HostsMainController*)defaultInstance;

- (void)load;
- (BOOL)rename:(Hosts*)hosts to:(NSString*)name;

#pragma mark -
#pragma mark Creating

- (IBAction)createNewHostsFile:(id)sender;
- (IBAction)createCombinedHostsFile:(id)sender;
- (void)createNewHostsFileWithContents:(NSString*)contents;
- (BOOL)createHostsFromURL:(NSURL*)url toGroup:(HostsGroup*)group;
- (BOOL)createHostsFromURL:(NSURL*)url forControllerClass:(Class)controllerClass;

- (BOOL)createHostsFromLocalURL:(NSURL*)url toGroup:(HostsGroup*)group;
- (BOOL)createHostsFromLocalURL:(NSURL*)url forControllerClass:(Class)controllerClass;

#pragma mark -
#pragma mark Saving

- (IBAction)saveSelected:(id)sender;
- (void)save:(id)sender;
- (void)saveHosts:(Hosts*)hosts;

- (BOOL)canRemoveFiles;
- (void)remove:(id)sender;
- (void)removeSelectedHostsFile:(id)sender;
- (void)removeHostsFile:(Hosts*)hosts moveToTrash:(BOOL)moveToTrash;

#pragma mark -
#pragma mark Activating

- (void)activate:(id)sender;
- (Hosts*)activatePrevious;
- (Hosts*)activateNext;
- (IBAction)activateSelected:(id)sender;
- (void)activateHostsFile:(Hosts*)hosts;

#pragma mark -
#pragma mark Moving

- (void)move:(Hosts*)hosts to:(HostsGroup*)group;
- (void)move:(Hosts*)hosts toControllerClass:(Class)controllerClass;

#pragma mark -
#pragma Tracking Changes

- (void)startTrackingFileChanges;
- (void)stopTrackingFileChanges;

#pragma mark -
#pragma mark General

- (Hosts*)activeHostsFile;
- (Hosts*)selectedHosts;
- (void)selectHosts:(Hosts*)hosts;
- (NSArray*)allHostsFilesGrouped;
- (NSArray*)allHostsFiles;
- (int)filesCount;
- (BOOL)hostsFileWithURLExists:(NSURL*)url;
- (BOOL)canCreateHostsFromLocalURL:(NSURL*)url toGroup:(HostsGroup*)group;
- (BOOL)canCreateHostsFromURL:(NSURL*)url toGroup:(HostsGroup*)group;
- (BOOL)hostsFilesExistForControllerClass:(Class)controllerClass;

- (BOOL)hostsFileWithLocalURLExists:(NSURL*)url;
- (Hosts*)hostsFileWithLocalURL:(NSURL*)url;

@end
