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

#import "NSImage+Additions.h"
#import "Util.h"

@implementation NSImage (Additions)

- (NSImage *)rotate:(NSUInteger)degrees
{
    NSSize size = [self size];
    
    [self lockFocus];
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context setImageInterpolation:NSImageInterpolationHigh];
    
    NSAffineTransform *rotateTF = [NSAffineTransform transform];
    
    [rotateTF translateXBy:( 0.5 * size.width) yBy: ( 0.5 * size.height)];
    [rotateTF rotateByDegrees:degrees];
    [rotateTF translateXBy:( -0.5 * size.width) yBy: ( -0.5 * size.height)];
    [rotateTF concat];
    
    [self drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];
    [self unlockFocus];
    [context restoreGraphicsState];
    
    return self;
}

- (NSImage *)applyTint:(NSColor *)tint
{
    if (tint) {
        [self lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [self size]};
        NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);
        [self unlockFocus];
    }
    return self;
}

- (NSImage *)convertToTemplateIcon
{
    BOOL isDarkMode = [Util isDarkMode];
    NSColor *color = isDarkMode ? NSColor.highlightColor : NSColor.darkGrayColor;
    [self applyTint:color];
    
    return self;
}

@end
