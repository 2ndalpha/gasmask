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

#import <ShortcutRecorder/ShortcutRecorder.h>

#import "PreferenceController.h"
#import "Preferences.h"
#import "Preferences+Remote.h"
#import "LoginItem.h"
#import "Hotkey.h"
#import "Util.h"

#define TOOLBAR_GENERAL @"TOOLBAR_GENERAL"
#define TOOLBAR_EDITOR @"TOOLBAR_EDITOR"
#define TOOLBAR_REMOTE @"TOOLBAR_REMOTE"
#define TOOLBAR_HOTKEYS @"TOOLBAR_HOTKEYS"
#define TOOLBAR_UPDATE @"TOOLBAR_UPDATE"


@interface PreferenceController (Remote)
- (void)initRemote;
- (int)remoteInterval;
- (void)setRemoteInterval:(int)interval;
@end

@interface PreferenceController (Hotkeys)
- (void)initHotkeys;
@end

@interface PreferenceController (General)
- (void)initGeneral;
@end

@implementation PreferenceController

- (id)init
{
	self = [super initWithWindowNibName:@"Preferences"];
    if (self == nil) {
		return nil;
	}
	
	NSToolbar * toolbar = [[NSToolbar alloc] initWithIdentifier: @"Preferences Toolbar"];
	[toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode: NSToolbarSizeModeRegular];
    [toolbar setSelectedItemIdentifier: TOOLBAR_GENERAL];
	[[self window] setToolbar: toolbar];
	
	return self;
}

- (void) awakeFromNib
{
	[self setPreferenceView:nil];
	
	loginItem = [LoginItem new];
	[loginItem bind:@"enabled" toObject:[Preferences instance] withKeyPath:@"values.openAtLogin" options:nil];
		
	[self initGeneral];
	[self initRemote];
	[self initHotkeys];
}

- (NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar
{
    return [self toolbarDefaultItemIdentifiers: toolbar];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [self toolbarAllowedItemIdentifiers: toolbar];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects: TOOLBAR_GENERAL,
									  TOOLBAR_EDITOR,
									  TOOLBAR_REMOTE,
									  TOOLBAR_HOTKEYS,
									  TOOLBAR_UPDATE,
									  nil];
}

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar itemForItemIdentifier: (NSString *) ident willBeInsertedIntoToolbar: (BOOL) flag
{
	NSToolbarItem * item = [[NSToolbarItem alloc] initWithItemIdentifier: ident];
	
	if ([ident isEqualTo:TOOLBAR_GENERAL]) {
		[item setLabel: @"General"];
		[item setImage: [NSImage imageNamed: NSImageNamePreferencesGeneral]];
	}
	else if ([ident isEqualTo:TOOLBAR_EDITOR]) {
		[item setLabel: @"Editor"];
        [item setImage: [NSImage imageNamed: @"Editor.png"]];
	}
	else if ([ident isEqualTo:TOOLBAR_REMOTE]) {
		[item setLabel: @"Remote"];
		[item setImage: [NSImage imageNamed: @"Remote.png"]];
	}
	else if ([ident isEqualTo:TOOLBAR_HOTKEYS]) {
		[item setLabel: @"Hotkeys"];
		[item setImage: [NSImage imageNamed: @"Hotkeys.png"]];
	}
	else if ([ident isEqualTo:TOOLBAR_UPDATE]) {
		[item setLabel: @"Update"];
		[item setImage: [NSImage imageNamed: @"Update.png"]];
	}
	[item setTarget: self];
	[item setAction: @selector(setPreferenceView:)];
	[item setAutovalidates: NO];
	
	return item;
}

- (void) setPreferenceView:(id)sender
{	
	NSView *view = generalView;
	NSString * identifier = [sender itemIdentifier];
	if ([identifier isEqualToString:TOOLBAR_EDITOR]) {
		view = editorView;
	}
	else if ([identifier isEqualToString:TOOLBAR_REMOTE]) {
		view = remoteView;
	}
	else if ([identifier isEqualToString:TOOLBAR_HOTKEYS]) {
		view = hotkeysView;
	}
	else if ([identifier isEqualToString:TOOLBAR_UPDATE]) {
		view = updateView;
	}
	
	NSWindow * window = [self window];
	NSRect windowRect = [window frame];
    float difference = ([view frame].size.height - [[window contentView] frame].size.height);
    windowRect.origin.y -= difference;
    windowRect.size.height += difference;
	
	[window setContentView: view];
	[window setFrame: windowRect display: YES animate: YES];
}

@end

@implementation PreferenceController (General)
/**
 * OS X 10.10 and later support the NSStatusItemBar button which is what the
 * "Show Host File Name in Status Bar" feature is built upon.  So if we're
 * not 10.10 or above, then we need to disable the preference selection.
 */
- (void) initGeneral
{
    showHostFileNameButton.enabled = ![Util isPre10_10];
}
@end

@implementation PreferenceController (Remote)

- (void)initRemote
{
	NSArray *objects = [NSArray arrayWithObjects:
						[NSNumber numberWithInt:5],
						[NSNumber numberWithInt:15],
						[NSNumber numberWithInt:30],
						[NSNumber numberWithInt:60],
						[NSNumber numberWithInt:120],
						[NSNumber numberWithInt:300],
						[NSNumber numberWithInt:600],
						[NSNumber numberWithInt:1440],
						[NSNumber numberWithInt:10080],
						nil];
	NSArray *keys = [NSArray arrayWithObjects:
					 [NSNumber numberWithInt:1],
					 [NSNumber numberWithInt:2],
					 [NSNumber numberWithInt:3],
					 [NSNumber numberWithInt:4],
					 [NSNumber numberWithInt:5],
					 [NSNumber numberWithInt:6],
					 [NSNumber numberWithInt:7],
					 [NSNumber numberWithInt:8],
					 [NSNumber numberWithInt:9],
					 nil];

	remoteIntervals = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	
	[remoteIntervalSlider bind:@"value" toObject:self withKeyPath:@"remoteInterval" options:nil];
}

- (int)remoteInterval
{
	NSNumber *interval = [NSNumber numberWithInt:[Preferences remoteHostsUpdateInterval]];
	
	for (NSNumber *key in remoteIntervals) {
		if ([[remoteIntervals objectForKey:key] isEqual:interval]) {
			return [key integerValue];
		}
	}
	
	return 0;
}

- (void)setRemoteInterval:(int)interval
{
	NSNumber *value = [remoteIntervals objectForKey:[NSNumber numberWithInt:interval]];
	[Preferences setRemoteHostsUpdateInterval:[value intValue]];
}

@end


@implementation PreferenceController (Hotkeys)

- (void)initHotkeys
{
	id plist = [[[Preferences instance] defaults] valueForKey:ActivatePreviousFilePrefKey];
	Hotkey *hotkey = [[Hotkey alloc] initWithPlistRepresentation:plist];
	if (hotkey.keyCode > 0) {
		[activatePreviousHotkey setObjectValue:[SRShortcut shortcutWithCode:(SRKeyCode)hotkey.keyCode
		                                                      modifierFlags:SRCarbonToCocoaFlags((UInt32)hotkey.modifiers)
		                                                         characters:nil
		                                      charactersIgnoringModifiers:nil]];
	}

	plist = [[[Preferences instance] defaults] valueForKey:ActivateNextFilePrefKey];
	hotkey = [[Hotkey alloc] initWithPlistRepresentation:plist];
	if (hotkey.keyCode > 0) {
		[activateNextHotkey setObjectValue:[SRShortcut shortcutWithCode:(SRKeyCode)hotkey.keyCode
		                                                  modifierFlags:SRCarbonToCocoaFlags((UInt32)hotkey.modifiers)
		                                                     characters:nil
		                                  charactersIgnoringModifiers:nil]];
	}

	plist = [[[Preferences instance] defaults] valueForKey:UpdateAndSynchronizePrefKey];
	hotkey = [[Hotkey alloc] initWithPlistRepresentation:plist];
	if (hotkey.keyCode > 0) {
		[updateHotkey setObjectValue:[SRShortcut shortcutWithCode:(SRKeyCode)hotkey.keyCode
		                                            modifierFlags:SRCarbonToCocoaFlags((UInt32)hotkey.modifiers)
		                                               characters:nil
		                              charactersIgnoringModifiers:nil]];
	}
}

- (void)recorderControlDidEndRecording:(SRRecorderControl *)aControl
{
	SRShortcut *shortcut = aControl.objectValue;
	Hotkey *hotkey;
	if (shortcut) {
		hotkey = [[Hotkey alloc] initWithKeyCode:(int)shortcut.carbonKeyCode
		                               modifiers:(int)shortcut.carbonModifierFlags];
	} else {
		hotkey = [[Hotkey alloc] initWithKeyCode:-1 modifiers:-1];
	}

	NSString *prefKey;
	if (aControl == activatePreviousHotkey) {
		prefKey = ActivatePreviousFilePrefKey;
	}
	else if (aControl == activateNextHotkey) {
		prefKey = ActivateNextFilePrefKey;
	}
	else {
		prefKey = UpdateAndSynchronizePrefKey;
	}

	[[[Preferences instance] defaults] setValue:[hotkey plistRepresentation] forKey:prefKey];
}


@end