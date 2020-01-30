package com.toddle.Sketch;

import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.toddle.Recorder.Recorder;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.ListIterator;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

public class DrawView extends FrameLayout {

    String TAG = "DrawView";

//    private LinkedHashMap<MyPath, PaintOptions> mPaths = new LinkedHashMap<>();

//    private LinkedHashMap<MyPath, PaintOptions> mLastPaths = new LinkedHashMap<>();
//    private LinkedHashMap<MyPath, PaintOptions> mUndonePaths = new LinkedHashMap<>();

    private LinkedList<Stroke> mPaths = new LinkedList<>();
    private LinkedList<Stroke> mLastPaths = new LinkedList<>();
    private LinkedList<Stroke> mUndonePaths = new LinkedList<>();

    private Paint mPaint = new Paint();
    private MyPath mPath = new MyPath();
    private PaintOptions mPaintOptions = new PaintOptions();


    private float mCurX = 0f;
    private float mCurY = 0f;
    private float mStartX = 0f;
    private float mStartY = 0f;
    private boolean mIsSaving = false;
    private boolean mIsStrokeWidthBarEnabled = false;

    private boolean isEraserOn = false;

    private String drawingTool = "pen";

    private Canvas mCanvas;
    private Bitmap mBitmap;
    private Paint   mBitmapPaint;

    private OnDrawListener onDrawListener;

    public DrawView(Context context) {
        super(context);

        init();
    }

    public DrawView(Context context, AttributeSet attrs) {
        super(context, attrs);

        init();
    }

    public DrawView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);

        init();
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    public DrawView(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);

        init();
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        readyCanvas(w, h);
    }

    private void readyCanvas(int w, int h){
        if(mBitmap != null && !mBitmap.isRecycled()){
            mBitmap.recycle();
        }
        mBitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
        mCanvas = new Canvas(mBitmap);
    }

    public void setOnDrawListener(OnDrawListener onDrawListener) {
        this.onDrawListener = onDrawListener;
    }


    private void init(){
        mBitmapPaint = new Paint(Paint.DITHER_FLAG);
        mPaint.setColor(mPaintOptions.color);
        mPaint.setStyle(Paint.Style.STROKE);
        mPaint.setStrokeJoin(Paint.Join.ROUND);
        mPaint.setStrokeCap(Paint.Cap.ROUND);
        mPaint.setStrokeWidth(mPaintOptions.strokeWidth);
        mPaint.setAntiAlias(true);

//        setOnTouchListener();
    }



    public void addPath(MyPath path, PaintOptions options) {
        mPaths.add(new Stroke(path, options));
    }


    private void refreshView(boolean update){
//        mCanvas.drawColor(Color.TRANSPARENT);

//        changePaint(mPaintOptions);
//        mCanvas.drawPath(mPath, mPaint);

        if(update){
            readyCanvas(getWidth(), getHeight());
            mCanvas.drawColor(Color.TRANSPARENT);
            ListIterator iterator = mPaths.listIterator(0);

            while(iterator.hasNext()){
                Stroke stroke = (Stroke) iterator.next();
                if(mCanvas != null){
                    changePaint(stroke.paintOptions);
                    mCanvas.drawPath(stroke.path, mPaint);
                }
            }
        }

        postInvalidate();
    }

    @Override
    protected void dispatchDraw(Canvas canvas) {
        super.dispatchDraw(canvas);

//        mCanvas.drawColor(Color.TRANSPARENT);
        ListIterator iterator = mPaths.listIterator(0);

//        while(iterator.hasNext()){
//            Stroke stroke = (Stroke) iterator.next();
//            if(mCanvas != null){
//                changePaint(stroke.paintOptions);
//                mCanvas.drawPath(stroke.path, mPaint);
//            }
//        }

        changePaint(mPaintOptions);
        mCanvas.drawPath(mPath, mPaint);


        canvas.save();

        canvas.drawBitmap(mBitmap, 0, 0, mBitmapPaint);

//        ListIterator iterator = mPaths.listIterator(0);
//        while(iterator.hasNext()){
//            Stroke stroke = (Stroke) iterator.next();
//            if(!stroke.paintOptions.isEraserOn){
//                changePaint(stroke.paintOptions);
//                canvas.drawPath(stroke.path, mPaint);
//            }
//        }
//        changePaint(mPaintOptions);
//        canvas.drawPath(mPath, mPaint);

        canvas.restore();
//        if(onDrawListener != null) onDrawListener.onDraw();
    }



    /**
     * Returns the bitmap position inside an imageView.
     * @param imageView source ImageView
     * @return 0: left, 1: top, 2: width, 3: height
     */
    public static int[] getBitmapPositionInsideImageView(ImageView imageView) {
        int[] ret = new int[4];

        if (imageView == null || imageView.getDrawable() == null)
            return ret;

        // Get image dimensions
        // Get image matrix values and place them in an array
        float[] f = new float[9];
        imageView.getImageMatrix().getValues(f);

        // Extract the scale values using the constants (if aspect ratio maintained, scaleX == scaleY)
        final float scaleX = f[Matrix.MSCALE_X];
        final float scaleY = f[Matrix.MSCALE_Y];

        // Get the drawable (could also get the bitmap behind the drawable and getWidth/getHeight)
        final Drawable d = imageView.getDrawable();
        final int origW = d.getIntrinsicWidth();
        final int origH = d.getIntrinsicHeight();

        // Calculate the actual dimensions
        final int actW = Math.round(origW * scaleX);
        final int actH = Math.round(origH * scaleY);

        ret[2] = actW;
        ret[3] = actH;

        // Get image position
        // We assume that the image is centered into ImageView
        int imgViewW = imageView.getWidth();
        int imgViewH = imageView.getHeight();

        int top = (int) (imgViewH - actH)/2;
        int left = (int) (imgViewW - actW)/2;

        ret[0] = left;
        ret[1] = top;

        return ret;
    }


    Bitmap imageBitmap;



    private void changePaint(PaintOptions paintOptions) {
        mPaint.setColor(paintOptions.color);

        if(paintOptions.drawingTool != null && paintOptions.drawingTool.equals("eraser")){
            mPaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
        }
        else{
            mPaint.setXfermode(null);
        }

        mPaint.setStrokeWidth(paintOptions.strokeWidth);
    }

    private Paint getPaint(PaintOptions paintOptions){
        Paint paint = new Paint();
        paint.setColor(paintOptions.color);
        paint.setStyle(Paint.Style.STROKE);
        paint.setStrokeJoin(Paint.Join.ROUND);
        paint.setStrokeCap(Paint.Cap.ROUND);
        paint.setStrokeWidth(paintOptions.strokeWidth);
        paint.setAntiAlias(true);
        paint.setColor(paintOptions.color);

        if(paintOptions.drawingTool != null && paintOptions.drawingTool.equals("eraser")){
            paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
        }
        else{
            paint.setXfermode(null);
        }

        paint.setStrokeWidth(paintOptions.strokeWidth);

        return paint;
    }

    public void clearCanvas(){
        mPaths.clear();
        mPath.reset();
        mLastPaths.clear();
        readyCanvas(getWidth(), getHeight());
        refreshView(false);
        onEventStackUpdated();
    }

    private void actionDown(float x, float y){
        mPath.reset();
        mPath.moveTo(x, y);
        mCurX = x;
        mCurY = y;
    }

    private void actionMove(float x, float y){
        mPath.quadTo(mCurX, mCurY, (x + mCurX) / 2, (y + mCurY) / 2);
        mCurX = x;
        mCurY = y;
    }

    private void actionUp(){
        mPath.lineTo(mCurX, mCurY);

        // draw a dot on click
        if (mStartX == mCurX && mStartY == mCurY) {
            mPath.lineTo(mCurX, mCurY + 2);
            mPath.lineTo(mCurX + 1, mCurY + 2);
            mPath.lineTo(mCurX + 1, mCurY);
        }

        mPaths.add(new Stroke(mPath, mPaintOptions));
        mLastPaths = (LinkedList<Stroke>) mPaths.clone();
        mPath = new MyPath();
        mPaintOptions = new PaintOptions(mPaintOptions.color, mPaintOptions.strokeWidth
                , mPaintOptions.alpha, mPaintOptions.isEraserOn, drawingTool);
    }


    @Override
    public boolean dispatchTouchEvent(MotionEvent event) {
        float x = event.getX();
        float y = event.getY();

//        Log.i("DrawView", "event dispatch"+x+" "+y);

        switch (event.getAction()){
            case MotionEvent.ACTION_DOWN:
                mStartX = x;
                mStartY = y;
                actionDown(x, y);
                mUndonePaths.clear();
                break;
            case MotionEvent.ACTION_MOVE:
                actionMove(x, y);
                break;
            case MotionEvent.ACTION_UP:
                actionUp();
                break;
            default:
                break;

        }

//        refreshView();

        float strokeWidth = mPaintOptions.strokeWidth;
        postInvalidate((int)(event.getX()-2*strokeWidth),(int)(event.getY()-2*strokeWidth)
                ,(int)(event.getX()+2*strokeWidth),(int)(event.getY()+2*strokeWidth));

        if(event.getAction() == MotionEvent.ACTION_UP || event.getAction() == MotionEvent.ACTION_DOWN){
            onEventStackUpdated();
        }

        return true;
    }

//    @Override
//    public boolean onTouchEvent(MotionEvent event) {
//        float x = event.getX();
//        float y = event.getY();
//
//        switch (event.getAction()){
//            case MotionEvent.ACTION_DOWN:
//                mStartX = x;
//                mStartY = y;
//                actionDown(x, y);
//                mUndonePaths.clear();
//                break;
//            case MotionEvent.ACTION_MOVE:
//                actionMove(x, y);
//                break;
//            case MotionEvent.ACTION_UP:
//                actionUp();
//                break;
//            default:
//                break;
//
//        }
//
//        refreshView(false);
//
//
//
//        if(event.getAction() == MotionEvent.ACTION_UP){
//            onEventStackUpdated();
//        }
//
//        return true;
//    }

    public void setIsErasing(boolean isErasing){
        isEraserOn = isErasing;
        mPaintOptions.isEraserOn = isEraserOn;
    }

    public void setStrokeWidth(float strokeWidth){
        mPaintOptions.strokeWidth = strokeWidth;
    }

    public void setColor(String color){
        Log.i("DrawView", "setColor "+color+" alpha "+mPaintOptions.alpha);
        if(color != null)
            mPaintOptions.color = Color.parseColor(color);
    }

    public void toggleEraser(){
        isEraserOn = !isEraserOn;
        mPaintOptions.isEraserOn = isEraserOn;
    }

    public void undo(){
        if(mPaths.size()>0){
            mPaths.removeLast();
//            readyCanvas(getWidth(),  getHeight());
            refreshView(true);
            onEventStackUpdated();
        }

    }

    public void redo(){
        if(mLastPaths.size() > mPaths.size()){
            mPaths.add(mLastPaths.get(mPaths.size()));
//            readyCanvas(getWidth(),  getHeight());
            refreshView(true);
            onEventStackUpdated();
        }
    }


    /// Determines whether a last change can be undone
    private boolean canUndo(){
        return mPaths != null && mPaths.size() > 0;
    }

    /// Determines whether an undone change can be redone
    private boolean canRedo(){
        return mLastPaths != null && mPaths != null && mLastPaths.size() > mPaths.size();
    }


    public void onEventStackUpdated(){
        WritableMap event = Arguments.createMap();
        event.putBoolean("canRedo", canRedo());
        event.putBoolean("canUndo", canUndo());
        ReactContext reactContext = (ReactContext) getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onEventStackUpdated", event);
    }

    public void setDrawingTool(String drawingTool) {
        this.drawingTool = drawingTool;
        mPaintOptions.drawingTool = drawingTool;

        changePaint(mPaintOptions);
    }
}

