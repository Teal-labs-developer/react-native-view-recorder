package com.toddle.Recorder;

import android.content.Context;
import android.graphics.Canvas;
import android.media.MediaCodec;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.os.Build;
import android.os.Environment;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import com.toddle.RecorderLib.VideoRecorder;
import com.toddle.Sketch.DrawView;

import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

public class Recorder implements EncoderListener {
    AudioRecorder audioRecorder;

    String TAG = "Recorder";

    MediaMuxer muxer;

    boolean muxerStarted = false;

    int numOfTracks = 0;

    public File outputFile;

    RECORDING_STATES state;

    int totalTracks = 2;

    VideoRecorder videoRecorder;

    RecorderListener listener;

    long presentationTimeUs;

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    public Recorder(RecorderListener listener) {
        this.listener = listener;
        String dirPath = listener.getContext().getApplicationInfo().dataDir;
        String fileName = "drawing-"+System.currentTimeMillis()+".mp4";

        this.outputFile = new File(dirPath + File.separator + fileName);
        this.state = RECORDING_STATES.STOPPED;
        try {
            this.muxer = new MediaMuxer(this.outputFile.getAbsolutePath(), MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
        } catch (IOException e) {
            e.printStackTrace();
        }
        this.videoRecorder = new VideoRecorder(this, listener);
        this.audioRecorder = new AudioRecorder(this);
    }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    public int addTrackToMuxer(MediaFormat paramMediaFormat) {
        this.numOfTracks++;
        return this.muxer.addTrack(paramMediaFormat);
    }

    public boolean isMuxerStarted() { return this.muxerStarted; }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    public void releaseMuxer() {
        try {
            if (this.muxer != null) {
                this.muxer.stop();
                this.muxer.release();
                this.muxer = null;
                this.muxerStarted = false;
                this.numOfTracks = 0;
                Log.i(TAG, "muxer stopped");
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        listener.onRecordingDone(false);
                    }
                });
            }
            return;
        } catch (Exception exception) {
            exception.printStackTrace();
            listener.onRecordingDone(true);
            return;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    public void startMuxer() {
        String str = TAG;
        Log.i(str, "starting muxer in recorder "+this.numOfTracks+" "+this.totalTracks);
        if (this.numOfTracks == this.totalTracks) {
            this.muxer.start();
            this.muxerStarted = true;
            Log.i(TAG, "muxer started");
            return;
        }
    }

    public void startRecording() {
        try {
            this.audioRecorder.startRecording();
            this.videoRecorder.startRecording();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void stopRecording() {
        try {
            this.audioRecorder.stopRecording();
            this.videoRecorder.stopRecording();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    public void writeSampleData(int paramInt, @NonNull ByteBuffer paramByteBuffer, @NonNull MediaCodec.BufferInfo paramBufferInfo) {
        try {
            if(this.muxerStarted) {
                this.muxer.writeSampleData(paramInt, paramByteBuffer, paramBufferInfo);

            }
            return;
        } catch (Exception e) {
            e.printStackTrace();
            return;
        }
    }

    @Override
    public void runOnUiThread(Runnable runnable) {
        new Handler(Looper.getMainLooper()).post(runnable);
    }

    @Override
    public void onRecorded() {
        listener.onRecordingDone(false);
    }

    @Override
    public long getPresentationTimeUs() {
        return presentationTimeUs;
    }

    @Override
    public void setPresentationTimeUs(long presentationTimeUs) {
        this.presentationTimeUs = presentationTimeUs;
    }

    enum RECORDING_STATES {
        STARTED, STOPPED;
    }

//    public static interface RecorderListener {
//        void onStateChanged(Recorder.RECORDING_STATES param1RECORDING_STATES);
//    }

    public interface RecorderListener{
        void onRecordingDone(boolean error);
        Context getContext();
        void drawOnCanvas(Canvas canvas, boolean image);
        int getCanvasHeight();
        int getCanvasWidth();
    }
}
