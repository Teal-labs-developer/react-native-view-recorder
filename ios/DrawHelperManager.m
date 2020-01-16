//
//  HelperManagerBridge.m
//  RNViewRecorder
//
//  Created by Toddle on 12/01/2020.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

// CalendarManagerBridge.m
#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(DrawHelperManager, NSObject)

RCT_EXTERN_METHOD(isDeviceCompatible:(RCTResponseSenderBlock)callback)

@end
