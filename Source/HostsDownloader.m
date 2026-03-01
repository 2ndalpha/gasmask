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
#import "Error.h"

#define kHeaderLastModified @"Last-Modified"
#define kHeaderContentType @"Content-Type"
#define kContentTypeHtml @"text/html"
#define kContentTypeImage @"image"
#define kContentTypeText @"text/plain"

@interface HostsDownloader (Private)

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
	
	return self;
}

- (void)setDelegate:(NSObject<HostsDownloaderDelegate>*)delegateValue
{
	delegate = delegateValue;
}

- (void)download
{
    logDebug(@"Downloading: %@", url);
    
    NSURLSessionDataTask *task = [
          NSURLSession.sharedSession dataTaskWithURL:url
          completionHandler:^(NSData *data, NSURLResponse *urlResponse, NSError *taskError) {
              if (taskError || !data || data.length == 0) {
                  error = [[Error alloc] initWithType:FailedToDownload];
                  NSString *description = @"Failed to download the hosts file";
                  [error setDescription:description];
                  [error setUrl:url];
                  
                  [self notifyDelegateDownloadFailed];
                  return;
              }
              
              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)urlResponse;
              lastModified = [[httpResponse allHeaderFields] objectForKey:kHeaderLastModified];
              
              // Check If Hosts File Is Up To Date
              if ([hosts isKindOfClass:[RemoteHosts class]] && [lastModified isEqual:[(RemoteHosts*)hosts lastModified]]) {
                  upToDate = YES;
                  [self notifyDelegateHostsUpToDate];
                  return;
              }
              
              contentType = [[httpResponse allHeaderFields] objectForKey:kHeaderContentType];
              
              if (![contentType hasPrefix:kContentTypeText])
              {
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
                  [self notifyDelegateDownloadFailed];
                  return;
              }
              
              NSString * output = [[NSString alloc] initWithData:data
                                                        encoding:NSUTF8StringEncoding];
              response = [NSMutableString string];
              [response appendString:output];
              
              if ([response isEqual:[hosts contents]]) {
                  [self notifyDelegateHostsUpToDate];
              } else {
                  [self notifyDelegateDownloaded];
              }
          }];

    [self notifyDelegateDownloadingStarted];
    [task resume];
}

@end

@implementation HostsDownloader (Private)

- (void)notifyDelegateHostsUpToDate
{
	dispatch_async(dispatch_get_main_queue(), ^{
		SEL selector = @selector(hostsUpToDate:);
		if (delegate && [delegate respondsToSelector:selector]) {
			SuppressPerformSelectorLeakWarning(
				[delegate performSelector:selector withObject:self]);
		}
	});
}

- (void)notifyDelegateDownloadingStarted
{
	dispatch_async(dispatch_get_main_queue(), ^{
		SEL selector = @selector(hostsDownloadingStarted:);
		if (delegate && [delegate respondsToSelector:selector]) {
			SuppressPerformSelectorLeakWarning(
				[delegate performSelector:selector withObject:self]);
		}
	});
}

- (void)notifyDelegateDownloaded
{
	dispatch_async(dispatch_get_main_queue(), ^{
		logDebug(@"Downloading complete: %@", url);

		SEL selector = @selector(hostsDownloaded:);
		if (delegate && [delegate respondsToSelector:selector]) {
			SuppressPerformSelectorLeakWarning(
				[delegate performSelector:selector withObject:self]);
		}
	});
}

- (void)notifyDelegateDownloadFailed
{
	dispatch_async(dispatch_get_main_queue(), ^{
		SEL selector = @selector(hostsDownloadFailed:);
		if (delegate && [delegate respondsToSelector:selector]) {
			SuppressPerformSelectorLeakWarning(
				[delegate performSelector:selector withObject:self]);
		}
	});
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

