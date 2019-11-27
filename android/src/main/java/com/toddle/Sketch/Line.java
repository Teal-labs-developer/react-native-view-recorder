package com.toddle.Sketch;

import android.graphics.Path;

import java.io.IOException;
import java.io.Writer;

public class Line implements Action {

    private float x;
    private float y;

    public Line(float x, float y){

        this.x = x;
        this.y = y;
    }

    @Override
    public void perform(Path path) {
        path.moveTo(x, y);
    }

    @Override
    public void perform(Writer writer) {
        try {
            writer.write("L"+x+","+y);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
