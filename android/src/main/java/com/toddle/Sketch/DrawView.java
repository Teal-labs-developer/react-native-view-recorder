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

    ImageView imageView;


    private float mCurX = 0f;
    private float mCurY = 0f;
    private float mStartX = 0f;
    private float mStartY = 0f;
    private boolean mIsSaving = false;
    private boolean mIsStrokeWidthBarEnabled = false;

    private boolean isEraserOn = false;

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

        imageView = new ImageView(getContext());

        addView(imageView, new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

//        setOnTouchListener();
    }

    public Bitmap getBitmap(){
        Bitmap bitmap = Bitmap.createBitmap( this.getWidth(), this.getHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        canvas.drawColor(Color.WHITE);
        mIsSaving = true;
        drawOnCanvas(canvas);
        mIsSaving = false;
        return bitmap;
    }

    /** Create a File for saving an image or video */
    private  File getOutputMediaFile(){
        // To be safe, you should check that the SDCard is mounted
        // using Environment.getExternalStorageState() before doing this.
        File mediaStorageDir = getContext().getCacheDir();

        // This location works best if you want the created images to be shared
        // between applications and persist after your app has been uninstalled.

        // Create the storage directory if it does not exist
        if (! mediaStorageDir.exists()){
            if (! mediaStorageDir.mkdirs()){
                return null;
            }
        }
        // Create a media file name
        String timeStamp = new SimpleDateFormat("ddMMyyyy_HHmm").format(new Date());
        File mediaFile;
        String mImageName="MI_"+ timeStamp +".jpg";
        mediaFile = new File(mediaStorageDir.getPath() + File.separator + mImageName);
        return mediaFile;
    }

    public void saveAsImage(){
        Bitmap bitmap = getBitmap();

        File pictureFile = getOutputMediaFile();
        if (pictureFile == null) {
            Log.d(TAG,
                    "Error creating media file, check storage permissions: ");// e.getMessage());
            return;
        }
        try {
            FileOutputStream fos = new FileOutputStream(pictureFile);
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos);
            fos.close();
            onImageStored(pictureFile, bitmap.getWidth(), bitmap.getHeight());
            bitmap.recycle();
        } catch (FileNotFoundException e) {
            Log.d(TAG, "File not found: " + e.getMessage());
        } catch (IOException e) {
            Log.d(TAG, "Error accessing file: " + e.getMessage());
        }
    }

    public void addPath(MyPath path, PaintOptions options) {
        mPaths.add(new Stroke(path, options));
    }


    private void refreshView(){
//        mCanvas.drawColor(Color.TRANSPARENT);

//        changePaint(mPaintOptions);
//        mCanvas.drawPath(mPath, mPaint);

        invalidate();
    }

    @Override
    protected void dispatchDraw(Canvas canvas) {
        super.dispatchDraw(canvas);

        mCanvas.drawColor(Color.TRANSPARENT);
        ListIterator iterator = mPaths.listIterator(0);

        while(iterator.hasNext()){
            Stroke stroke = (Stroke) iterator.next();
            if(mCanvas != null){
                changePaint(stroke.paintOptions);
                mCanvas.drawPath(stroke.path, mPaint);
            }
        }

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

    public void drawOnCanvas(Canvas canvas){
        try {
            if(imageBitmap == null){
                BitmapDrawable drawable = (BitmapDrawable) imageView.getDrawable();
                if(drawable != null)
                    imageBitmap = drawable.getBitmap();
            }

            canvas.drawColor(Color.WHITE);

            if(imageBitmap != null)
                canvas.drawBitmap(imageBitmap, imageView.getImageMatrix(), null);


            Bitmap mBitmap = Bitmap.createBitmap(getWidth(), getHeight(), Bitmap.Config.ARGB_8888);
            Canvas mCanvas = new Canvas(mBitmap);
            mCanvas.drawColor(Color.TRANSPARENT);
            ListIterator iterator = mPaths.listIterator(0);

            while(iterator.hasNext()){
                Stroke stroke = (Stroke) iterator.next();
                if(mCanvas != null){
                    mCanvas.drawPath(stroke.path, getPaint(stroke.paintOptions));
                }
            }
            mCanvas.drawPath(mPath, getPaint(mPaintOptions));


            canvas.drawBitmap(mBitmap, 0, 0, mBitmapPaint);

            mBitmap.recycle();
        }
        catch (Exception e){
            e.printStackTrace();
        }
    }

    private void changePaint(PaintOptions paintOptions) {
        mPaint.setColor(paintOptions.color);

        if(paintOptions.isEraserOn){
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

        if(paintOptions.isEraserOn){
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
        refreshView();
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
                , mPaintOptions.alpha, mPaintOptions.isEraserOn);
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

        refreshView();

        if(event.getAction() == MotionEvent.ACTION_UP){
            onEventStackUpdated();
        }

        return true;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        float x = event.getX();
        float y = event.getY();

        Log.i("DrawView", "event"+x+" "+y);

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

        refreshView();



        if(event.getAction() == MotionEvent.ACTION_UP){
            onEventStackUpdated();
        }

        return true;
    }

    public void setIsErasing(boolean isErasing){
        isEraserOn = isErasing;
        mPaintOptions.isEraserOn = isEraserOn;
    }

    public void setStrokeWidth(float strokeWidth){
        mPaintOptions.strokeWidth = strokeWidth;
    }

    public void setColor(String color){
        Log.i("DrawView", "setColor "+color);
        if(color != null)
            mPaintOptions.color = Color.parseColor(color);
    }

    public void setBackgroundImage(String uri){
        if(uri != null){
            if(uri.contains("://")){
                imageView.setImageURI(Uri.parse(uri));
            }
            else{
                File imgFile = new  File(uri);
                if(imgFile.exists()){
                    Bitmap myBitmap = BitmapFactory.decodeFile(imgFile.getAbsolutePath());

                    imageView.setImageBitmap(myBitmap);
                }

            }
        }


//            imageView.setBackgroundResource(android.R.mipmap.sym_def_app_icon);
    }

    public void toggleEraser(){
        isEraserOn = !isEraserOn;
        mPaintOptions.isEraserOn = isEraserOn;
    }

    public void undo(){
        if(mPaths.size()>0){
            mPaths.removeLast();
            readyCanvas(getWidth(),  getHeight());
            refreshView();
            onEventStackUpdated();
        }

    }

    public void redo(){
        if(mLastPaths.size() > mPaths.size()){
            mPaths.add(mLastPaths.get(mPaths.size()));
            readyCanvas(getWidth(),  getHeight());
            refreshView();
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



    Recorder recorder;
    public void startRecording(){
        recorder = new Recorder(this);
        recorder.startRecording();
    }

    public void stopRecording(){
        recorder.stopRecording();
    }

    public void onRecordingDone(){
        File file = recorder.outputFile;
        WritableMap event = Arguments.createMap();
        event.putString("path", file.getAbsolutePath());
        event.putString("uri", file.getAbsolutePath());
        event.putInt("width", getWidth());
        event.putInt("height", getHeight());
        ReactContext reactContext = (ReactContext) getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onRecorded", event);
    }


    public void onEventStackUpdated(){
        WritableMap event = Arguments.createMap();
        event.putBoolean("canRedo", canRedo());
        event.putBoolean("canUndo", canUndo());
        ReactContext reactContext = (ReactContext) getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onEventStackUpdated", event);
    }

    public void onImageStored(File imageFile, int width, int height){
        WritableMap event = Arguments.createMap();
        event.putString("path", imageFile.getAbsolutePath());
        event.putString("uri", Uri.fromFile(imageFile).toString());
        event.putInt("width", width);
        event.putInt("height", height);
        ReactContext reactContext = (ReactContext) getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onImageStored", event);
    }
}

