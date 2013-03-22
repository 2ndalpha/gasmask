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

#import "Node.h"

@class Error;

@interface Hosts : Node {
	@protected
	NSString *path;
	NSString *contents;
	BOOL active;
	BOOL saved;
	BOOL enabled;
	BOOL editable;
	BOOL exists;
	Error *error;
}

@property (retain) NSString *path;
@property BOOL editable;
@property BOOL exists;

- (id)initWithPath:(NSString*)pathValue;
- (NSString*)contents;
/* Returns hosts file from the disk */
- (NSString*)contentsOnDisk;
- (void) setContents:(NSString*)newContentsValue;
- (NSString*) name;
- (void)setName:(NSString*)name;
- (NSString*)fileName;

- (NSString*)type;

- (void) setSaved:(BOOL) saved;
- (BOOL) saved;
- (void) save;

- (void) setActive:(BOOL) active;
- (BOOL) active;

- (BOOL)enabled;
- (void)setEnabled:(BOOL)_enabled;

- (Error*)error;
- (void)setError:(Error*)newErrorValue;

@end
