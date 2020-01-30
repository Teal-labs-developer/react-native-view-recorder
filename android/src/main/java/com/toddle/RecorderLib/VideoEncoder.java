package com.toddle.RecorderLib;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaFormat;
import android.os.Build;
import android.util.Log;
import android.view.Surface;

import androidx.annotation.RequiresApi;

import com.toddle.Recorder.EncoderListener;
import com.toddle.Recorder.Recorder;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.Random;

public class VideoEncoder {
    private static final int BIT_RATE = 300000;

    private static final int FRAMES_PER_SECOND = 20;

    private static int HEIGHT = 0;

    private static final int IFRAME_INTERVAL = 1;

    private static final String MIME_TYPE = "video/mp4v-es";

    private static final int NUM_FRAMES = 1000;

    private static final String TAG = "RecorderLib";

    private static final boolean VERBOSE = false;

    private static int WIDTH = 1280;

    private Recorder.RecorderListener listener;

    private EncoderListener encoderListener;

    private MediaCodec.BufferInfo mBufferInfo;

    MediaCodec mEncoder;

    private long mFakePts;

    Surface mInputSurface;

    private boolean mMuxerStarted;

    private int mTrackIndex;

    private long startTimeMicro = -1;

    static  {
        HEIGHT = 960;
    }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    public VideoEncoder(EncoderListener paramEncoderListener, Recorder.RecorderListener listener) throws IOException {
        this.encoderListener = paramEncoderListener;
        this.listener = listener;
        WIDTH = listener.getCanvasWidth();
        HEIGHT = listener.getCanvasHeight();
        prepareEncoder();
    }

    /*
    * 640×480-, 800×600-, 960×720-, 1024×768-, 1280×960-, 1400-×1050-, 1440-×1080-, 1600×1200-, 1856×1392, 1920×1440,
    *  2048×1536.
16:10 aspect ratio resolutions: 1280×800, 1440×900, 1680×1050, 1920×1200, and 2560×1600.
16:9 aspect ratio resolutions: 1024×576, 1152×648, 1280×720, 1366×768, 1600×900,
*  1920×1080, 2560×1440, 3840×2160 7680 x 4320
*
* 480-, 640-, 720-, 1024-, 1280-, 1440-, 1920, 2048, 2160, 2560, 3840, 4320,
*
    * */


    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    private void prepareEncoder() throws IOException {
        this.mBufferInfo = new MediaCodec.BufferInfo();

        Log.i(TAG, "width  "+WIDTH+" height "+HEIGHT);

        MediaFormat mediaFormat = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_MPEG4, WIDTH, HEIGHT);
        mediaFormat.setInteger("color-format",MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface);
        //2130708361

        mediaFormat.setInteger("bitrate", WIDTH*HEIGHT*6);
        mediaFormat.setInteger("frame-rate", 20);
        mediaFormat.setFloat("i-frame-interval", 0.1f);
        String str = TAG;
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("format: ");
        stringBuilder.append(mediaFormat);
        Log.d(str, stringBuilder.toString());
        this.mEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_MPEG4);
        this.mEncoder.configure(mediaFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
        this.mInputSurface = this.mEncoder.createInputSurface();
        this.mEncoder.start();
        this.mTrackIndex = -1;
    }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    public void drainEncoder(boolean endOfStream) {
        final int TIMEOUT_USEC = 10000;
        if (VERBOSE) Log.d(TAG, "drainEncoder(" + endOfStream + ")");

        if (endOfStream) {
            if (VERBOSE) Log.d(TAG, "sending EOS to encoder");
            mEncoder.signalEndOfInputStream();
        }

        ByteBuffer[] encoderOutputBuffers = mEncoder.getOutputBuffers();
        while (true) {
            int encoderStatus = mEncoder.dequeueOutputBuffer(mBufferInfo, TIMEOUT_USEC);
            if (encoderStatus == MediaCodec.INFO_TRY_AGAIN_LATER) {
                // no output available yet
                if (!endOfStream) {
                    break;      // out of while
                } else {
                    if (VERBOSE) Log.d(TAG, "no output available, spinning to await EOS");
                }
            } else if (encoderStatus == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED) {
                // not expected for an encoder
                encoderOutputBuffers = mEncoder.getOutputBuffers();
            } else if (encoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                // should happen before receiving buffers, and should only happen once
                if (mMuxerStarted) {
//                    throw new RuntimeException("format changed twice");
                }
                else{
                    MediaFormat newFormat = mEncoder.getOutputFormat();
                    Log.d(TAG, "encoder output format changed: " + newFormat);

                    // now that we have the Magic Goodies, start the muxer
                    mTrackIndex = encoderListener.addTrackToMuxer(newFormat);
                    encoderListener.startMuxer();
                    mMuxerStarted = true;
                }
            } else if (encoderStatus < 0) {
                Log.w(TAG, "unexpected result from encoder.dequeueOutputBuffer: " +
                        encoderStatus);
                // let's ignore it
            } else {
                ByteBuffer encodedData = encoderOutputBuffers[encoderStatus];
                if (encodedData == null) {
                    throw new RuntimeException("encoderOutputBuffer " + encoderStatus +
                            " was null");
                }

                if ((mBufferInfo.flags & MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
                    // The codec config data was pulled out and fed to the muxer when we got
                    // the INFO_OUTPUT_FORMAT_CHANGED status.  Ignore it.
                    if (VERBOSE) Log.d(TAG, "ignoring BUFFER_FLAG_CODEC_CONFIG");
                    mBufferInfo.size = 0;
                }

                if (mBufferInfo.size != 0) {
                    if (!mMuxerStarted) {
                        throw new RuntimeException("muxer hasn't started");
                    }

                    // adjust the ByteBuffer values to match BufferInfo (not needed?)
                    encodedData.position(mBufferInfo.offset);
                    encodedData.limit(mBufferInfo.offset + mBufferInfo.size);

                    if(startTimeMicro < 0){
                        startTimeMicro = System.currentTimeMillis() * 1000;
                    }

                    mFakePts = System.currentTimeMillis() * 1000 - startTimeMicro;
                    encoderListener.setPresentationTimeUs(mFakePts);

                    mBufferInfo.presentationTimeUs = mFakePts;
//                    mFakePts += 1000000L / FRAMES_PER_SECOND;

                    encoderListener.writeSampleData(mTrackIndex, encodedData, mBufferInfo);
                    if (VERBOSE) {
                        Log.d(TAG, "sent " + mBufferInfo.size + " bytes to muxer, ts=" +
                                mBufferInfo.presentationTimeUs);
                    }
                }

                mEncoder.releaseOutputBuffer(encoderStatus, false);

                if ((mBufferInfo.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                    if (!endOfStream) {
                        Log.w(TAG, "reached end of stream unexpectedly");
                    } else {
                        if (VERBOSE) Log.d(TAG, "end of stream reached");
                    }
                    break;      // out of while
                }
            }
        }
    }

    void generateFrame(int frameNum) {
//            Canvas canvas = mInputSurface.lockCanvas(new Rect());
//            canvas = mInputSurface.lockHardwareCanvas();



        Canvas canvas = mInputSurface.lockCanvas(null);

        try{

            listener.drawOnCanvas(canvas, false);
        }finally {
            mInputSurface.unlockCanvasAndPost(canvas);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN)
    void releaseEncoder() throws IOException {
        Log.d(TAG, "releasing encoder objects");
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
        if (encoderListener != null) {
            try {
                Thread.sleep(200);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            encoderListener.releaseMuxer();
            return;
        }
    }

    public void setEncoderListener(EncoderListener paramEncoderListener) { this.encoderListener = paramEncoderListener; }
}

