//
//  VDKQueue.h
//
//  Created by Bryan Jones on 28 March 2012.
//  Copyright (c) 2012 Bryan D K Jones.
//  You are free to use, modify and redistribute this software subject to these conditions:
//      1) I am not liable for anything that happens to you if you use this software --- including if it becomes sentient and eats your grandmother.
//      2) You keep this notice in your derivative work.
//      3) You keep Uli Kusterer's original copyright notice as well (this notice appears at the bottom of this file.)
//      4) You are awesome.
//      

//
//  BASED ON UKKQUEUE:
//
//      This is an updated, modernized and streamlined version of the excellent UKKQueue class, which was authored by Uli Kusterer.
//      UKKQueue was written back in 2003 and there have been many, many improvements to Objective-C since then. VDKQueue uses the 
//      core of Uli's original class, but makes it faster and more efficient. Method calls are reduced. Grand Central Dispatch is used in place
//      of Uli's "threadProxy" objects. The new @autoreleasepool is used instead of alloc/initing a pool (which is much slower). The memory footprint 
//      is roughly halved, as I don't create the overhead that UKKQueue does. I take fewer locks, don't depend on notifications to get back to the main thread, and
//      use modern language constructs to MASSIVELY speed up event processing compared to the original UKKQueue class.
//
//      VDKQueue is also simplified. The option to use it as a singleton is removed. You simply alloc/init an instance and add paths you want to
//      watch. Your objects can be alerted to changes either by notifications or by a delegate method (or both). See below. 
//
//      It also fixes several bugs. For one, it won't crash if it can't create a file descriptor to a file you ask it to watch. (By default, an OS X process can only
//      have about 3,000 file descriptors open at once. If you hit that limit, UKKQueue will crash. VDKQueue will not.)
//

//
//  DEPENDENCIES: 
//      
//      VDKQueue requires OS 10.7.0+ because it relies on the @autoreleasepool language addition. If you wish to use the class on 10.6, you can 
//      simply replace the @autoreleasepool construct with an alloc/init-ed NSAutoReleasePool instance instead. The class will not work on versions of 
//      OS X below 10.6, as it requires blocks and Grand Central Dispatch.
//


#import <Foundation/Foundation.h>
#include <sys/event.h>


//
//  Logical OR these values into the u_int that you pass in the -addPath:notifyingAbout: method
//  to specify the types of notifications you're interested in. Pass the default value to receive all of them.
//
#define VDKQueueNotifyAboutRename					NOTE_RENAME		// Item was renamed.
#define VDKQueueNotifyAboutWrite					NOTE_WRITE		// Item contents changed (also folder contents changed).
#define VDKQueueNotifyAboutDelete					NOTE_DELETE		// item was removed.
#define VDKQueueNotifyAboutAttributeChange			NOTE_ATTRIB		// Item attributes changed.
#define VDKQueueNotifyAboutSizeIncrease				NOTE_EXTEND		// Item size increased.
#define VDKQueueNotifyAboutLinkCountChanged			NOTE_LINK		// Item's link count changed.
#define VDKQueueNotifyAboutAccessRevocation			NOTE_REVOKE		// Access to item was revoked.

#define VDKQueueNotifyDefault						(VDKQueueNotifyAboutRename | VDKQueueNotifyAboutWrite \
                                                    | VDKQueueNotifyAboutDelete | VDKQueueNotifyAboutAttributeChange \
                                                    | VDKQueueNotifyAboutSizeIncrease | VDKQueueNotifyAboutLinkCountChanged \
                                                    | VDKQueueNotifyAboutAccessRevocation)

//
//  Notifications that this class sends to the NSWORKSPACE notification center.
//      Object          =   the instance of VDKQueue that was watching for changes
//      userInfo.path   =   the file path where the change was observed
//
extern NSString * VDKQueueRenameNotification;
extern NSString * VDKQueueWriteNotification;
extern NSString * VDKQueueDeleteNotification;
extern NSString * VDKQueueAttributeChangeNotification;
extern NSString * VDKQueueSizeIncreaseNotification;
extern NSString * VDKQueueLinkCountChangeNotification;
extern NSString * VDKQueueAccessRevocationNotification;


//
//  Or, instead of subscribing to notifications, you can specify a delegate and implement this method to respond to kQueue events.
//  Note the required statement! For speed, this class does not check to make sure the delegate implements this method. (When I say "required" I mean it!)
//
@class VDKQueue;
@protocol VDKQueueDelegate <NSObject>
@required

-(void) VDKQueue:(VDKQueue *)queue receivedNotification:(NSString*)noteName forPath:(NSString*)fpath;

@end





@interface VDKQueue : NSObject
{
    id<VDKQueueDelegate>    _delegate;
    BOOL                    _alwaysPostNotifications;               // By default, notifications are posted only if there is no delegate set. Set this value to YES to have notes posted even when there is a delegate.
    
@private
    
    int						_coreQueueFD;                           // The actual kqueue ID (Unix file descriptor).
	NSMutableDictionary    *_watchedPathEntries;                    // List of VDKQueuePathEntries. Keys are NSStrings of the path that each VDKQueuePathEntry is for.
    BOOL                    _keepWatcherThreadRunning;              // Set to NO to cancel the thread that watches _coreQueueFD for kQueue events
}


//
//  Note: there is no need to ask whether a path is already being watched. Just add it or remove it and this class
//        will take action only if appropriate. (Add only if we're not already watching it, remove only if we are.)
//  
//  Warning: You must pass full, root-relative paths. Do not pass tilde-abbreviated paths or file URLs. 
//
- (void) addPath:(NSString *)aPath;
- (void) addPath:(NSString *)aPath notifyingAbout:(u_int)flags;     // See note above for values to pass in "flags"

- (void) removePath:(NSString *)aPath;
- (void) removeAllPaths;

@property (assign) id<VDKQueueDelegate> delegate;
@property (assign) BOOL alwaysPostNotifications;

@end




//  This is the original copyright header that shipped with UKKQueue, on which VDKQueue is based:
//	UKKQueue.m
//	Created by Uli Kusterer on 21.12.2003
//	Copyright 2003 Uli Kusterer.
//	This software is provided 'as-is', without any express or implied
//	warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//	Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//	   1. The origin of this software must not be misrepresented; you must not
//	   claim that you wrote the original software. If you use this software
//	   in a product, an acknowledgment in the product documentation would be
//	   appreciated but is not required.
//	   2. Altered source versions must be plainly marked as such, and must not be
//	   misrepresented as being the original software.
//	   3. This notice may not be removed or altered from any source
//	   distribution.