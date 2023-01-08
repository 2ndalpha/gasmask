//
//  NotificationHelper.h
//  Gas Mask
//
//  Created by Siim Raud on 16.11.12.
//  Copyright (c) 2012 Clockwise. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>

@interface NotificationHelper : NSObject<NSUserNotificationCenterDelegate>

+ (void) initNotificationCenter;
+ (void)notify:(NSString*)title message:(NSString*)message;

@end
