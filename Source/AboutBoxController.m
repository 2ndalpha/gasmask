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

#import "AboutBoxController.h"
#import "ExtendedNSApplication.h"
#import "ExtendedNSTextView.h"


@implementation AboutBoxController

- (id)init
{
	return [super initWithWindowNibName:@"AboutBox"];
}

- (void)awakeFromNib
{
	[versionField setStringValue:[@"Version " stringByAppendingString:[NSApplication version]]];
	[emailField setURL:[NSURL URLWithString:[@"mailto:" stringByAppendingString:[[emailField textStorage] string]]]];
	[homePageField setURL:[NSURL URLWithString:[[homePageField textStorage] string]]];
    [[self window] center];
}

@end
