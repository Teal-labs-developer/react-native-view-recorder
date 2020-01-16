package com.toddle.Views;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.drawable.BitmapDrawable;
import android.net.Uri;
import android.os.Build;
import android.util.AttributeSet;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.RequiresApi;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.toddle.Recorder.Recorder;
import com.toddle.Sketch.Stroke;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.ListIterator;

public class RecorderView extends FrameLayout implements Recorder.RecorderListener {

    String TAG = "RecorderView";

    private boolean mIsSaving = false;

    Recorder recorder;

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    public void startRecording(){
        recorder = new Recorder(this);
        recorder.startRecording();
    }

    public void stopRecording(){
        recorder.stopRecording();
    }

    public RecorderView(Context context) {
        super(context);
    }

    public RecorderView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public RecorderView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    public RecorderView(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
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

    public Bitmap getBitmap(){
        Bitmap bitmap = Bitmap.createBitmap( this.getWidth(), this.getHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
//        canvas.drawColor(Color.WHITE);
        mIsSaving = true;
        drawOnCanvas(canvas);
        mIsSaving = false;
        return bitmap;
    }


    @Override
    public void onRecordingDone(boolean error) {
        File file = recorder.outputFile;
        WritableMap event = Arguments.createMap();
        if(error){
            event.putBoolean("error", true);
        }
        else {
            event.putString("path", file.getAbsolutePath());
            event.putString("uri", file.getAbsolutePath());
            event.putInt("width", getWidth());
            event.putInt("height", getHeight());
        }
        ReactContext reactContext = (ReactContext) getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(getId(), "onRecorded", event);
    }

//    Bitmap imageBitmap;

    @Override
    public void drawOnCanvas(Canvas canvas) {

        try {
//            Bitmap b = Bitmap.createBitmap(getWidth() , getHeight(), Bitmap.Config.ARGB_8888);
//            Canvas c = new Canvas(b);
//            layout(0, 0, getLayoutParams().width, getLayoutParams().height);
            draw(canvas);
        }
        catch (Exception e){
            e.printStackTrace();
        }
    }

    @Override
    public int getCanvasHeight() {
        return getHeight();
    }

    @Override
    public int getCanvasWidth() {
        return getWidth();
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
