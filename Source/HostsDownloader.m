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

#import "HostsDownloader.h"
#import "RemoteHosts.h"
#import "ExtendedNSString.h"
#import "Error.h"
#import "ExtendedNSApplication.h"

#define kBufferSize 1024
#define kHeaderLastModified @"Last-Modified:"
#define kHeaderContentType @"Content-Type:"
#define kContentTypeHtml @"text/html"
#define kContentTypeImage @"image"
#define kContentTypeText @"text/plain"
#define kDefaultPort [NSNumber numberWithInt:80]

#define HTTP_1_0 @"HTTP/1.0 "
#define HTTP_1_1 @"HTTP/1.1 "
#define LINE_END @"\r\n"

@interface HostsDownloader (Private)

- (void)sendRequestHeader;
- (void)readResponse;
- (void)notifyDelegateHostsUpToDate;
- (void)notifyDelegateDownloadingStarted;
- (void)notifyDelegateDownloaded;
- (void)notifyDelegateDownloadFailed;

- (void)addBadContentTypeError:(NSString*)description;
- (void)addUnknownContentTypeError;

@end



@implementation HostsDownloader

@synthesize hosts;
@synthesize response;
@synthesize lastModified;
@synthesize error;
@synthesize initialLoad;


- (id)initWithHosts:(Hosts*)hostsValue url:(NSURL*)urlValue
{
	self = [super init];
	
	hosts = hostsValue;
	url = urlValue;
	
	headerRead = NO;
	
	return self;
}

- (void)setDelegate:(NSObject<HostsDownloaderDelegate>*)delegateValue
{
	delegate = delegateValue;
}

- (void)download
{
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		
		logDebug(@"Downloading: %@", url);
		
		response = [NSMutableString string];
		
		NSHost *host = [NSHost hostWithName:[url host]];
		
		NSNumber *port = [url port];
		if (port == nil) {
			port = kDefaultPort;
		}
        
        NSInputStream *newInputStream;
        NSOutputStream *newOutputStream;
		
		[NSStream getStreamsToHost:host port:[port intValue] inputStream:&newInputStream outputStream:&newOutputStream];
		
		// Failed to open connection
		if (newOutputStream == nil || newOutputStream == nil) {
			error = [[Error alloc] initWithType:ServerNotFound];
			[self notifyDelegateDownloadFailed];
			return;
		}
        
        inputStream = newInputStream;
        outputStream = newOutputStream;
        
		[inputStream setDelegate:self];
		[outputStream setDelegate:self];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
								   forMode:NSDefaultRunLoopMode];
			[outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
									forMode:NSDefaultRunLoopMode];
			
			[inputStream open];
			[outputStream open];
		});
        
	});
}

#pragma mark -
#pragma mark NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	switch (eventCode) {
		case NSStreamEventHasSpaceAvailable:
			if (stream == outputStream) {
				[self sendRequestHeader];
			}
			break;
		case NSStreamEventHasBytesAvailable:
			if (stream == inputStream) {
				[self readResponse];
				
				if (upToDate) {
					[self notifyDelegateHostsUpToDate];
				}
				else if (error) {
					[self notifyDelegateDownloadFailed];
				}
			}
			break;
		case NSStreamEventEndEncountered:
			if (stream == inputStream) {
				if ([response isEqual:[hosts contents]]) {
					[self notifyDelegateHostsUpToDate];
				}
				else {
					[self notifyDelegateDownloaded];
				}
			}
			break;
		case NSStreamEventErrorOccurred: {
			
			error = [[Error alloc] initWithType:FailedToDownload];
			NSString *description = @"Failed to download the hosts file";
			[error setDescription:description];
			[error setUrl:url];
			
			[inputStream close];
			[outputStream close];
			
			[self notifyDelegateDownloadFailed];
			break;
        }
        default:
            break;
	}
}

@end

@implementation HostsDownloader (Private)

- (void)sendRequestHeader
{
	logDebug(@"Sending request");
	
	NSMutableString *request = [NSMutableString new];
	[request appendFormat:@"GET %@ HTTP/1.0\r\n", [[url path] length] ? [url path] : @"/"];
	[request appendFormat:@"Host: %@\r\n", [url host]];
	[request appendFormat:@"User-Agent: Gas Mask/%@\r\n", [NSApplication version]];
	[request appendString:@"Accept: text/html,text/plain\r\n"];
	[request appendString:@"\r\n"];
	
	const uint8_t * raw = (const uint8_t *)[request UTF8String];
	[outputStream write:raw maxLength:[request length]];
	[outputStream close];
}

- (void)readResponse
{	
	uint8_t buf[kBufferSize];
	unsigned int len = 0;
	len = [inputStream read:buf maxLength:kBufferSize];

	if (len) {
		NSString *output = [[NSString alloc] initWithBytes:buf length:len encoding:NSASCIIStringEncoding];
		
		if (!headerRead) {
			NSArray *lines = [output componentsSeparatedByString:LINE_END];
			
			for (int i=0; i<[lines count]; i++) {
				NSString *line = [lines objectAtIndex:i];
				
				// End of the header
				if (!headerRead && [line length] == 0) {
					
					headerRead = YES;
					[self notifyDelegateDownloadingStarted];
					
					// Page did not specify content type - cancel download
					if (contentType == nil) {
						[self addUnknownContentTypeError];
						[inputStream close];
						[outputStream close];
						return;
					}
					
					continue;
				}
				
				if (headerRead) {
					[response appendString:line];
					if (i != [lines count]-1 || [output hasSuffix:LINE_END]) {
						[response appendString:LINE_END];
					}
				}
				else {
					if ([line hasPrefix:kHeaderLastModified]) {
						lastModified = [line substringFromIndex:[kHeaderLastModified length]];
						
						// Hosts File Is Up To Date
						if ([hosts isKindOfClass:[RemoteHosts class]] && [lastModified isEqual:[(RemoteHosts*)hosts lastModified]]) {
							[inputStream close];
							[outputStream close];
							upToDate = YES;
							return;
						}
					}
					else if ([line hasPrefix:kHeaderContentType]) {
						contentType = [line substringFromIndex:[kHeaderContentType length]];
						contentType = [contentType trim];
						
						if (![contentType hasPrefix:kContentTypeText]) {
							if ([contentType hasPrefix:kContentTypeHtml]) {
								[self addBadContentTypeError:@"Can't download the hosts file. It contains HTML page."];
							}
							else if ([contentType hasPrefix:kContentTypeImage]) {
								[self addBadContentTypeError:@"Can't download the hosts file. It contains image."];
							}
							else {
								logDebug(@"Content type: %@", contentType);
								[self addUnknownContentTypeError];
							}
						}
					}
					else if ([line hasPrefix:HTTP_1_0] || [line hasPrefix:HTTP_1_1]) {
						NSRange range = NSMakeRange([HTTP_1_0 length], 3);
						NSString *rawResponseCode = [line substringWithRange:range];
						int responseCode = [rawResponseCode intValue];
						if (responseCode >= 400) {
							error = [[Error alloc] initWithType:FileNotFound];
							NSString *description = [NSString stringWithFormat:
													 @"Failed to download the hosts file.\nRemote server responded with error code \"%@\".",
													 rawResponseCode];
							[error setDescription:description];
							[error setUrl:url];
						}
					}
				}
				
				if (error) {
					[inputStream close];
					[outputStream close];
					return;
				}
			}
		}
		else {
			[response appendString:output];
		}
	}
}

- (void)notifyDelegateHostsUpToDate
{
	SEL selector = @selector(hostsUpToDate:);
	if (delegate && [delegate respondsToSelector:selector]) {
		SuppressPerformSelectorLeakWarning(
            [delegate performSelector:selector withObject:self]);
	}
}

- (void)notifyDelegateDownloadingStarted
{
	SEL selector = @selector(hostsDownloadingStarted:);
	if (delegate && [delegate respondsToSelector:selector]) {
        SuppressPerformSelectorLeakWarning(
            [delegate performSelector:selector withObject:self]);
	}
}

- (void)notifyDelegateDownloaded
{
	logDebug(@"Downloading complete: %@", url);
	
	SEL selector = @selector(hostsDownloaded:);
	if (delegate && [delegate respondsToSelector:selector]) {
        SuppressPerformSelectorLeakWarning(
            [delegate performSelector:selector withObject:self]);
	}
}

- (void)notifyDelegateDownloadFailed
{
	SEL selector = @selector(hostsDownloadFailed:);
	if (delegate && [delegate respondsToSelector:selector]) {
        SuppressPerformSelectorLeakWarning(
            [delegate performSelector:selector withObject:self]);
	}
}

#pragma mark -
#pragma mark Errors

- (void)addBadContentTypeError:(NSString*)description
{
	error = [[Error alloc] initWithType:BadContentType];
	[error setDescription:description];
	[error setUrl:url];
	
}

- (void)addUnknownContentTypeError
{
	[self addBadContentTypeError:@"Can't download the hosts file. It contains unknown content."];
}

@end

