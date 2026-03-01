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


NS_ASSUME_NONNULL_BEGIN

@interface HostsTextView : NSTextView<NSTextStorageDelegate> {
	@private
	BOOL syntaxHighlighting;
	NSColor *ipv4Color;
	NSColor *ipv6Color;
    NSColor *textColor;
    NSColor *commentColor;
	NSCharacterSet *nameCharacterSet;
	NSUInteger _highlightGeneration;
	BOOL _replacingContent;
}

- (void)setSyntaxHighlighting:(BOOL)value;
- (BOOL)syntaxHighlighting;
- (void)cancelPendingHighlighting;
- (void)replaceContentWith:(NSString *)newContent;

+ (nullable instancetype)createForProgrammaticUse;

@end

NS_ASSUME_NONNULL_END
