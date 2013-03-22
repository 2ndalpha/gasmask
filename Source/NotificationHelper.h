//
//  NotificationHelper.h
//  Gas Mask
//
//  Created by Siim Raud on 16.11.12.
//  Copyright (c) 2012 Clockwise. All rights reserved.
//

#import <Growl/Growl.h>

@interface NotificationHelper : NSObject<GrowlApplicationBridgeDelegate>

+ (void)notify:(NSString*)title message:(NSString*)message;

@end
