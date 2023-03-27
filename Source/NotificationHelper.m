//
//  NotificationHelper.m
//  Gas Mask
//
//  Created by Siim Raud on 16.11.12.
//  Copyright (c) 2012 Clockwise. All rights reserved.
//

#import "NotificationHelper.h"

@implementation NotificationHelper

+ (void) initNotificationCenter
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center setDelegate:(id)self];
    
    
    //authorize
    [NotificationHelper checkNotificationCenter];
}

+ (void) checkNotificationCenter
{
    UNAuthorizationOptions options = UNAuthorizationOptionAlert;
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError *error) {
        if (granted == NO && !error) {
            logDebug(@"Local Notifications failed to authorize");
        }
        
        if (granted == YES && !error) {
            logInfo(@"Local Notifications authorized");
        }
    }];
}

+ (void)notify:(NSString*)title message:(NSString*)message
{
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = [NSString localizedUserNotificationStringForKey:title arguments:nil];
    content.body = [NSString localizedUserNotificationStringForKey:message arguments:nil];
    content.sound = [UNNotificationSound defaultSound];
    content.attachments = @[];
                
                
    //schedule the notification
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
                
    //Create the request
    NSString *uuidString = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:uuidString content:content trigger:trigger];
                
                
    // Schedule the notification.
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            logDebug(@"Local Notification: '%@' failed to send", message);
        }
    }];
}

//Notification delegates
- (void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    
    //make sure we get the notification even when app is in foreground!
    completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner);
}

@end
