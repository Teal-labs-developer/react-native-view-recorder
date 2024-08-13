#import "React/RCTViewManager.h"
@interface RCT_EXTERN_MODULE(RNViewRecorder, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(imageBackgroundUri, NSString)
RCT_EXPORT_VIEW_PROPERTY(backgroundType, NSString)
RCT_EXPORT_VIEW_PROPERTY(backgroundColorString, NSString)


RCT_EXTERN_METHOD(setupRecorder:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(startRecording:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(stopRecording:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(pauseRecording:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(saveAsImage:(nonnull NSNumber *)node)


RCT_EXPORT_VIEW_PROPERTY(onRecorded, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onSetupDone, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onImageStored, RCTDirectEventBlock)

@end
