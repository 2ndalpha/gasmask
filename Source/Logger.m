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

#import "ExtendedNSThread.h"
#import "Logger.h"

void privateLogDebug(NSString *format, const char *method, ...)
{
	@autoreleasepool {
        va_list args;
        va_start(args, method);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	
        [Logger debug:message method:method];
        va_end(args);
	}
}

void privateLogInfo(NSString *format, const char *method, ...)
{
	@autoreleasepool {
        va_list args;
        va_start(args, method);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	
        [Logger info:message method:method];
        va_end(args);
	}
}

void privateLogWarn(NSString *format, const char *method, ...)
{
	@autoreleasepool {
        va_list args;
        va_start(args, method);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	
        [Logger warn:message method:method];
        va_end(args);
	}
}

void privateLogError(NSString *format, const char *method, ...)
{
	@autoreleasepool {
        va_list args;
        va_start(args, method);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        
        [Logger error:message method:method];
        va_end(args);
	}
}

@interface Logger (Private)

+ (void)printMessage:(NSString*)message method:(const char *)method level:(NSString*)level;

@end


@implementation Logger

+ (void)setup
{
	@autoreleasepool {
        NSString *component = [NSString stringWithFormat:@"Library/Logs/%@", kLogFile];
        NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:component];
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager removeItemAtPath:logPath error:nil];
	
        freopen([logPath fileSystemRepresentation], "a", stderr);
	}
}

+ (void)debug:(NSString*)message method:(const char *)method
{	
	[self printMessage:message method:method level:@"DEBUG"];
}

+ (void)info:(NSString*)message method:(const char *)method
{
	[self printMessage:message method:method level:@"INFO"];
}

+ (void)warn:(NSString*)message method:(const char *)method
{
	[self printMessage:message method:method level:@"WARN"];
}

+ (void)error:(NSString*)message method:(const char *)method
{
	[self printMessage:message method:method level:@"ERROR"];
}

@end

@implementation Logger (Private)

+ (void)printMessage:(NSString*)message method:(const char *)method level:(NSString*)level
{
	message = [message stringByAppendingString:@"\n"];
	
	NSArray *parts = [[NSString stringWithCString:method encoding:NSUTF8StringEncoding] componentsSeparatedByString:@" "];
	NSString *className = [[[parts objectAtIndex:0] componentsSeparatedByString:@"("] objectAtIndex:0];
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\-|\\+)\\[" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *matchResults = [regex matchesInString:className options:0 range:NSMakeRange(0, className.length)];
    if ([matchResults count] == 0)
        return;
        
    NSTextCheckingResult *result = matchResults[0];
    NSRange range = result.range;
	if (range.location != NSNotFound) {
		className = [className substringFromIndex:NSMaxRange(range)];
	}
	
	NSString *thread = [[NSThread currentThread] name];
	
	if (thread == nil) {
		if ([NSThread isMainThread]) {
			thread = @"main";
		}
		else {
            thread = [NSString stringWithFormat:@"thread-%lu", (unsigned long)[[NSThread currentThread] number]];
		}
	}
	
	level = [NSString stringWithFormat:@"[%@]", level];
	
	fprintf(stderr, "%-7s %-8s - %-25s - %s", [level UTF8String], [thread UTF8String], [className UTF8String], [message UTF8String]);
	fflush(stderr);
}

@end

