package com.toddle.Recorder;

import android.annotation.TargetApi;
import android.media.MediaCodec;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Environment;
import android.util.Log;
import android.view.Surface;

import com.toddle.Sketch.DrawView;
import com.toddle.Sketch.OnDrawListener;

import java.io.File;
import java.io.IOException;

public class RecordingHelper3 {
    private static final int BIT_RATE = 4000000;

    private static final int FRAMES_PER_SECOND = 43;

    private static int HEIGHT = 0;

    private static final int IFRAME_INTERVAL = 5;

    private static final String MIME_TYPE = "video/avc";

    private static final int NUM_FRAMES = 100;

    private static final String TAG = "RecordingHelper3";

    private static final boolean VERBOSE = false;

    private static int WIDTH = 1280;

    private DrawView drawView;

    private MediaCodec.BufferInfo mBufferInfo;

    private MediaCodec mEncoder;

    private long mFakePts;

    private Surface mInputSurface;

    private MediaMuxer mMuxer;

    private boolean mMuxerStarted;

    private int mTrackIndex;

    private File outputFile;

    private MediaRecorder recorder;

    static  {
        HEIGHT = 960;
    }

    public RecordingHelper3(DrawView paramDrawView) {
        this.drawView = paramDrawView;
        this.drawView.setOnDrawListener(new OnDrawListener() {
            public void onDraw() { (new Thread(new Runnable() {
                public void run() {
                    synchronized (mInputSurface) {
                        generateFrame(0);
                        return;
                    }
                }
            })).start(); }
        });
        this.outputFile = new File(Environment.getExternalStorageDirectory(), "soft-input-surface.mp4");
        WIDTH = paramDrawView.getWidth();
        HEIGHT = paramDrawView.getHeight();
    }

    private void generateFrame(int paramInt) { // Byte code:
        //   0: aload_0
        //   1: monitorenter
        //   2: aload_0
        //   3: getfield mInputSurface : Landroid/view/Surface;
        //   6: aconst_null
        //   7: invokevirtual lockCanvas : (Landroid/graphics/Rect;)Landroid/graphics/Canvas;
        //   10: astore_2
        //   11: aload_0
        //   12: getfield drawView : Lcom/ais/canvasrecorddemo/DrawView;
        //   15: aload_2
        //   16: invokevirtual drawOnCanvas : (Landroid/graphics/Canvas;)V
        //   19: new android/graphics/Paint
        //   22: dup
        //   23: invokespecial <init> : ()V
        //   26: ldc -65536
        //   28: invokevirtual setColor : (I)V
        //   31: aload_0
        //   32: getfield mInputSurface : Landroid/view/Surface;
        //   35: aload_2
        //   36: invokevirtual unlockCanvasAndPost : (Landroid/graphics/Canvas;)V
        //   39: aload_0
        //   40: monitorexit
        //   41: return
        //   42: astore_3
        //   43: aload_0
        //   44: getfield mInputSurface : Landroid/view/Surface;
        //   47: aload_2
        //   48: invokevirtual unlockCanvasAndPost : (Landroid/graphics/Canvas;)V
        //   51: aload_3
        //   52: athrow
        //   53: astore_2
        //   54: aload_0
        //   55: monitorexit
        //   56: aload_2
        //   57: athrow
        // Exception table:
        //   from	to	target	type
        //   2	19	53	finally
        //   19	31	42	finally
        //   31	39	53	finally
        //   43	53	53	finally
        }


        private void generateMovie(File paramFile) {
            try {
                prepareEncoder(paramFile);
                prepareRecorder(paramFile);
                this.recorder.start();
                for (byte b = 0; b < 100; b++) {
                    System.nanoTime();
                    generateFrame(b);
                    try {
                        Thread.sleep(10L);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    System.nanoTime();
                }
                this.recorder.stop();
                this.recorder.reset();
                this.recorder.release();
                return;
            } catch (IOException e) {
                e.printStackTrace();
            } finally {}
        }


        @TargetApi(Build.VERSION_CODES.M)
        private void prepareEncoder(File paramFile) throws IOException {
            this.mBufferInfo = new MediaCodec.BufferInfo();
            MediaFormat mediaFormat = MediaFormat.createVideoFormat("video/avc", WIDTH, HEIGHT);
            mediaFormat.setInteger("color-format", 2130708361);
            mediaFormat.setInteger("bitrate", 4000000);
            mediaFormat.setInteger("frame-rate", 43);
            mediaFormat.setInteger("i-frame-interval", 5);
            this.mEncoder = MediaCodec.createEncoderByType("video/avc");
            this.mEncoder.configure(mediaFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
            this.mInputSurface = this.mEncoder.createPersistentInputSurface();
        }


        @TargetApi(Build.VERSION_CODES.M)
        private void prepareRecorder(File paramFile) {
            try {
                this.recorder = new MediaRecorder();
                this.recorder.setAudioSource(1);
                this.recorder.setVideoSource(2);
                this.recorder.setOutputFormat(2);
                this.recorder.setAudioEncoder(1);
                this.recorder.setVideoEncoder(1);
                this.recorder.setVideoSize(WIDTH, HEIGHT);
                this.recorder.setOutputFile(paramFile.getAbsolutePath());
                this.recorder.setInputSurface(this.mInputSurface);
                this.recorder.prepare();
                return;
            } catch (IOException e) {
                e.printStackTrace();
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

        public void generateMovie() {}


        public void startRecording() {
            try {
                prepareEncoder(this.outputFile);
                prepareRecorder(this.outputFile);
                this.recorder.start();
                return;
            } catch (IOException iOException) {
                iOException.printStackTrace();
                return;
            }
        }

        public void stopRecording() {
            try {
                this.recorder.stop();
                this.recorder.reset();
                this.recorder.release();
                return;
            } catch (Exception exception) {
                exception.printStackTrace();
                return;
            }
        }
    }
