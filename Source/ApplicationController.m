/***************************************************************************
 *   Copyright (C) 2009-2018 by Siim Raud   *
 *   siim@clockwise.ee   *
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

#import "ApplicationController.h"
#import "StructureConverter.h"
#import "Preferences.h"
#import "AboutBoxController.h"
#import "HostsMenu.h"
#import "URLWindowController.h"
#import "LocalHostsController.h"
#import "RemoteHostsController.h"
#import "NotificationHelper.h"
#import "Network.h"

@interface ApplicationController(Private)
- (void)initStructure;
- (void)initEditorWindow;
- (void)notifyHostsChange:(Hosts*)hosts;
- (void)showApplicationInDock;
- (void)hideApplicationFromDock;
- (void)createHostsFileFromLocalURL:(NSURL*)url;

- (void)activatePreviousFile:(NSNotification *)note;
- (void)activateNextFile:(NSNotification *)note;
- (void)notifyOfFileRestored:(NSNotification *)note;
@end

@implementation ApplicationController


static ApplicationController *sharedInstance = nil;

+ (ApplicationController*)defaultInstance
{
	return sharedInstance;
}

- (id)init
{
    if (sharedInstance) {
        return sharedInstance;
    }
	if (self = [super init]) {
		busyThreads = 0;
		shouldQuit = YES;
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(activatePreviousFile:) name:ActivatePreviousFileNotification object:nil];
		[nc addObserver:self selector:@selector(activateNextFile:) name:ActivateNextFileNotification object:nil];
        [nc addObserver:self selector:@selector(notifyOfFileRestored:) name:RestoredHostsFileNotification object:nil];
        
        [NotificationHelper initNotificationCenter];
		
		sharedInstance = self;
		return self;
	}
    return sharedInstance;
}

-(IBAction)openPreferencesWindow:(id)sender
{
	if (!preferenceController) {
		preferenceController = [[PreferenceController alloc] init];
	}
	
    [self showApplicationInDock];
	[preferenceController showWindow:self];
}

- (IBAction)displayAboutBox:(id)sender
{
    if (!aboutBoxController) {
        aboutBoxController = [AboutBoxController new];
    }
	[aboutBoxController showWindow:self];
}

- (IBAction)reportBugs:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:IssueTrackerURL]];
}

- (IBAction)donate:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:DonateURL]];
}

-(IBAction)quit:(id)sender
{
	[[NSApplication sharedApplication] terminate:self];
}

- (IBAction)openEditorWindow:(id)sender
{
	if (![window isVisible]) {
		[self initEditorWindow];
	}
	
	[self showApplicationInDock];
    [window makeKeyWindow];
}

- (IBAction)closeEditorWindow:(id)sender
{
	[self hideApplicationFromDock];
}

- (IBAction)addFromURL:(id)sender
{
	URLWindowController * controller = [URLWindowController new];
    [[NSApp mainWindow] beginSheet:[controller window] completionHandler:nil];
}

- (IBAction)openHostsFile:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
    NSArray *fileTypes = [NSArray arrayWithObject:HostsFileExtension];
    [panel setAllowedFileTypes:fileTypes];
    if ([panel runModal] == NSModalResponseOK) {
		[self createHostsFileFromLocalURL:[[panel URLs] lastObject]];
	}
}

- (IBAction)updateAndSynchronize:(id)sender
{
	logDebug(@"Update & synchronize");
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:UpdateAndSynchronizeNotification object:nil];
}

- (BOOL)editorWindowOpened
{
	return [window isVisible];
}

- (void)increaseBusyThreadsCount:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->busyThreads++;
        [self->busyIndicator startAnimation:self];
    });
}

- (void)decreaseBusyThreadsCount:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->busyThreads > 0) {
            self->busyThreads--;
        }
        if (self->busyThreads == 0) {
            [self->busyIndicator stopAnimation:self];
        }
    });
}

#pragma mark - Application Delegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    [Logger setup];

    logDebug(@"Starting Gas Mask %@", [NSApplication version]);

    [[Network defaultInstance] startListeningForChanges];
    
	[NSApp setServicesProvider:self];
	
	[self initStructure];
    [hostsController load];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(increaseBusyThreadsCount:) name:ThreadBusyNotification object:nil];
	[nc addObserver:self selector:@selector(decreaseBusyThreadsCount:) name:ThreadNotBusyNotification object:nil];
	
	if (!openedAtLogin() && [Preferences showEditorWindow]) {
		[self openEditorWindow:nil];
	}
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	if (reopened() && [filename isEqual:@"#reopen#"]) {
		return NO;
	}
	
	logDebug(@"Opening file \"%@\"", filename);
	
	if ([[filename pathExtension] isEqual:HostsFileExtension]) {
		NSURL *url = [NSURL fileURLWithPath:filename];
		[self createHostsFileFromLocalURL:url];
		return YES;
	}
	
	return NO;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	shouldQuit = YES;
	[self hideApplicationFromDock];
	return NO;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[Network defaultInstance] stopListenening];
    
	if (!shouldQuit) {
		[self hideApplicationFromDock];
	}
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
	return [HostsMenu new];
}

#pragma mark -
#pragma mark CrashReportSenderDelegate

- (void) showMainApplicationWindow
{
	[[NSApp mainWindow] makeFirstResponder: nil];
	[[NSApp mainWindow] makeKeyAndOrderFront: nil];
}

#pragma mark -
#pragma mark Service Provider

-(void)createNewHostsFile:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
	logDebug(@"Creating new hosts file from dropped data");
    NSString * data = [pboard stringForType:NSPasteboardTypeString];
    
	NSURL *url = [NSURL URLWithString:data];
	if (url == nil) {
		[hostsController createNewHostsFileWithContents:data];
	}
	else {
		BOOL created = [hostsController createHostsFromURL:url forControllerClass:[RemoteHostsController class]];
		if (!created) {
			[hostsController createHostsFromURL:url forControllerClass:[LocalHostsController class]];
		}
	}
}

@end

@implementation ApplicationController(Private)

- (void)initStructure
{
	logDebug(@"Init structure");
	StructureConverter *structureConverter = [StructureConverter new];
	[structureConverter convertToCurrent];
}

- (void)initEditorWindow
{
    logDebug(@"Initializing editor window");
    [[NSBundle mainBundle] loadNibNamed:@"Editor" owner:self topLevelObjects:nil];
}

- (void)activatePreviousFile:(NSNotification *)note
{
	Hosts *hosts = [hostsController activatePrevious];
    [self notifyHostsChange:hosts];
}

- (void)activateNextFile:(NSNotification *)note
{
	Hosts *hosts = [hostsController activateNext];
    [self notifyHostsChange:hosts];
}

- (void)notifyOfFileRestored:(NSNotification *)note
{    
    [NotificationHelper notify:@"Hosts File Restored"
                       message:@"External application has changed the hosts file.\nGas Mask restored previous state."];
}

- (void)notifyHostsChange:(Hosts*)hosts
{
    [NotificationHelper notify:@"Hosts File Activated" message:[hosts name]];
}

- (void)showApplicationInDock
{
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)hideApplicationFromDock
{
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
	[Preferences setShowEditorWindow:NO];
    [window close];
}

- (void)createHostsFileFromLocalURL:(NSURL*)url
{
	if ([hostsController hostsFileWithLocalURLExists:url]) {
		Hosts *hosts = [hostsController hostsFileWithLocalURL:url];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:HostsFileShouldBeSelectedNotification object:hosts];
	}
	else {
		[hostsController createHostsFromLocalURL:url forControllerClass:[LocalHostsController class]];
	}
}

@end
