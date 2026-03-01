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

#import "HostsTextView.h"
#import "ExtendedNSString.h"
#import "IP.h"

@interface HostsTextView (HighLight)
-(void)colorText: (NSTextStorage*)textStorage;
-(void)removeColors;
-(void)removeMarks: (NSTextStorage*)textStorage range: (NSRange)range;
-(void)markComment: (NSTextStorage*)textStorage range:(NSRange)range;
-(void)markIPv4: (NSTextStorage*)textStorage range:(NSRange)range;
-(void)markIPv6: (NSTextStorage*)textStorage range:(NSRange)range;
-(void)markInvalid: (NSTextStorage*)textStorage range:(NSRange)range;
-(NSRange)changedLinesRange: (NSTextStorage*)textStorage;
-(BOOL)validName:(NSString*)contents range:(NSRange)nameRange;
@end

@interface HostsTextView (Selection)
-(NSRange)selectRangeFromDoubleClick:(NSUInteger)location range:(NSRange)range;
@end

@implementation HostsTextView

- (void)setupColors
{
	ipv4Color = [NSColor colorWithCalibratedRed:0.27 green:0.36 blue:0.61 alpha:1];
	ipv6Color = [NSColor colorWithCalibratedRed:0.27 green:0.36 blue:0.8 alpha:1];
    textColor = [NSColor colorNamed:@"TextColor"];
    commentColor = [NSColor colorNamed:@"CommentColor"];
	nameCharacterSet = [NSCharacterSet characterSetWithCharactersInString: @"abcdefghijklmnopqrstuvwxyz0123456789.-"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	[self setupColors];
	return self;
}

+ (instancetype)createForProgrammaticUse
{
    NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [container setWidthTracksTextView:NO];

    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:container];

    NSTextStorage *textStorage = [[NSTextStorage alloc] init];
    [textStorage addLayoutManager:layoutManager];

    HostsTextView *textView = [[HostsTextView alloc] initWithFrame:NSZeroRect textContainer:container];
    [textView setupColors];

    [textStorage setDelegate:textView];
    [textView setHorizontallyResizable:YES];
    [textView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [textView setFont:[NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightMedium]];
    [textView setBackgroundColor:[NSColor colorNamed:@"BackgroundColor"]];
    [textView setTextColor:[NSColor colorNamed:@"TextColor"]];

    return textView;
}

- (void)awakeFromNib
{
	[[super textStorage] setDelegate:self];
	
    // Enable horizontal scroll
    [[self enclosingScrollView] setHasHorizontalScroller:YES];
    [self setHorizontallyResizable:YES];
    [self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [[self textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[self textContainer] setWidthTracksTextView:NO];
    
    if (@available(macOS 10_13, *)) {
        [self setBackgroundColor:[NSColor colorNamed:@"BackgroundColor"]];
        [self setTextColor:[NSColor colorNamed:@"TextColor"]];
    }
}

/*
 Overrides proposed selection range for double clicks.
 */
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange
                              granularity:(NSSelectionGranularity)granularity
{
    NSRange range = [super selectionRangeForProposedRange:proposedSelRange
                                              granularity:granularity];
    
    NSEvent *event = [NSApp currentEvent];
	if ([event type] == NSLeftMouseUp && [event clickCount] == 2) {
        return [self selectRangeFromDoubleClick:proposedSelRange.location range:range];
    }
    
    return range;
}

-(void)setSyntaxHighlighting:(BOOL)value
{
	syntaxHighlighting = value;
	if (syntaxHighlighting) {
		[self colorText:[self textStorage]];
	}
	else {
		[self removeColors];
	}
}
-(BOOL)syntaxHighlighting
{
	return syntaxHighlighting;
}

@end

@implementation HostsTextView (HighLight)

-(void)colorText: (NSTextStorage*)textStorage
{
	
	NSRange range = [self changedLinesRange: textStorage];
	NSString *contents = [[textStorage string] substringWithRange:range];
	
	if ([contents length] == 0) {
		return;
	}
	
	[self removeMarks: textStorage range: range];
	
	NSArray *array = [contents componentsSeparatedByString: @"\n"]; // 37ms
	
	int pos = 0;
	IP *ip = [[IP alloc] initWithString:contents];
	
	for (NSString *line in array) {
		NSRange ipRange = NSMakeRange(NSNotFound, NSNotFound);
		NSRange namesRange = NSMakeRange(NSNotFound, NSNotFound);
		
		int i;
		for (i=0; i<[line length]; i++) {
			unichar character = [line characterAtIndex:i];
			// Start of comment
			if (character == '#') {
				
				// End of names
				if (namesRange.location != NSNotFound) {
					namesRange.length = pos-namesRange.location;
				}
				
				NSRange range2 = NSMakeRange(range.location+pos, [line length]-i);
				[self markComment:textStorage range:range2];
				
				pos += [line length]-i;
				break;
			}
			// Start of IP
			else if (ipRange.location == NSNotFound && character != ' ' && character != '\t') {
				ipRange.location = pos;
			}
			// Start of names
			else if (namesRange.location == NSNotFound && ipRange.length != NSNotFound) {
				namesRange.location = pos;
			}
			// End of IP
			else if (ipRange.location != NSNotFound && ipRange.length == NSNotFound && (character == ' ' || character == '\t')) {
				ipRange.length = pos-ipRange.location;
			}
			pos++;
		}
		
		if (ipRange.location != NSNotFound && ipRange.length == NSNotFound) {
			ipRange.length = pos-ipRange.location;
		}
		
		if (ipRange.location != NSNotFound && ipRange.length != NSNotFound) {
			[ip setRange:ipRange];
			
			ipRange.location += range.location;
			
			if ([ip isValid]) {
				if ([ip isVersion4]) {
					[self markIPv4:textStorage range:ipRange];
				}
				else {
					[self markIPv6:textStorage range:ipRange];
				}
			}
			else {
				NSRange badIPRange = [ip invalidRange];
				badIPRange.location += ipRange.location;
				
				[self markInvalid: textStorage range:badIPRange];
			}
		}
		
		if (namesRange.length == NSNotFound) {
			namesRange.length = pos-namesRange.location;
			
			if ([line hasSuffix:@"\r"]) {
				namesRange.length--;
			}
		}
		// Color names
		if (namesRange.location != NSNotFound) {
			
			NSRange nameRange = NSMakeRange(namesRange.location, NSNotFound);
			
			int end = NSMaxRange(namesRange);
			for (int i=namesRange.location; i<end; i++) {
				unichar character = [contents characterAtIndex:i];
				
				if (nameRange.length == NSNotFound) {
					if (character == ' ' || character == '\t') {
						nameRange.length = i-nameRange.location;
					}
					// End of line
					else if (i == end-1) {
						nameRange.length = i-nameRange.location+1;
					}
					
					if (nameRange.length != NSNotFound && nameRange.length > 0) {
						if (![self validName:contents range:nameRange]) {
							[self markInvalid:textStorage range:NSMakeRange(range.location+nameRange.location, nameRange.length)];
						}
					}
				}
				else if (character != ' ' && character != '\t') {
					nameRange.location = i;
					nameRange.length = NSNotFound;
				}
			}
		}
		
		// Move over newline
		pos++;
	}
}

-(void)removeColors
{
	NSTextStorage *textStorage = [self textStorage];
	NSRange range = NSMakeRange(0, [[textStorage string] length]);
	[self removeMarks:textStorage range:range];
}

-(void)removeMarks: (NSTextStorage*)textStorage range: (NSRange)range
{	
	[textStorage removeAttribute:NSForegroundColorAttributeName range:range];
	[textStorage removeAttribute:NSUnderlineStyleAttributeName range:range];
	[textStorage removeAttribute:NSUnderlineColorAttributeName range:range];
    
    [textStorage addAttribute:NSForegroundColorAttributeName value:textColor range:range];
}

-(void)markComment: (NSTextStorage*)textStorage range: (NSRange)range
{
	[textStorage addAttribute:NSForegroundColorAttributeName value:commentColor range:range];
}

-(void)markIPv4: (NSTextStorage*)textStorage range:(NSRange)range
{
	[textStorage addAttribute:NSForegroundColorAttributeName value:ipv4Color range:range];
}

-(void)markIPv6: (NSTextStorage*)textStorage range:(NSRange)range
{
	[textStorage addAttribute:NSForegroundColorAttributeName value:ipv6Color range:range];
}

-(void)markInvalid: (NSTextStorage*)textStorage range:(NSRange)range
{
	NSNumber *style = [NSNumber numberWithUnsignedInt:NSUnderlineStyleSingle | NSUnderlinePatternDot];
	[textStorage addAttribute: NSUnderlineStyleAttributeName value:style range: range];
	[textStorage addAttribute: NSUnderlineColorAttributeName value:[NSColor redColor] range: range];
}

-(NSRange)changedLinesRange: (NSTextStorage*)textStorage
{
	NSRange range = [textStorage editedRange];
	NSString *string = [textStorage string];
	
	if ([string length] == 0) {
		return NSMakeRange(0, 0);
	}
	if (range.location > [string length]-1) {
		return NSMakeRange(0, [string length]);
	}
	
	return [string lineRangeForRange:range];
}

-(BOOL)validName:(NSString*)contents range:(NSRange)nameRange
{	
	unichar previousCharacter;
	unichar character;
	
	int length = NSMaxRange(nameRange);
	for (int i=nameRange.location; i<length; i++) {
		character = [contents characterAtIndex:i];
		
		// First or last characher of the name
		if (i == nameRange.location || i == length-1) {
			if (character == '-' || character == '.') {
				return NO;
			}
		}
		else if ((previousCharacter == '.' || previousCharacter == '.') && (character == '.' || character == '-')) {
			return NO;
		}
		
		if (![nameCharacterSet characterIsMember:character]) {
			return NO;
		}
				
		previousCharacter = character;
	}
	
	return YES;
}

#pragma mark - NSTextStorageDelegate

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
	if (syntaxHighlighting && [[self textStorage] editedMask] != NSTextStorageEditedAttributes) {
		[self colorText:[notification object]];
	}
}

@end

@implementation HostsTextView (Selection)

/*
 Selects token between two dots.
 Example: instead of selecting "www.goo|gle.com" it selects "google". Note: "|" represents
 cursor location.
*/
-(NSRange)selectRangeFromDoubleClick:(NSUInteger)location range:(NSRange)range
{
    NSString *selectedString = [[self string] substringWithRange:range];
    NSInteger clickPosition = location - range.location;
    
    NSInteger length = [selectedString length];
    for (int i=clickPosition; i<length; i++) {
        unichar character = [selectedString characterAtIndex:i];
        if (character == '.') {
            range.length = i;
            break;
        }
    }
    for (int i=clickPosition; i>0; i--) {
        unichar character = [selectedString characterAtIndex:i];
        if (character == '.') {
            range.location += i + 1;
            range.length -= i + 1;
            break;
        }
    }
    
    return range;
}

@end
