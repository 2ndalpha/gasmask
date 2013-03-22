//
//  NotificationHelper.m
//  Gas Mask
//
//  Created by Siim Raud on 16.11.12.
//  Copyright (c) 2012 Clockwise. All rights reserved.
//

#import "NotificationHelper.h"

@interface NotificationHelper(Private)
+ (void)notifyGrowl:(NSString*)title message:(NSString*)message;
+ (void)notifyNative:(NSString*)title message:(NSString*)message;
@end

@implementation NotificationHelper

+ (void)notify:(NSString*)title message:(NSString*)message
{
    if (floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_8) {
        [NotificationHelper notifyGrowl:title message:message];
    } else {
        [NotificationHelper notifyNative:title message:message];
    }
}

@end

@implementation NotificationHelper (Private)

+ (void)notifyGrowl:(NSString*)title message:(NSString*)message
{
    if ([GrowlApplicationBridge growlDelegate] == nil) {
        [GrowlApplicationBridge setGrowlDelegate:[NotificationHelper new]];
    }
    
    [GrowlApplicationBridge
	 notifyWithTitle:title
	 description:message
	 notificationName:title
	 iconData:nil
	 priority:0
	 isSticky:NO
	 clickContext:nil];
}

+ (void)notifyNative:(NSString*)title message:(NSString*)message
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

@end
