package com.toddle.Views;

import android.content.res.Resources;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.util.DisplayMetrics;

public class OrthogonalViewHelper {

    private float width = 0;
    private float height = 0;

    private String color = "#dbdbdb";

    public OrthogonalViewHelper(float width, float height, String color){
        this.width = width;
        this.height = height;
        this.color = color;
    }

    private float space = this.dpToPx(48);

    private float tan30 = (float) Math.tan(30*(Math.PI/180));

    public void setColor(String color) {
        this.color = color;
    }

    public int dpToPx(int dp) {
        return (int) (dp * Resources.getSystem().getDisplayMetrics().density);
    }

    public Paint getPaint(){
        Paint paint = new Paint();
        paint.setStrokeWidth(this.dpToPx(1));
        paint.setColor(Color.parseColor(color));
        return paint;
    }

    public void drawHorizontalLines(Canvas canvas){
        float startY = space / 2;

        while(startY < height){
            Paint paint = getPaint();
            canvas.drawLine(0, startY, width, startY, paint);
            startY += space;
        }
    }

    public void drawVerticalLines(Canvas canvas){
        drawVerticalLines(canvas, space/2, space);
    }

    public void drawDots(Canvas canvas){
        float startX = 0, startY = 0;

        int dp_1 = this.dpToPx(2);

        while(startY < height){
            startX = space / 2;
            while(startX < width){
                Paint paint = getPaint();
                canvas.drawOval(
                        new RectF(startX-dp_1, startY-dp_1, startX+dp_1, startY+dp_1)
                        , paint);
                startX += space;
            }
            startY += space;
        }
    }

    public void drawVerticalLines(Canvas canvas, float startX, float space){
        while(startX < width){
            Paint paint = getPaint();
            canvas.drawLine(startX, 0, startX, height, paint);
            startX += space;
        }
    }

    public void drawOrthogonalRightLines(Canvas canvas){
        float startX = space / tan30;
        float startY = space;

        float xSegment = startX;
        float ySegment = startY;

        float numberOfLines = width / xSegment + height / ySegment;

        float i = 0.0f;

        while(i < numberOfLines){
            Paint paint = getPaint();
            canvas.drawLine(0, startY, startX, 0, paint);

            startX += space / tan30;
            startY += space;
            i++;
        }

        drawVerticalLines(canvas,(space / tan30) / 2, (space/tan30)/2);
    }

    public void drawOrthogonalLeftLines(Canvas canvas){
        float i = 0.0f;

        float xSegment  = space / tan30;
        float ySegment = space;

        float numberOfLines = width / xSegment +  height / ySegment;

        float tempStartY = height % ySegment;

        float startX = tempStartY / tan30;
        float startY = height - tempStartY;
        while(i < numberOfLines){
            Paint paint = getPaint();
            canvas.drawLine(0, startY, startX, height, paint);

            startX += (space/tan30);
            startY = startY - space;
            i ++;
        }
    }
}
