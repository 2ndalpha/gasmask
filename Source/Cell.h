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

@class Hosts;
@class BadgeManager;

@interface Cell : NSTextFieldCell {
	@private
	Hosts *item;
	
	NSImage *localFileIcon;
	NSImage *remoteFileIcon;
	NSImage *remoteDisabledFileIcon;
    NSImage *combinedFileIcon;
	NSImage *activeIcon;
	NSImage *unsavedIcon;
	
	BadgeManager *syncingArrowsBadgeManager;
	BadgeManager *alertBadgeManager;
	BadgeManager *offlineBadgeManager;
	
	BOOL offline;
}

- (void)setItem:(Hosts*)i;
- (void)removeAllBadges;

@end
