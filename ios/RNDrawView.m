//
//  RNDrawView.m
//  RNViewRecorder
//
//  Created by Toddle on 13/12/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import "React/RCTViewManager.h"
@interface RCT_EXTERN_MODULE(RNDrawView, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(brushWidth, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(colorString, NSString)
RCT_EXPORT_VIEW_PROPERTY(isErasing, BOOL)
RCT_EXPORT_VIEW_PROPERTY(imageBackgroundUri, NSString)
RCT_EXPORT_VIEW_PROPERTY(drawingTool, NSString)
RCT_EXPORT_VIEW_PROPERTY(pointPath, NSString)
RCT_EXPORT_VIEW_PROPERTY(opacity, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(forceOnTap, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(forceSensitive, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(pointStep, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(coreProportion, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(colorAlpha, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(brushes, NSArray)



RCT_EXTERN_METHOD(resetCanvas:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(undo:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(redo:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(saveAsImage:(nonnull NSNumber *)node)


RCT_EXPORT_VIEW_PROPERTY(onEventStackUpdated, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onViewMount, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onImageStored, RCTDirectEventBlock)

//onViewMount

@end
