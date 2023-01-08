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

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <SystemConfiguration/SCNetworkReachability.h>

#import "Network.h"

@interface Network (Private)

- (BOOL)networkSatatus;
- (void)findOnlineStatus;

@end

static Network *sharedInstance = nil;

@implementation Network

@synthesize online, internetReachability;

- (id)init
{
    if (sharedInstance) {
        return sharedInstance;
    }
	if (self = [super init]) {
		sharedInstance = self;
	}
    
    internetReachability = [Reachability reachabilityForInternetConnection];
    return sharedInstance;	
}

+ (Network*)defaultInstance
{
	if (!sharedInstance) {
		sharedInstance = [[Network alloc] init];
	}
	return sharedInstance;
}

- (void)startListeningForChanges
{
	logDebug(@"Starting listening for network changes");
	
    [internetReachability startNotifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    [self findOnlineStatus];
}

- (void)stopListenening
{
    [internetReachability stopNotifier];
    logDebug(@"stopped listening for network changes");
}

- (void) reachabilityChanged:(NSNotification *)note {
    Reachability* reachability = [note object];
    NetworkStatus netStatus = [reachability currentReachabilityStatus];

    BOOL isOnline = YES;
    if (netStatus == NotReachable) {
        logDebug(@"Network went down");
        isOnline = NO;
    }
    else {
        logDebug(@"Network came up");
        isOnline = YES;
    }
    
    if (isOnline == online) {
        return;
    }

    [self setOnline:isOnline];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:NetworkStatusChangedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:self.online] forKey:@"reachable"]];
}

@end

@implementation Network (Private)

-(BOOL)networkSatatus
{
    NetworkStatus networkStatus = [internetReachability currentReachabilityStatus];
    
    BOOL isOnline = YES;
    if (networkStatus == NotReachable) {
        isOnline = NO;
    }
    return isOnline;
}

- (void)findOnlineStatus
{
    BOOL isOnline = [self networkSatatus];
    if (isOnline == NO) {
        logDebug(@"Network is not reachable");
    }
    else {
        logDebug(@"Network is reachable");
    }
    [self setOnline:isOnline];
}

@end

