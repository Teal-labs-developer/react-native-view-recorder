#import "React/RCTViewManager.h"
@interface RCT_EXTERN_MODULE(RNViewRecorder, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(brushWidth, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(colorString, NSString)
RCT_EXPORT_VIEW_PROPERTY(isErasing, BOOL)
RCT_EXPORT_VIEW_PROPERTY(imageBackgroundUri, NSString)

RCT_EXTERN_METHOD(
                  updateFromManager:(nonnull NSNumber *)node
                  count:(nonnull NSNumber *)count
                  )

RCT_EXTERN_METHOD(setupRecorder:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(startRecording:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(stopRecording:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(resetCanvas:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(undo:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(redo:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(saveAsImage:(nonnull NSNumber *)node)

RCT_EXPORT_VIEW_PROPERTY(onRecorded, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onEventStackUpdated, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onSetupDone, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onImageStored, RCTDirectEventBlock)

@end
