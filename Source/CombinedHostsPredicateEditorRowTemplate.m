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

#import "CombinedHostsPredicateEditorRowTemplate.h"
#import "HostsMainController.h"
#import "RemoteHosts.h"
#import "Pair.h"
#import "CombinedHosts.h"

@interface CombinedHostsPredicateEditorRowTemplate (Private)
- (NSTextField*)label;
- (NSPopUpButton*)select;
- (void)populateSelectMenu;
- (IBAction)hostsFileRemoved:(NSNotification *)notification;
- (IBAction)hostsFileAdded:(NSNotification *)notification;
- (IBAction)hostsFileRenamed:(NSNotification *)notification;
@end

@implementation CombinedHostsPredicateEditorRowTemplate

- (void)awakeFromNib
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(hostsFileRemoved:) name:HostsFileRemovedNotification object:nil];
    [nc addObserver:self selector:@selector(hostsFileAdded:) name:HostsFileCreatedNotification object:nil];
    [nc addObserver:self selector:@selector(hostsFileRenamed:) name:HostsFileRenamedNotification object:nil];
}

- (NSArray *) templateViews
{   
    return [NSArray arrayWithObjects:[self label], [self select], nil];
}

- (double)matchForPredicate:(NSPredicate *)predicate
{
    return 1;
}

- (NSPredicate *)predicateWithSubpredicates:(NSArray *)subpredicates
{   

    NSMenuItem * item = [[self select] selectedItem];
    Hosts *hosts = (Hosts*)[item representedObject];
    if (hosts == nil) {
        return nil;
    }

    return [NSPredicate predicateWithFormat:@"type = %@ AND name = %@" argumentArray:[NSArray arrayWithObjects:[hosts type], [hosts name], nil]];
}

- (void)setPredicate:(NSPredicate *)predicate
{   
    NSMenu *menu = [[self select] menu];
    for (NSMenuItem * item in [menu itemArray]) {
        Hosts *hosts = [item representedObject];
        if ([predicate evaluateWithObject:hosts]) {
            [[self select] selectItem:item];
            return;
        }
    }
    
    [[self select] selectItemAtIndex:0];
}

@end

@implementation CombinedHostsPredicateEditorRowTemplate (Private)

- (NSTextField*)label
{
    if (textField == nil) {
        textField = [[NSTextField alloc] init];
        [textField setFrame:NSMakeRect(0, 0, 100, 15)];
        [textField setEditable:NO];
        [textField setSelectable:NO];
        [textField setBordered:NO];
        [textField setDrawsBackground:NO];
        [textField setAlignment:NSTextAlignmentCenter];
        [textField.cell setTitle:@"Hosts File:"];
    }
    return textField;
}

- (NSPopUpButton*)select
{
    if (select == nil) {
        select = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 200, 15) pullsDown:YES];
        [self populateSelectMenu];
    }
    return select;
}

- (void)populateSelectMenu
{
    [select removeAllItems];
    [select addItemWithTitle:@"                   "];
    
    NSMenu *menu = [select menu];
    
    NSArray *allHosts = [[HostsMainController defaultInstance] allHostsFiles];
    for (Hosts *hosts in allHosts) {
        if ([hosts isKindOfClass:[CombinedHosts class]]) {
            continue;
        }
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[hosts name] action:NULL keyEquivalent:@""];
        [item setRepresentedObject:hosts];
        [menu addItem:item];
    }
}

- (IBAction)hostsFileRemoved:(NSNotification *)notification
{
    Hosts *removedHosts = [notification object];
    NSMenu *menu = [[self select] menu];
    for (NSMenuItem * item in [menu itemArray]) {
        Hosts *hosts = [item representedObject];
        if ([removedHosts isEqualTo:hosts]) {
            [menu removeItem:item];
            break;
        }
    }
}

- (IBAction)hostsFileAdded:(NSNotification *)notification
{
    logDebug(@"Hosts file added: %@", [[notification object] name]);
    [self populateSelectMenu];
}

- (IBAction)hostsFileRenamed:(NSNotification *)notification
{
    [self populateSelectMenu];
}

@end
