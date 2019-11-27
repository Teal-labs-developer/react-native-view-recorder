package com.toddle;

import android.net.Uri;

import android.widget.ImageView;

import com.facebook.drawee.backends.pipeline.Fresco;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewProps;
import com.facebook.react.uimanager.annotations.ReactProp;

import androidx.annotation.Nullable;

public class ReactImageManager extends SimpleViewManager<ImageView> {

    public static final String REACT_CLASS = "RCTImageView";

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    protected ImageView createViewInstance(ThemedReactContext reactContext) {
        return new ImageView(reactContext);
    }

    @ReactProp(name = "src")
    public void setSrc(ImageView view, @Nullable String sources) {
        view.setImageURI(Uri.parse(sources));
    }

    @ReactProp(name = "alpha", defaultFloat = 1)
    public void setImageAlpha(ImageView view, int alpha) {
        view.setImageAlpha(alpha);
    }

//    @ReactProp(name = ViewProps.RESIZE_MODE)
//    public void setResizeMode(ImageView view, @Nullable String resizeMode) {
//        view.setScaleType(ImageResizeMode.toScaleType(resizeMode));
//    }
}
