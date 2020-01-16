package com.toddle;

import android.net.Uri;
import android.widget.ImageView;

import com.facebook.infer.annotation.Assertions;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.toddle.Sketch.DrawView;

import java.util.HashMap;
import java.util.Map;

import androidx.annotation.Nullable;

public class ReactDrawViewManager extends SimpleViewManager<DrawView> {

    public static final String REACT_CLASS = "RNDrawView";

    public static final int COMMAND_SAVE_IMAGE = 1;

//    RCT_EXTERN_METHOD(startRecording:(nonnull NSNumber *)node)
//    RCT_EXTERN_METHOD(stopRecording:(nonnull NSNumber *)node)
//    RCT_EXTERN_METHOD(resetCanvas:(nonnull NSNumber *)node)
//    RCT_EXTERN_METHOD(undo:(nonnull NSNumber *)node)
//    RCT_EXTERN_METHOD(redo:(nonnull NSNumber *)node)
//
//    RCT_EXPORT_VIEW_PROPERTY(onRecorded, RCTDirectEventBlock)
//    RCT_EXPORT_VIEW_PROPERTY(onEventStackUpdated, RCTDirectEventBlock)


    public static final int START_RECORDING = 2;
    public static final int STOP_RECORDING = 3;
    public static final int RESET_CANVAS = 4;
    public static final int UNDO = 5;
    public static final int REDO = 6;
    public static final int SAVE_AS_IMAGE = 7;

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    protected DrawView createViewInstance(ThemedReactContext reactContext) {
        return new DrawView(reactContext);
    }

    @ReactProp(name = "isErasing")
    public void setIsErasing(DrawView view, @Nullable boolean isEraserOn) {
        view.setIsErasing(isEraserOn);
    }

    @ReactProp(name = "brushWidth")
    public void setBrushWidth(DrawView view, @Nullable float brushWidth) {
        view.setStrokeWidth(brushWidth);
    }

    @ReactProp(name = "drawingTool")
    public void setDrawingTool(DrawView view, @Nullable String colorString) {
//        view.setDrawingTool(colorString);
    }

    @ReactProp(name = "colorString")
    public void setColorString(DrawView view, @Nullable String colorString) {
//        view.setColor(colorString);
    }



    @javax.annotation.Nullable
    @Override
    public Map<String, Integer> getCommandsMap() {
        return MapBuilder.of(
                "saveImage", COMMAND_SAVE_IMAGE,
                "startRecording", START_RECORDING,
                "stopRecording", STOP_RECORDING,
                "resetCanvas", RESET_CANVAS,
                "undo", UNDO,
                "redo", REDO,
                "saveAsImage", SAVE_AS_IMAGE);
    }

    @javax.annotation.Nullable
    @Override
    public Map<String, Object> getExportedCustomBubblingEventTypeConstants() {
        Map<String, Object> temp = new HashMap<>();
        temp.put("onEventStackUpdated", MapBuilder.of(
                "phasedRegistrationNames",
                MapBuilder.of("bubbled", "onEventStackUpdated")));
        temp.put("onRecorded", MapBuilder.of(
                "phasedRegistrationNames",
                MapBuilder.of("bubbled", "onRecorded")));
        temp.put("onImageStored", MapBuilder.of(
                "phasedRegistrationNames",
                MapBuilder.of("bubbled", "onImageStored")));
        return temp;
    }

    @javax.annotation.Nullable
    @Override
    public Map<String, Object> getExportedCustomDirectEventTypeConstants() {
        return super.getExportedCustomDirectEventTypeConstants();
    }

    @Override
    public void receiveCommand(
            DrawView view,
            int commandType,
            @Nullable ReadableArray args) {
        Assertions.assertNotNull(view);
        Assertions.assertNotNull(args);
        switch (commandType) {
            case COMMAND_SAVE_IMAGE: {
//                view.saveImage();
                return;
            }
            case RESET_CANVAS: {
                view.clearCanvas();
                return;
            }
            case UNDO:{
                view.undo();
                return;
            }
            case REDO:{
                view.redo();
                return;
            }

            default:
                throw new IllegalArgumentException(String.format(
                        "Unsupported command %d received by %s.",
                        commandType,
                        getClass().getSimpleName()));
        }
    }


}
