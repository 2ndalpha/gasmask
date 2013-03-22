//
//  VDKQueue.m
//
//  Created by Bryan Jones on 28 March 2012.
//  Copyright (c) 2012 Bryan D K Jones.
//
//  (See the header file for full copyright and usage information.)
//

#import "VDKQueue.h"
#include <sys/types.h>
#import <unistd.h>
#import <fcntl.h>
#include <sys/stat.h>



NSString * VDKQueueRenameNotification = @"VDKQueueFileRenamedNotification";
NSString * VDKQueueWriteNotification = @"VDKQueueFileWrittenToNotification";
NSString * VDKQueueDeleteNotification = @"VDKQueueFileDeletedNotification";
NSString * VDKQueueAttributeChangeNotification = @"VDKQueueFileAttributesChangedNotification";
NSString * VDKQueueSizeIncreaseNotification = @"VDKQueueFileSizeIncreasedNotification";
NSString * VDKQueueLinkCountChangeNotification = @"VDKQueueLinkCountChangedNotification";
NSString * VDKQueueAccessRevocationNotification = @"VDKQueueAccessWasRevokedNotification";



#pragma mark -
#pragma mark VDKQueuePathEntry
#pragma mark -
#pragma ------------------------------------------------------------------------------------------------------------------------------------------------------------ */
#pragma ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

//  This is a simple model class used to hold info about each path we watch.
@interface VDKQueuePathEntry : NSObject
{
	NSString*		_path;
	int				_watchedFD;
	u_int			_subscriptionFlags;
}

- (id) initWithPath:(NSString*)inPath andSubscriptionFlags:(u_int)flags;

@property (atomic, copy) NSString *path;
@property (atomic, assign) int watchedFD;
@property (atomic, assign) u_int subscriptionFlags;

@end


@implementation VDKQueuePathEntry
@synthesize path = _path, watchedFD = _watchedFD, subscriptionFlags = _subscriptionFlags;


- (id) initWithPath:(NSString*)inPath andSubscriptionFlags:(u_int)flags;
{
    self = [super init];
	if(self)
	{
		_path = [inPath copy];
		_watchedFD = open( [_path fileSystemRepresentation], O_EVTONLY, 0 );
		if(_watchedFD < 0)
		{
			[self autorelease];
			return nil;
		}
		_subscriptionFlags = flags;
	}
	return self;
}

-(void)	dealloc
{
	[_path release];
	_path = nil;
    
	if(_watchedFD >= 0) close(_watchedFD);
	_watchedFD = -1;
	
	[super dealloc];
}

@end











#pragma mark -
#pragma mark VDKQueue
#pragma mark -
#pragma ------------------------------------------------------------------------------------------------------------------------------------------------------------ */
#pragma ------------------------------------------------------------------------------------------------------------------------------------------------------------ */

@interface VDKQueue ()
- (void) watcherThread:(id)sender;
@end



@implementation VDKQueue
@synthesize delegate = _delegate, alwaysPostNotifications = _alwaysPostNotifications;



#pragma mark -
#pragma mark INIT/DEALLOC

- (id) init
{
	self = [super init];
	if (self)
	{
		_coreQueueFD = kqueue();
		if (_coreQueueFD == -1)
		{
			[self autorelease];
			return nil;
		}
		
        _alwaysPostNotifications = NO;
		_watchedPathEntries = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (void) dealloc
{
    // Shut down the thread that's scanning for kQueue events
    _keepWatcherThreadRunning = NO;
    
    // Do this to close all the open file descriptors for files we're watching
    [self removeAllPaths];
    
    [_watchedPathEntries release];
    _watchedPathEntries = nil;
    
    [super dealloc];
}





#pragma mark -
#pragma mark PRIVATE METHODS

- (VDKQueuePathEntry *)	addPathToQueue:(NSString *)path notifyingAbout:(u_int)flags
{
	@synchronized(self)
	{
        // Are we already watching this path?
		VDKQueuePathEntry *pathEntry = [_watchedPathEntries objectForKey:path];
		
        if (pathEntry)
		{
            // All flags already set?
			if(([pathEntry subscriptionFlags] & flags) == flags) 
            {
				return [[pathEntry retain] autorelease]; 
            }
			
			flags |= [pathEntry subscriptionFlags];
		}
		
		struct timespec		nullts = { 0, 0 };
		struct kevent		ev;
		
		if (!pathEntry)
        {
            pathEntry = [[[VDKQueuePathEntry alloc] initWithPath:path andSubscriptionFlags:flags] autorelease];
        }
        
		if (pathEntry)
		{
			EV_SET(&ev, [pathEntry watchedFD], EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_CLEAR, flags, 0, pathEntry);
			
			[pathEntry setSubscriptionFlags:flags];
            
            [_watchedPathEntries setObject:pathEntry forKey:path];
            kevent(_coreQueueFD, &ev, 1, NULL, 0, &nullts);
            
			// Start the thread that fetches and processes our events if it's not already running.
			if(!_keepWatcherThreadRunning)
			{
				_keepWatcherThreadRunning = YES;
				[NSThread detachNewThreadSelector:@selector(watcherThread:) toTarget:self withObject:nil];
			}
        }
        
        return [[pathEntry retain] autorelease];
    }
    
    return nil;
}


- (void) watcherThread:(id)sender;
{
    int					n;
    struct kevent		ev;
    struct timespec     timeout = { 1, 0 };     // 1 second timeout. Should be longer, but we need this thread to exit when a kqueue is dealloced, so 1 second timeout is quite a while to wait.
	int					theFD = _coreQueueFD;	// So we don't have to risk accessing iVars when the thread is terminated.
    
    NSMutableArray      *notesToPost = [[NSMutableArray alloc] initWithCapacity:5];
    
#if DEBUG_LOG_THREAD_LIFETIME
	NSLog(@"watcherThread started.");
#endif
	
    while(_keepWatcherThreadRunning)
    {
		@autoreleasepool 
        {
            NS_DURING
                n = kevent(theFD, NULL, 0, &ev, 1, &timeout);
                if (n > 0)
                {
                    //NSLog( @"KEVENT returned %d", n );
                    if (ev.filter == EVFILT_VNODE)
                    {
                        //NSLog( @"KEVENT filter is EVFILT_VNODE" );
                        if (ev.fflags)
                        {
                            //NSLog( @"KEVENT flags are set" );
                            VDKQueuePathEntry *pe = [[(VDKQueuePathEntry*)ev.udata retain] autorelease];    // In case one of the notified folks removes the path.
                            NSString *fpath = [pe path];
                            [[NSWorkspace sharedWorkspace] noteFileSystemChanged:fpath];
                        
                        
                            // Clear any old notifications
                            [notesToPost removeAllObjects];
                        
                            
                            // Figure out which notifications we need to issue
                            if ((ev.fflags & NOTE_RENAME) == NOTE_RENAME)
                            {
                                [notesToPost addObject:VDKQueueRenameNotification];
                            }
                            if ((ev.fflags & NOTE_WRITE) == NOTE_WRITE)
                            {
                                [notesToPost addObject:VDKQueueWriteNotification];
                            }
                            if ((ev.fflags & NOTE_DELETE) == NOTE_DELETE)
                            {
                                [notesToPost addObject:VDKQueueDeleteNotification];
                            }
                            if ((ev.fflags & NOTE_ATTRIB) == NOTE_ATTRIB)
                            {
                                [notesToPost addObject:VDKQueueAttributeChangeNotification];
                            }
                            if ((ev.fflags & NOTE_EXTEND) == NOTE_EXTEND)
                            {
                                [notesToPost addObject:VDKQueueSizeIncreaseNotification];
                            }
                            if ((ev.fflags & NOTE_LINK) == NOTE_LINK)
                            {
                                [notesToPost addObject:VDKQueueLinkCountChangeNotification];
                            }
                            if ((ev.fflags & NOTE_REVOKE) == NOTE_REVOKE)
                            {
                                [notesToPost addObject:VDKQueueAccessRevocationNotification];
                            }
                            
                            
                            [fpath retain];                                                 // Need to retain so it does not disappear while the block below is waiting to run on the main thread.
                            NSArray *notes = [[NSArray alloc] initWithArray:notesToPost];   // notesToPost will be changed in the next loop iteration, which will likely occur before the block below runs.
                            
                            
                            // Post the notifications (or call the delegate method) on the main thread.
                            dispatch_async(dispatch_get_main_queue(), 
                            ^{
                                for (NSString *note in notes)
                                {
                                    [_delegate VDKQueue:self receivedNotification:note forPath:fpath];
                                    
                                    if (!_delegate || _alwaysPostNotifications)
                                    {
                                        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:fpath forKey:@"path"];
                                        [[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName:note object:self userInfo:userInfoDict];
                                    }
                                }
                                
                                [fpath release];
                                [notes release];
                            });
        
                        }
                    }
                }
            NS_HANDLER
                NSLog(@"Error in VDKQueue watcherThread: %@", localException);
            NS_ENDHANDLER
        }
    }
    
	// Close our kqueue's file descriptor
	if(close(theFD) == -1) {
       NSLog(@"VDKQueue watcherThread: Couldn't close main kqueue (%d)", errno); 
    }
    
    [notesToPost release];
    
#if DEBUG_LOG_THREAD_LIFETIME
	NSLog(@"watcherThread finished.");
#endif

}






#pragma mark -
#pragma mark PUBLIC METHODS

- (void) addPath:(NSString *)aPath
{
    if (!aPath) return;
    [aPath retain];
    
    @synchronized(self)
    {
        VDKQueuePathEntry *entry = [_watchedPathEntries objectForKey:aPath];
        
        // Only add this path if we don't already have it.
        if (!entry)
        {
            entry = [self addPathToQueue:aPath notifyingAbout:VDKQueueNotifyDefault];
            if (!entry) {
                NSLog(@"VDKQueue tried to add the path %@ to watchedPathEntries, but the VDKQueuePathEntry was nil. \nIt's possible that the host process has hit its max open file descriptors limit.", aPath);
            }
        }
    }
    
    [aPath release];
}


- (void) addPath:(NSString *)aPath notifyingAbout:(u_int)flags
{
    if (!aPath) return;
    [aPath retain];
    
    @synchronized(self)
    {
        VDKQueuePathEntry *entry = [_watchedPathEntries objectForKey:aPath];
        
        // Only add this path if we don't already have it.
        if (!entry)
        {
            entry = [self addPathToQueue:aPath notifyingAbout:flags];
            if (!entry) {
                NSLog(@"VDKQueue tried to add the path %@ to watchedPathEntries, but the VDKQueuePathEntry was nil. \nIt's possible that the host process has hit its max open file descriptors limit.", aPath);
            }
        }
    }
    
    [aPath release];
}


- (void) removePath:(NSString *)aPath
{
    if (!aPath) return;
    [aPath retain];
    
    @synchronized(self)
	{
		VDKQueuePathEntry *entry = [_watchedPathEntries objectForKey:aPath];
        
        // Remove it only if we're watching it.
        if (entry) {
            [_watchedPathEntries removeObjectForKey:aPath];
        }
	}
    
    [aPath release];
}


- (void) removeAllPaths
{
    @synchronized(self)
    {
        [_watchedPathEntries removeAllObjects];
    }
}


@end

