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

#import <Carbon/Carbon.h>

#import "GlobalHotkeys.h"
#import "Hotkey.h"
#import "Preferences.h"

#define ActivatePreviousFileHotkeyID 1
#define ActivateNextFileHotkeyID 2
#define UpdateAndSynchronizeHotkeyID 3

@interface GlobalHotkeys ()
- (void)registerHotkeyWithID:(int)hotkeyID preferenceKey:(NSString*)key;
- (void)unregisterHotkey:(EventHotKeyRef)hotkeyRef;
@end


@implementation GlobalHotkeys

OSStatus HotkeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
					   void *userData)
{	
	EventHotKeyID hkCom;
	GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL,
					  sizeof(hkCom), NULL, &hkCom);
	int l = hkCom.id;
	
	NSString *notificationName;
	
	switch (l) {
		case ActivatePreviousFileHotkeyID:
			notificationName = ActivatePreviousFileNotification;
			break;
		case ActivateNextFileHotkeyID:
			notificationName = ActivateNextFileNotification;
			break;
		case UpdateAndSynchronizeHotkeyID:
			notificationName = UpdateAndSynchronizeNotification;
			break;
        default:
            return noErr;
	}
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:notificationName object:nil];
	
	return noErr;
}

- (id)init
{
	self = [super init];
	ids = [[NSMutableDictionary alloc] init];
	
	EventTypeSpec eventType;
	eventType.eventClass = kEventClassKeyboard;
	eventType.eventKind = kEventHotKeyPressed;
	
	InstallApplicationEventHandler(&HotkeyHandler, 1, &eventType, NULL, NULL);
	
	[self registerHotkeyWithID:ActivatePreviousFileHotkeyID
				 preferenceKey:ActivatePreviousFilePrefKey];
	
	[self registerHotkeyWithID:ActivateNextFileHotkeyID
				 preferenceKey:ActivateNextFilePrefKey];
	
	[self registerHotkeyWithID:UpdateAndSynchronizeHotkeyID
				 preferenceKey:UpdateAndSynchronizePrefKey];
	
	return self;
}

- (void)registerHotkeyWithID:(int)hotkeyID preferenceKey:(NSString*)key
{
	NSUserDefaults *defaults = [[Preferences instance] defaults];
	
	id plist = [defaults valueForKey:key];
	Hotkey *hotkey = [[Hotkey alloc] initWithPlistRepresentation:plist];
	
	EventHotKeyID eventHotKeyID;
	eventHotKeyID.id = hotkeyID;
	EventHotKeyRef hotkeyRef;
	
	RegisterEventHotKey([hotkey keyCode],
						[hotkey modifiers],
						eventHotKeyID,
						GetApplicationEventTarget(),
						0,
						&hotkeyRef);
	if ([ids objectForKey:key] != nil) {
		[ids removeObjectForKey:key];
	}
	[ids setObject:[NSNumber numberWithInt:hotkeyID] forKey:key];
	
	[defaults addObserver:self
			   forKeyPath:key
				  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
				  context:hotkeyRef];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id old = [change objectForKey:@"old"];
    if (old != nil && ![old isKindOfClass:[NSNull class]] ) { //TODO: check nil or NSNull
        int oldKeyCode = [[old objectForKey:@"keyCode"] intValue];
        int oldModifiers = [[old objectForKey:@"modifiers"] intValue];
        
        id new = [change objectForKey:@"new"];
        int keyCode = [[new objectForKey:@"keyCode"] intValue];
        int modifiers = [[new objectForKey:@"modifiers"] intValue];
        
        if (oldKeyCode != keyCode || oldModifiers != modifiers) {
            
            [self unregisterHotkey:context];
            [self registerHotkeyWithID:[[ids objectForKey:keyPath] intValue] preferenceKey:keyPath];
        }
    }

}

- (void)unregisterHotkey:(EventHotKeyRef)hotkeyRef
{
	UnregisterEventHotKey(hotkeyRef);
}

@end
