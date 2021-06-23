package com.toddle.Views;

import androidx.annotation.Nullable;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import javax.annotation.Nonnull;

public class OrthogonalPatternsViewManager extends SimpleViewManager<OrthogonalView> {
    @Nonnull
    @Override
    public String getName() {
        return "RNOrthogonalPatternsView";
    }

    @Nonnull
    @Override
    protected OrthogonalView createViewInstance(@Nonnull ThemedReactContext reactContext) {
        return new OrthogonalView(reactContext);
    }

    @ReactProp(name = "color")
    public void setColor(OrthogonalView view, @Nullable String color) {
        view.setColor(color);
    }

    @ReactProp(name = "type")
    public void setType(OrthogonalView view, @Nullable String type) {
        view.setType(type);
    }
}
