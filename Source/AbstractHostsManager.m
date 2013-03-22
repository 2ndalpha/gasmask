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

#import "AbstractHostsManager.h"
#import "Network.h"
#import "Error.h"
#import "Hosts.h"

@implementation AbstractHostsManager

- (id)initWithHostsController:(NSObject<HostsControllerProtocol>*)hostsControllerValue
{
	self = [super init];
	
	hostsController = hostsControllerValue;
    hostsDownloaders = [NSMutableArray new];
	
	return self;
}

- (void)initializeHosts:(Hosts*)hosts url:(NSURL*)url
{
	logDebug(@"Initializing hosts: \"%@\"", [hosts name]);
	
	if (![[Network defaultInstance] online]) {
		Error *error = [[Error alloc] initWithType:NetworkOffline];
		[error setDescription:@"Can't update hosts file because you are not connected to the Internet."];
		[hosts setError:error];
		[hosts setExists:NO];
		[hosts setEnabled:YES];
		return;
	}
	
	HostsDownloader *downloader = [[HostsDownloader alloc] initWithHosts:hosts url:url];
    [self addDownloader:downloader];
    
	[downloader setInitialLoad:YES];
	[downloader setDelegate:self];
	[downloader download];
	
}

#pragma mark -
#pragma mark RemoteHostsDownloaderDelegate

- (void)hostsUpToDate:(HostsDownloader*)downloader
{
    logDebug(@"Hosts up to date");
	Hosts *hosts = [downloader hosts];
	logDebug(@"Hosts file \"%@\" is up-to-date", [hosts name]);
	[self decreaseActiveDownloadsCount];
    [self removeDownloader:downloader];
	
	[hosts setEnabled:YES];
}

- (void)hostsDownloadingStarted:(HostsDownloader*)downloader
{
	logDebug(@"Downloading started");
	[self increaseActiveDownloadsCount];
	[[downloader hosts] setEnabled:NO];
}

- (void)hostsDownloaded:(HostsDownloader*)downloader
{
	logDebug(@"Hosts downloaded");
	[self decreaseActiveDownloadsCount];
	
	Hosts *hosts = [downloader hosts];
	[hosts setEnabled:YES];
	[hosts setContents:[downloader response]];
	if ([downloader error]) {
		[hosts setError:[downloader error]];
	}
	
	[hostsController saveHosts:hosts];
	[hosts setExists:YES];
	[hosts setEditable:YES];
	
	[self removeDownloader:downloader];
}

- (void)hostsDownloadFailed:(HostsDownloader*)downloader
{
	logError(@"Downloading failed");
	
	Hosts *hosts = [downloader hosts];
	[hosts setEnabled:YES];
	
	if ([downloader error]) {
		[hosts setError:[downloader error]];
	}
	
	[self removeDownloader:downloader];
}

#pragma mark -
#pragma mark Protected

- (void)addDownloader:(HostsDownloader*)downloader
{
	if ([hostsDownloaders count] == 0) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:ThreadBusyNotification object:nil];
	}
	
	[hostsDownloaders addObject:downloader];
}

- (void)removeDownloader:(HostsDownloader*)downloader
{
	[hostsDownloaders removeObject:downloader];
	if ([hostsDownloaders count] == 0) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:ThreadNotBusyNotification object:nil];
	}
}

- (int)numberOfDownloaders
{
    return [hostsDownloaders count];
}

- (void)increaseActiveDownloadsCount
{
	if (activeDownloads == 0) {
		[[hostsController hostsGroup] setSynchronizing:YES];
	}
	activeDownloads++;
}

- (void)decreaseActiveDownloadsCount
{
	activeDownloads--;
	if (activeDownloads == 0) {
		[[hostsController hostsGroup] setSynchronizing:NO];
	}
}

@end

