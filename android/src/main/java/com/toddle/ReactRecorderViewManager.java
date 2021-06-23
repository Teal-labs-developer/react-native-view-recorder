package com.toddle;

import android.os.Build;

import androidx.annotation.Nullable;

import com.facebook.infer.annotation.Assertions;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.toddle.Views.RecorderView;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Nonnull;

public class ReactRecorderViewManager extends ViewGroupManager<RecorderView> {

    public static final String REACT_CLASS = "RNViewRecorder";

    public static final int COMMAND_SAVE_IMAGE = 1;
    public static final int START_RECORDING = 2;
    public static final int STOP_RECORDING = 3;
    public static final int SAVE_AS_IMAGE = 4;

    @Nonnull
    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Nonnull
    @Override
    protected RecorderView createViewInstance(@Nonnull ThemedReactContext reactContext) {
        return new RecorderView(reactContext);
    }



    @javax.annotation.Nullable
    @Override
    public Map<String, Integer> getCommandsMap() {
        return MapBuilder.of(
                "saveImage", COMMAND_SAVE_IMAGE,
                "startRecording", START_RECORDING,
                "stopRecording", STOP_RECORDING,
                "saveAsImage", SAVE_AS_IMAGE);
    }

    @javax.annotation.Nullable
    @Override
    public Map<String, Object> getExportedCustomBubblingEventTypeConstants() {
        Map<String, Object> temp = new HashMap<>();
        temp.put("onSetupDone", MapBuilder.of(
                "phasedRegistrationNames",
                MapBuilder.of("bubbled", "onSetupDone")));
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
            RecorderView view,
            int commandType,
            @Nullable ReadableArray args) {
        Assertions.assertNotNull(view);
        Assertions.assertNotNull(args);
        switch (commandType) {
            case COMMAND_SAVE_IMAGE: {
//                view.saveImage();
                return;
            }
            case START_RECORDING: {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                    view.startRecording();
                }
                return;
            }
            case STOP_RECORDING: {
                view.stopRecording();
                return;
            }
            case SAVE_AS_IMAGE:{
                view.saveAsImage();
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

