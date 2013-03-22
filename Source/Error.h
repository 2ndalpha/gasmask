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

enum {
	NetworkOffline = 1,
	ServerNotFound = 2,
	FileNotFound = 3,
	FailedToDownload = 4,
	BadContentType = 5,
	InvalidMobileMeAccount = 6
};
typedef NSUInteger ErrorType;


@interface Error : NSObject {
@private
	ErrorType type;
	NSString *description;
	NSURL *url;
}

+ (Error*)errorWithType:(ErrorType)errorType;
- (id)initWithType:(ErrorType)errorType;

@property (readonly) ErrorType type;
@property (retain) NSString *description;
@property (retain) NSURL *url;

@end
