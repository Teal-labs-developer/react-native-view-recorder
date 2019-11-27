package com.toddle.Sketch;

import android.graphics.Color;

public class PaintOptions {

    public int color = Color.RED;
    public float strokeWidth = 8;
    public int alpha = 255;
    public boolean isEraserOn = false;

    public PaintOptions(int color, float strokeWidth, int alpha, boolean isEraserOn ){
        this.color = color;
        this.strokeWidth = strokeWidth;
        this.alpha = alpha;
        this.isEraserOn = isEraserOn;
    }

    public PaintOptions(){

    }
}
