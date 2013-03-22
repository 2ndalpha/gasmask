//
//  BGHUDBox.h
//  BGHUDAppKit
//
//  Created by BinaryGod on 2/16/09.
//  Copyright 2009 none. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//		Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//
//		Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation and/or
//	other materials provided with the distribution.
//
//		Neither the name of the BinaryMethod.com nor the names of its contributors
//	may be used to endorse or promote products derived from this software without
//	specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS AS IS AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
//	OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
//	POSSIBILITY OF SUCH DAMAGE.

#import <Cocoa/Cocoa.h>
#import "BGThemeManager.h"

@interface BGHUDBox : NSBox {
	
	BOOL flipGradient;
	BOOL drawTopBorder;
	BOOL drawBottomBorder;
	BOOL drawLeftBorder;
	BOOL drawRightBorder;
	NSColor *borderColor;
	BOOL drawTopShadow;
	BOOL drawBottomShadow;
	BOOL drawLeftShadow;
	BOOL drawRightShadow;
	NSColor *shadowColor;
	NSGradient *customGradient;
	
	NSColor *color1;
	NSColor *color2;
	
	NSString *themeKey;
	BOOL useTheme;
}

@property BOOL flipGradient;
@property BOOL drawTopBorder;
@property BOOL drawBottomBorder;
@property BOOL drawLeftBorder;
@property BOOL drawRightBorder;
@property (retain) NSColor *borderColor;
@property BOOL drawTopShadow;
@property BOOL drawBottomShadow;
@property BOOL drawLeftShadow;
@property BOOL drawRightShadow;
@property (retain) NSColor *shadowColor;
@property (retain) NSGradient *customGradient;
@property (retain) NSColor *color1;
@property (retain) NSColor *color2;

@property (retain) NSString *themeKey;
@property BOOL useTheme;

@end
