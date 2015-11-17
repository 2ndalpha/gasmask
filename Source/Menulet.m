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
#import "Util.h"

@implementation Menulet

- (void)awakeFromNib
{
    if ([Util isPre10_10]) {
        logDebug(@"Initializing Status Bar with pre-Yosemite options");
        [self awakeFromNibPre10_10];
    } else {
        logDebug(@"Initializing Status Bar with Yosemite and later options");
        [self awakeFromNib10_10AndAfter];
    }
}
/**
 * OS X 10.10 and later support the NSStatusItemBar button which is what the
 * "Show Host File Name in Status Bar" feature is built upon.  So if we're
 * not 10.10 or above, then we need to build the status bar button in the
 * legacy (pre 10.10) way adn not support the file name in the bar.
 */
- (void)awakeFromNibPre10_10
{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setHighlightMode:YES];
    [statusItem setEnabled:YES];
    [statusItem setToolTip:@"Gas Mask"];
    [statusItem setTitle:@""];
    [statusItem setAction:@selector(showMenu:)];
    [statusItem setTarget:self];
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"menuIcon" ofType:@"tiff"];
    NSImage *icon = [[NSImage alloc] initWithContentsOfFile:path];
    [icon setTemplate:YES];
    [statusItem setImage:icon];
}
/**
 * Build the status bar using 10.10+ compatible NSStatusBar's button
 * member.  We also need to add some observers to the preferences so that
 * we can tear down or re initialize the button if someone changes their
 * preferences.  
 */
- (void)awakeFromNib10_10AndAfter
{	
    
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"menuIcon" ofType:@"tiff"];
	NSImage *icon = [[NSImage alloc] initWithContentsOfFile:path];
    [icon setTemplate:YES];

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

// Only used in 10.10 and above
-(void) initTitleInBar {
    [statusItem setLength:NSVariableStatusItemLength];
    [[statusItem button] setImagePosition:NSImageLeft];
}

// Only used in 10.10 and above
-(void)updateName {
    if (![Preferences showNameInStatusBar]) {
        return;
    }
    NSString *name = [[[HostsMainController defaultInstance] activeHostsFile] name];
    [[statusItem button] setTitle:name];
}

// Only used in 10.10 and above
-(void) removeTitleFromBar {
    [statusItem setLength:NSSquareStatusItemLength];
    [[statusItem button] setImagePosition:NSImageOnly];
    [[statusItem button] setTitle:@""];
}

// Only used in 10.10 and above
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
    // we only need clean up if we're 10.10 and above.
    if (![Util isPre10_10]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObserver:self forKeyPath:ActiveHostsFilePrefKey];
        [defaults removeObserver:self forKeyPath:ShowNameInStatusBarKey];
    }
}

-(IBAction)showMenu:(id)sender
{	
	HostsMenu *menu = [[HostsMenu alloc] initWithExtras];
	[statusItem popUpStatusItemMenu:menu];
}

@end