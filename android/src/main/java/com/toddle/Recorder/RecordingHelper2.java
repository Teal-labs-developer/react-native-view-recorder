package com.toddle.Recorder;

import android.annotation.TargetApi;
import android.graphics.Canvas;
import android.media.MediaCodec;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Environment;
import android.util.Log;
import android.view.Surface;

import com.toddle.Sketch.DrawView;



import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;

public class RecordingHelper2 {
    private static final int BIT_RATE = 4000000;

    private static final int FRAMES_PER_SECOND = 43;

    private static int HEIGHT = 0;

    private static final int IFRAME_INTERVAL = 5;

    private static final String MIME_TYPE = "video/avc";

    private static final int NUM_FRAMES = 1000;

    private static final String TAG = "RecordingHelper1";

    private static final boolean VERBOSE = false;

    private static int WIDTH = 1280;

    private DrawView drawView;

    private Recorder.RecorderListener listener;

    private MediaCodec.BufferInfo mBufferInfo;

    private MediaCodec mEncoder;

    private long mFakePts;

    private Surface mInputSurface;

    private MediaMuxer mMuxer;

    private boolean mMuxerStarted;

    private int mTrackIndex;

    private MediaRecorder recorder;

    static  {
        HEIGHT = 960;
    }

    public RecordingHelper2(Recorder.RecorderListener listener) { this.listener = listener; }

    private void drainEncoder(boolean paramBoolean) {
        int i;
        if (paramBoolean)
            this.mEncoder.signalEndOfInputStream();
        ByteBuffer[] arrayOfByteBuffer = this.mEncoder.getOutputBuffers();
        while (true) {
            i = this.mEncoder.dequeueOutputBuffer(this.mBufferInfo, 10000L);
            if (i == -1) {
                if (!paramBoolean)
                    return;
                continue;
            }
            if (i == -3) {
                arrayOfByteBuffer = this.mEncoder.getOutputBuffers();
                continue;
            }
            if (i == -2) {
                if (!this.mMuxerStarted) {
                    MediaFormat mediaFormat = this.mEncoder.getOutputFormat();
                    String str = TAG;
                    StringBuilder stringBuilder1 = new StringBuilder();
                    stringBuilder1.append("encoder output format changed: ");
                    stringBuilder1.append(mediaFormat);
                    Log.d(str, stringBuilder1.toString());
                    this.mTrackIndex = this.mMuxer.addTrack(mediaFormat);
                    this.mMuxer.start();
                    this.mMuxerStarted = true;
                    continue;
                }
                throw new RuntimeException("format changed twice");
            }
            if (i < 0) {
                String str = TAG;
                StringBuilder stringBuilder1 = new StringBuilder();
                stringBuilder1.append("unexpected result from encoder.dequeueOutputBuffer: ");
                stringBuilder1.append(i);
                Log.w(str, stringBuilder1.toString());
                continue;
            }
            ByteBuffer byteBuffer = arrayOfByteBuffer[i];
            if (byteBuffer != null) {
                if ((this.mBufferInfo.flags & 0x2) != 0)
                    this.mBufferInfo.size = 0;
                if (this.mBufferInfo.size != 0)
                    if (this.mMuxerStarted) {
                        byteBuffer.position(this.mBufferInfo.offset);
                        byteBuffer.limit(this.mBufferInfo.offset + this.mBufferInfo.size);
                        MediaCodec.BufferInfo bufferInfo = this.mBufferInfo;
                        long l = this.mFakePts;
                        bufferInfo.presentationTimeUs = l;
                        this.mFakePts = l + 23255L;
                        this.mMuxer.writeSampleData(this.mTrackIndex, byteBuffer, bufferInfo);
                    } else {
                        throw new RuntimeException("muxer hasn't started");
                    }
                this.mEncoder.releaseOutputBuffer(i, false);
                if ((this.mBufferInfo.flags & 0x4) != 0) {
                    if (!paramBoolean) {
                        Log.w(TAG, "reached end of stream unexpectedly");
                        return;
                    }
                    return;
                }
                continue;
            }
            break;
        }
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("encoderOutputBuffer ");
        stringBuilder.append(i);
        stringBuilder.append(" was null");
        throw new RuntimeException(stringBuilder.toString());
    }

    private void generateFrame(int paramInt) {
        Canvas canvas = this.mInputSurface.lockCanvas(null);
        this.listener.drawOnCanvas(canvas);
        this.mInputSurface.unlockCanvasAndPost(canvas);
    }

    private void generateMovie(File paramFile) {
        try {
            prepareEncoder(paramFile);
            for (byte b = 0; b < 1000; b++) {
                System.nanoTime();
                drainEncoder(false);
                generateFrame(b);
                System.nanoTime();
            }
            drainEncoder(true);
            releaseEncoder();
            return;
        } catch (IOException e) {
            e.printStackTrace();
        } finally {}
    }

    @TargetApi(Build.VERSION_CODES.M)
    private void generateMovie2(File paramFile) {
        try {
            this.recorder = new MediaRecorder();
            this.recorder.setOutputFormat(2);
            this.recorder.setAudioEncoder(1);
            this.recorder.setVideoSource(2);
            this.recorder.setOutputFile(paramFile.getAbsolutePath());
            this.recorder.setInputSurface(this.mEncoder.createInputSurface());
            this.recorder.prepare();
            this.recorder.start();
            this.recorder.stop();
            this.recorder.reset();
            this.recorder.release();
            return;
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }
    }

    private void prepareEncoder(File paramFile) throws IOException {
        this.mBufferInfo = new MediaCodec.BufferInfo();
        MediaFormat mediaFormat = MediaFormat.createVideoFormat("video/avc", WIDTH, HEIGHT);
        mediaFormat.setInteger("color-format", 2130708361);
        mediaFormat.setInteger("bitrate", 4000000);
        mediaFormat.setInteger("frame-rate", 43);
        mediaFormat.setInteger("i-frame-interval", 5);
        this.mEncoder = MediaCodec.createEncoderByType("video/avc");
        this.mEncoder.configure(mediaFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
        this.mInputSurface = this.mEncoder.createInputSurface();
        this.mEncoder.start();
        this.mMuxer = new MediaMuxer(paramFile.toString(), MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
        this.mTrackIndex = -1;
        this.mMuxerStarted = false;
    }

    private void releaseEncoder() {
        MediaCodec mediaCodec = this.mEncoder;
        if (mediaCodec != null) {
            mediaCodec.stop();
            this.mEncoder.release();
            this.mEncoder = null;
        }
        Surface surface = this.mInputSurface;
        if (surface != null) {
            surface.release();
            this.mInputSurface = null;
        }
        MediaMuxer mediaMuxer = this.mMuxer;
        if (mediaMuxer != null) {
            mediaMuxer.stop();
            this.mMuxer.release();
            this.mMuxer = null;
            return;
        }
    }

    public void createMovie() {
        Log.i(TAG, "Generating movie...");
        try {
            generateMovie(new File(Environment.getExternalStorageDirectory(), "soft-input-surface.mp4"));
            Log.i(TAG, "Movie generation complete");
            return;
        } catch (Exception exception) {
            Log.e(TAG, "Movie generation FAILED", exception);
            return;
        }
    }
}
