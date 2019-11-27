package com.toddle.Sketch;

import android.graphics.Path;

import java.io.Writer;

public interface Action {

    void perform(Path path);

    void perform(Writer writer);
}
