package com.toddle.Views;

import android.content.Context;
import android.graphics.Canvas;
import android.os.Build;
import android.util.AttributeSet;
import android.view.View;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

public class OrthogonalView extends View {

    String color = "#dbdbdb";

    String type = "";

    public OrthogonalView(Context context) {
        super(context);
    }

    public OrthogonalView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public OrthogonalView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    public OrthogonalView(Context context, @Nullable AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    @Override
    public void draw(Canvas canvas) {
        super.draw(canvas);

        OrthogonalViewHelper helper = new OrthogonalViewHelper(getWidth(), getHeight(), color);

//        helper.drawHorizontalLines(canvas);
//        helper.drawVerticalLines(canvas);

        if(type.equalsIgnoreCase("dots")){
            helper.drawDots(canvas);
        }
        else if(type.equalsIgnoreCase("lines")){
            helper.drawHorizontalLines(canvas);
        }
        else if(type.equalsIgnoreCase("math")){
            helper.drawHorizontalLines(canvas);
            helper.drawVerticalLines(canvas);
        }
        else if(type.equalsIgnoreCase("orthogonal")){
            helper.drawOrthogonalLeftLines(canvas);
            helper.drawOrthogonalRightLines(canvas);
        }
    }

    public void setColor(String color) {
        this.color = color;
        invalidate();
    }

    public void setType(String type) {
        this.type = type;
        invalidate();
    }
}
