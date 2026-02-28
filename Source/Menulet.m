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

#import "Menulet.h"
#import "Hosts.h"
#import "HostsMainController.h"
#import "HostsMenu.h"
#import "Preferences.h"

@implementation Menulet

- (void)awakeFromNib
{
    NSImage *icon = [NSImage imageNamed:@"menuIcon"];

    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [[statusItem button] setEnabled:true];
    [[statusItem button] setTarget:self];
    [[statusItem button] setAction:@selector(showMenu:)];
    [[statusItem button] setImage:icon];
    [[statusItem button] setTitle:@""];
    [[statusItem button] setToolTip:@"Gas Mask"];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults addObserver:self
               forKeyPath:ShowNameInStatusBarKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];

    [defaults addObserver:self
               forKeyPath:ActiveHostsFilePrefKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateName) name:ActivateFileNotification object:NULL];

    if ([Preferences showNameInStatusBar]) {
        [self initTitleInBar];
    }
}

-(void) initTitleInBar {
    [statusItem setLength:NSVariableStatusItemLength];
    [[statusItem button] setImagePosition:NSImageLeft];
}

-(void)updateName {
    if (![Preferences showNameInStatusBar]) {
        return;
    }
    NSString *name = [[[HostsMainController defaultInstance] activeHostsFile] name];
    [[statusItem button] setTitle:name];
}

-(void) removeTitleFromBar {
    [statusItem setLength:NSSquareStatusItemLength];
    [[statusItem button] setImagePosition:NSImageOnly];
    [[statusItem button] setTitle:@""];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([ShowNameInStatusBarKey isEqualToString:keyPath]) {
        if ([Preferences showNameInStatusBar]) {
            [self initTitleInBar];
            [self updateName];
        } else {
            [self removeTitleFromBar];
        }
    } else if ([ActiveHostsFilePrefKey isEqualToString:keyPath]) {
        [self updateName];
    }
}

-(void)dealloc {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:ActiveHostsFilePrefKey];
    [defaults removeObserver:self forKeyPath:ShowNameInStatusBarKey];
}

-(IBAction)showMenu:(id)sender
{	
	HostsMenu *menu = [[HostsMenu alloc] initWithExtras];
	[statusItem popUpStatusItemMenu:menu];
}

@end