package com.toddle.Recorder;

import android.media.MediaCodec;
import android.media.MediaFormat;
import android.media.MediaMuxer;
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

public class Recorder implements EncoderListener {
    AudioRecorder audioRecorder;

    String TAG = "Recorder";

    DrawView drawView;

    MediaMuxer muxer;

    boolean muxerStarted = false;

    int numOfTracks = 0;

    public File outputFile;

    RECORDING_STATES state;

    int totalTracks = 2;

    VideoRecorder videoRecorder;

    public Recorder(DrawView paramDrawView) {
        this.drawView = paramDrawView;
        File file = paramDrawView.getContext().getCacheDir();
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("drawing-");
        stringBuilder.append(System.currentTimeMillis());
        stringBuilder.append(".mp4");
        this.outputFile = new File(file, stringBuilder.toString());
        this.state = RECORDING_STATES.STOPPED;
        try {
            this.muxer = new MediaMuxer(this.outputFile.getAbsolutePath(), MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
        } catch (IOException e) {
            e.printStackTrace();
        }
        this.videoRecorder = new VideoRecorder(this, paramDrawView);
        this.audioRecorder = new AudioRecorder(this);
    }

    public int addTrackToMuxer(MediaFormat paramMediaFormat) {
        this.numOfTracks++;
        return this.muxer.addTrack(paramMediaFormat);
    }

    public boolean isMuxerStarted() { return this.muxerStarted; }

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
                        drawView.onRecordingDone();
                    }
                });
            }
            return;
        } catch (Exception exception) {
            exception.printStackTrace();
            return;
        }
    }

    public void startMuxer() {
        String str = TAG;
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("starting muxer in recorder ");
        stringBuilder.append(this.numOfTracks);
        stringBuilder.append(" ");
        stringBuilder.append(this.totalTracks);
        Log.i(str, stringBuilder.toString());
        if (this.numOfTracks == this.totalTracks) {
            this.muxer.start();
            this.muxerStarted = true;
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

    public void writeSampleData(int paramInt, @NonNull ByteBuffer paramByteBuffer, @NonNull MediaCodec.BufferInfo paramBufferInfo) {
        try {
            this.muxer.writeSampleData(paramInt, paramByteBuffer, paramBufferInfo);
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
        drawView.onRecordingDone();
    }

    enum RECORDING_STATES {
        STARTED, STOPPED;
    }

    public static interface RecorderListener {
        void onStateChanged(Recorder.RECORDING_STATES param1RECORDING_STATES);
    }
}
