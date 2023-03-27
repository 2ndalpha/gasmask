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
                  self->error = [[Error alloc] initWithType:FailedToDownload];
                  NSString *description = @"Failed to download the hosts file";
                  [self->error setDescription:description];
                  [self->error setUrl:self->url];
                  
                  [self notifyDelegateDownloadFailed];
                  return;
              }
              
              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)urlResponse;
              self->lastModified = [[httpResponse allHeaderFields] objectForKey:kHeaderLastModified];
              
              // Check If Hosts File Is Up To Date
              if ([self->hosts isKindOfClass:[RemoteHosts class]] && [self->lastModified isEqual:[(RemoteHosts*)self->hosts lastModified]]) {
                  self->upToDate = YES;
                  [self notifyDelegateHostsUpToDate];
                  return;
              }
              
              self->contentType = [[httpResponse allHeaderFields] objectForKey:kHeaderContentType];
              
              if (![self->contentType hasPrefix:kContentTypeText])
              {
                  if ([self->contentType hasPrefix:kContentTypeHtml]) {
                      [self addBadContentTypeError:@"Can't download the hosts file. It contains HTML page."];
                  }
                  else if ([self->contentType hasPrefix:kContentTypeImage]) {
                      [self addBadContentTypeError:@"Can't download the hosts file. It contains image."];
                  }
                  else {
                      logDebug(@"Content type: %@", self->contentType);
                      [self addUnknownContentTypeError];
                  }
                  [self notifyDelegateDownloadFailed];
                  return;
              }
              
              NSString * output = [[NSString alloc] initWithData:data
                                                        encoding:NSUTF8StringEncoding];
              self->response = [NSMutableString string];
              [self->response appendString:output];
              
              if ([self->response isEqual:[self->hosts contents]]) {
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

