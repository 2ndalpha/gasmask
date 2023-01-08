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

#import "PreferenceController.h"
#import "Preferences.h"
#import "Preferences+Remote.h"
#import "LoginItem.h"
#import "Util.h"

#define TOOLBAR_GENERAL @"TOOLBAR_GENERAL"
#define TOOLBAR_EDITOR @"TOOLBAR_EDITOR"
#define TOOLBAR_REMOTE @"TOOLBAR_REMOTE"
#define TOOLBAR_HOTKEYS @"TOOLBAR_HOTKEYS"
#define TOOLBAR_UPDATE @"TOOLBAR_UPDATE"

@interface PreferenceController (Remote)
- (void)initRemote;
- (NSUInteger)remoteInterval;
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
    [[self window] setToolbarStyle:NSWindowToolbarStylePreference];
	
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
        [item setImage: [NSImage imageWithSystemSymbolName:@"gearshape" accessibilityDescription:@"General"]];
	}
	else if ([ident isEqualTo:TOOLBAR_EDITOR]) {
		[item setLabel: @"Editor"];
        [item setImage: [NSImage imageWithSystemSymbolName:@"square.and.pencil" accessibilityDescription:@"Editor"]];
	}
	else if ([ident isEqualTo:TOOLBAR_REMOTE]) {
		[item setLabel: @"Remote"];
        [item setImage: [NSImage imageWithSystemSymbolName:@"globe" accessibilityDescription:@"Remote"]];
	}
	else if ([ident isEqualTo:TOOLBAR_HOTKEYS]) {
		[item setLabel: @"Hotkeys"];
        [item setImage: [NSImage imageWithSystemSymbolName:@"command.square.fill" accessibilityDescription:@"Hotkeys"]];
	}
	else if ([ident isEqualTo:TOOLBAR_UPDATE]) {
		[item setLabel: @"Update"];
        [item setImage: [NSImage imageWithSystemSymbolName:@"arrow.triangle.2.circlepath" accessibilityDescription:@"Update"]];
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
    
    //center view
    float horizontalOffset = (NSWidth([window frame]) - NSWidth([view frame])) / 2;
    NSView *subView = [[NSView alloc] initWithFrame:[[window contentView] frame]];
    [subView addSubview:view];
    [view setFrame:NSMakeRect(horizontalOffset, 0, NSWidth(view.frame), NSHeight(view.frame))];
	
	[window setContentView: subView];
	[window setFrame: windowRect display: YES animate: YES];
}

@end

@implementation PreferenceController (General)

- (void) initGeneral
{
    showHostFileNameButton.enabled = YES;
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

- (NSUInteger)remoteInterval
{
	NSNumber *interval = [NSNumber numberWithInteger:[Preferences remoteHostsUpdateInterval]];
	
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
    //compatiability with ShortcutRecorder
    [[MASShortcutBinder sharedBinder] setBindingOptions:@{NSValueTransformerNameBindingOption:MASDictionaryTransformerName}];
    
    [_activatePreviousHotkey setAssociatedUserDefaultsKey:ActivatePreviousFilePrefKey withTransformerName:MASDictionaryTransformerName];
    [_activateNextHotkey setAssociatedUserDefaultsKey:ActivateNextFilePrefKey withTransformerName:MASDictionaryTransformerName];
    [_updateHotkey setAssociatedUserDefaultsKey:UpdateAndSynchronizePrefKey withTransformerName:MASDictionaryTransformerName];
    
    _activatePreviousHotkey.style = MASShortcutViewStyleTexturedRect;
    _activateNextHotkey.style = MASShortcutViewStyleTexturedRect;
    _updateHotkey.style = MASShortcutViewStyleTexturedRect;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:ActivatePreviousFilePrefKey toAction:^{
        [nc postNotificationName:ActivatePreviousFileNotification object:nil];
    }];
    
    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:ActivateNextFilePrefKey toAction:^{
        [nc postNotificationName:ActivateNextFileNotification object:nil];
    }];
    
    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:UpdateAndSynchronizePrefKey toAction:^{
        [nc postNotificationName:UpdateAndSynchronizeNotification object:nil];
    }];
}


@end
