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
#import <Shortcut.h>

@class SRRecorderControl;
@class LoginItem;

@interface PreferenceController : NSWindowController<NSToolbarDelegate> {
	@private
	IBOutlet NSView *generalView, *editorView, *hotkeysView, *updateView, *remoteView;
    LoginItem *loginItem;
	
    __unsafe_unretained IBOutlet NSButton *showHostFileNameButton;
    
	// Remote
	IBOutlet NSSlider *remoteIntervalSlider;
	NSDictionary *remoteIntervals;
}

// Hotkeys
@property (strong) IBOutlet MASShortcutView *activatePreviousHotkey;
@property (strong) IBOutlet MASShortcutView *activateNextHotkey;
@property (strong) IBOutlet MASShortcutView *updateHotkey;

- (void) setPreferenceView:(id)sender;

@end
