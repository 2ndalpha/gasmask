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

#import "CombinedHostsPredicateController.h"
#import "CombinedHostsPredicateEditorRowTemplate.h"
#import "HostsMainController.h"
#import "CombinedHosts.h"
#import "Hosts.h"
#import "ExtendedNSArray.h"
#import "ExtendedNSPredicate.h"

@interface CombinedHostsPredicateController (Private)
- (void)updateHostsFileContents;
- (void)fillTemplate;
@end

@implementation CombinedHostsPredicateController

- (id)init
{
    self = [super init];
    rowCount = 1;
    
    return self;
}

- (void)awakeFromNib
{
    //[self bind:@"selectedFile" toObject:[HostsMainController defaultInstance] withKeyPath:@"selection" options:nil];
    
    [predicateEditor setRowHeight:25];
    
    [predicateEditor setObjectValue:[NSPredicate predicateWithFormat:@"name = ''"]];
    
    [self setSelectedFile:[[HostsMainController defaultInstance] activeHostsFile]];
}

- (IBAction)predicateEditorChanged:(id)sender
{    
    [self updateHostsFileContents];

    NSInteger newRowCount = [predicateEditor numberOfRows];
    
    if (newRowCount == rowCount) {
        return;
    }
    
    BOOL growing = (newRowCount > rowCount);
    
    CGFloat heightDifference = fabs([predicateEditor rowHeight] * (newRowCount - rowCount));
    NSSize sizeChange = [predicateEditor convertSize:NSMakeSize(0, heightDifference) toView:nil];
    
    NSScrollView *predicateEditorScrollView = [predicateEditor enclosingScrollView];
    
    NSRect frame = [predicateEditorScrollView frame];
    frame.size.height += growing? sizeChange.height : -sizeChange.height;
    frame.origin.y += growing? -sizeChange.height : sizeChange.height;
    [predicateEditorScrollView setFrame:frame];
    
    frame = [lowerScrollView frame];
    frame.origin.y += growing? -sizeChange.height : sizeChange.height;
    [lowerScrollView setFrame:frame];
    
    rowCount = newRowCount;
    
    [selectedHostsFile setSaved:NO];
}

- (void)setSelectedFile:(Hosts*)value
{
    Hosts *hosts = [[HostsMainController defaultInstance] selectedHosts];
    NSScrollView *scrollView = [predicateEditor enclosingScrollView];
    
    if ([hosts isMemberOfClass:[CombinedHosts class]]) {
        NSUInteger previousRowCount = rowCount;
        [scrollView setHidden:NO];
        [predicateEditor reloadCriteria];
        
        selectedHostsFile = (CombinedHosts*)hosts;
        [self fillTemplate];
        
        int rowHeight = [predicateEditor rowHeight];
        rowCount = [predicateEditor numberOfRows];
        NSUInteger height = rowCount * rowHeight;
        NSUInteger difference = (rowCount - previousRowCount) * rowHeight;
        
        NSRect frame = [lowerScrollView frame];
        frame.origin.y = 0;
        frame.size.height = [parentView frame].size.height - height;
        [lowerScrollView setFrame:frame];
        
        NSRect frame2 = [scrollView frame];
        frame2.size.height = height;       
        frame2.origin.y -= difference;
        [scrollView setFrame:frame2];
        
        if ([[selectedHostsFile hostsFiles] count] == 0 && hintView == nil) {
            hintView = [[NSImageView alloc] initWithFrame:NSMakeRect(140, -20, 210, 99)];
            [hintView setImage:[NSImage imageNamed: @"Combined Hosts Hint.png"]];
            [lowerScrollView addSubview:hintView];
        }
        else if (hintView != nil) {
            [hintView removeFromSuperview];
            hintView = nil;
        }
        
    } else {
        [scrollView setHidden:YES];
        NSRect frame = [lowerScrollView frame];
        frame.size.height = [parentView frame].size.height;
        frame.origin.y = 0;
        [lowerScrollView setFrame:frame];
        
        if (hintView != nil) {
            [hintView removeFromSuperview];
            hintView = nil;
        }
    }
}
- (Hosts*)selectedFile
{
    return selectedHostsFile;
}

@end

@implementation CombinedHostsPredicateController (Private)

- (void)updateHostsFileContents
{
    if (selectedHostsFile == nil) {
        return;
    }

    logDebug(@"Updating hosts file: \"%@\"", [selectedHostsFile name]);
    
    NSPredicate *predicate = [predicateEditor predicate];
    if (predicate == nil) {
        return;
    }
    
    NSArray *predicates;
    
    if ([predicateEditor numberOfRows] > 1 && [predicate containsNestedPredicates]) {
        NSCompoundPredicate * compound = (NSCompoundPredicate*)predicate;
        predicates = [compound subpredicates];
    }
    else {
        predicates = [NSArray arrayWithObject:predicate];
    }

    NSArray *files = [[[HostsMainController defaultInstance] allHostsFiles] filteredOrderedArrayUsingPredicates:predicates];
    
    [selectedHostsFile setHostsFiles:files];
    
    if (hintView != nil) {
        [hintView removeFromSuperview];
        hintView = nil;
    }
}

- (void)fillTemplate
{
    BOOL emptyPredicate = YES;
    NSMutableArray *predicates = [NSMutableArray new];
    for (Hosts *hosts in [selectedHostsFile hostsFiles]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@ AND name = %@" argumentArray:[NSArray arrayWithObjects:[hosts type], [hosts name], nil]];
        [predicates addObject:predicate];
        emptyPredicate = NO;
    }
    
    if (emptyPredicate) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"name = ''"]];
    }
    
    NSPredicate *compound = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
    [predicateEditor setObjectValue:compound];
}

@end
