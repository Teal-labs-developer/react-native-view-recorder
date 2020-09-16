package com.toddle.Views;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.net.Uri;
import android.os.Build;
import android.util.AttributeSet;
import android.util.Log;
import android.widget.FrameLayout;

import androidx.annotation.RequiresApi;

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
        String mediaStorageDir = getContext().getApplicationInfo().dataDir;

        // This location works best if you want the created images to be shared
        // between applications and persist after your app has been uninstalled.

        // Create the storage directory if it does not exist
        if (! mediaStorageDir.exists()){
            if (! mediaStorageDir.mkdirs()){
                return null;
            }
        }
        // Create a media file name
        String timeStamp = new SimpleDateFormat("ddMMyyyy_HHmmss.SSS").format(new Date());
        File mediaFile;
        String mImageName="Sketch_"+ timeStamp +".jpg";
        mediaFile = new File(mediaStorageDir + File.separator + mImageName);
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
        drawOnCanvas(canvas, true);
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
    public void drawOnCanvas(Canvas canvas, boolean image) {

        try {
            if(image){
                draw(canvas);
            }
            else{
                Bitmap b = Bitmap.createBitmap(getWidth() , getHeight(), Bitmap.Config.ARGB_8888);
                Canvas c = new Canvas(b);
                draw(c);
//            layout(0, 0, getLayoutParams().width, getLayoutParams().height);
                Bitmap scaledBitmap = Bitmap.createScaledBitmap(b, getCanvasWidth(), getCanvasHeight(), true);
                Paint paint = new Paint();
                paint.setAntiAlias(true);
                canvas.drawBitmap(scaledBitmap, 0,0,paint);
                b.recycle();
                scaledBitmap.recycle();
            }
        }
        catch (Exception e){
            e.printStackTrace();
        }
    }

    @Override
    public int getCanvasHeight() {
        int height = getHeight();
        int width = getWidth();

        if(height > width){
            //portrait
            //if height is greater than 720 then 720
            //otherwise return getHeight
            if(height > 720){
                return  720;
            }
            else{
                return height;
            }
        }
        else{
            //landscape
            //if width is greater than 720 then scale height accordingly
            //otherwise return getHeight
            if(width > 720){
                int result = height * 720 / width;
                return result % 2 != 0 ? result+1 : result;
            }
            else{
                return height;
            }
        }
//        return height;
    }

    @Override
    public int getCanvasWidth() {
        //available dimen
        //480, 640, 720, 1080, 1280, 1920
        int height = getHeight();
        int width = getWidth();

        if(height > width){
            //portrait
            //if height > 720 then scale width accordingly
            //else return width
            if(height > 720){
                int result = width * 720 / height;
                return result % 2 != 0 ? result+1 : result;
            }
            else{
                return width;
            }
        }
        else{
            //landscape
            //if width > 720 then return 720
            //else return height
            if(width > 720){
                return 720;
            }
            else{
                return width;
            }

        }

//        List<Camera.Size> list = Camera.open().getParameters().getSupportedVideoSizes();
//        for(int i = 0; i < list.size(); i++){
//            Camera.Size size = list.get(i);
//            Log.i(TAG, "camera supporoted  "+size.width+" "+size.height);
//        }
//        return getWidth();
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
