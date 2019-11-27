package com.toddle.Recorder;

import android.media.MediaCodec;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.os.Environment;
import android.util.Log;
import android.view.Surface;

import com.toddle.Sketch.DrawView;

import java.io.File;
import java.io.IOException;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class RecordingHelper {
    private static final int BIT_RATE = 300000;

    private static final int FRAMES_PER_SECOND = 20;

    private static int HEIGHT = 0;

    private static final int IFRAME_INTERVAL = 5;

    private static final String MIME_TYPE = "video/avc";

    private static final int NUM_FRAMES = 1000;

    private static final String TAG = "RecordingHelper";

    private static final boolean VERBOSE = false;

    private static int WIDTH = 1280;

    private DrawView drawView;

    ExecutorService executorService;

    private MediaCodec.BufferInfo mBufferInfo;

    private MediaCodec mEncoder;

    private long mFakePts;

    private Surface mInputSurface;

    private MediaMuxer mMuxer;

    private boolean mMuxerStarted;

    private int mTrackIndex;

    private File outputFile;

    Timer timer;

    static  {
        HEIGHT = 960;
    }

    public RecordingHelper(DrawView paramDrawView) {
        File file = Environment.getExternalStorageDirectory();
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("soft-input-surface-");
        stringBuilder.append(System.currentTimeMillis());
        stringBuilder.append(".mp4");
        this.outputFile = new File(file, stringBuilder.toString());
        this.executorService = Executors.newFixedThreadPool(1);
        this.drawView = paramDrawView;
        WIDTH = paramDrawView.getWidth();
        HEIGHT = paramDrawView.getHeight();
    }

    private void drainEncoder(boolean paramBoolean) { // Byte code:
        //   0: aload_0
        //   1: monitorenter
        //   2: iload_1
        //   3: ifeq -> 441
        //   6: aload_0
        //   7: getfield mEncoder : Landroid/media/MediaCodec;
        //   10: invokevirtual signalEndOfInputStream : ()V
        //   13: goto -> 16
        //   16: aload_0
        //   17: getfield mEncoder : Landroid/media/MediaCodec;
        //   20: invokevirtual getOutputBuffers : ()[Ljava/nio/ByteBuffer;
        //   23: astore_3
        //   24: aload_0
        //   25: getfield mEncoder : Landroid/media/MediaCodec;
        //   28: aload_0
        //   29: getfield mBufferInfo : Landroid/media/MediaCodec$BufferInfo;
        //   32: ldc2_w 10000
        //   35: invokevirtual dequeueOutputBuffer : (Landroid/media/MediaCodec$BufferInfo;J)I
        //   38: istore_2
        //   39: iload_2
        //   40: iconst_m1
        //   41: if_icmpne -> 51
        //   44: iload_1
        //   45: ifne -> 444
        //   48: goto -> 390
        //   51: iload_2
        //   52: bipush #-3
        //   54: if_icmpne -> 68
        //   57: aload_0
        //   58: getfield mEncoder : Landroid/media/MediaCodec;
        //   61: invokevirtual getOutputBuffers : ()[Ljava/nio/ByteBuffer;
        //   64: astore_3
        //   65: goto -> 393
        //   68: iload_2
        //   69: bipush #-2
        //   71: if_icmpne -> 169
        //   74: aload_0
        //   75: getfield mMuxerStarted : Z
        //   78: ifne -> 159
        //   81: aload_0
        //   82: getfield mEncoder : Landroid/media/MediaCodec;
        //   85: invokevirtual getOutputFormat : ()Landroid/media/MediaFormat;
        //   88: astore #4
        //   90: getstatic com/ais/canvasrecorddemo/RecordingHelper.TAG : Ljava/lang/String;
        //   93: astore #5
        //   95: new java/lang/StringBuilder
        //   98: dup
        //   99: invokespecial <init> : ()V
        //   102: astore #6
        //   104: aload #6
        //   106: ldc 'encoder output format changed: '
        //   108: invokevirtual append : (Ljava/lang/String;)Ljava/lang/StringBuilder;
        //   111: pop
        //   112: aload #6
        //   114: aload #4
        //   116: invokevirtual append : (Ljava/lang/Object;)Ljava/lang/StringBuilder;
        //   119: pop
        //   120: aload #5
        //   122: aload #6
        //   124: invokevirtual toString : ()Ljava/lang/String;
        //   127: invokestatic d : (Ljava/lang/String;Ljava/lang/String;)I
        //   130: pop
        //   131: aload_0
        //   132: aload_0
        //   133: getfield mMuxer : Landroid/media/MediaMuxer;
        //   136: aload #4
        //   138: invokevirtual addTrack : (Landroid/media/MediaFormat;)I
        //   141: putfield mTrackIndex : I
        //   144: aload_0
        //   145: getfield mMuxer : Landroid/media/MediaMuxer;
        //   148: invokevirtual start : ()V
        //   151: aload_0
        //   152: iconst_1
        //   153: putfield mMuxerStarted : Z
        //   156: goto -> 393
        //   159: new java/lang/RuntimeException
        //   162: dup
        //   163: ldc 'format changed twice'
        //   165: invokespecial <init> : (Ljava/lang/String;)V
        //   168: athrow
        //   169: iload_2
        //   170: ifge -> 216
        //   173: getstatic com/ais/canvasrecorddemo/RecordingHelper.TAG : Ljava/lang/String;
        //   176: astore #4
        //   178: new java/lang/StringBuilder
        //   181: dup
        //   182: invokespecial <init> : ()V
        //   185: astore #5
        //   187: aload #5
        //   189: ldc 'unexpected result from encoder.dequeueOutputBuffer: '
        //   191: invokevirtual append : (Ljava/lang/String;)Ljava/lang/StringBuilder;
        //   194: pop
        //   195: aload #5
        //   197: iload_2
        //   198: invokevirtual append : (I)Ljava/lang/StringBuilder;
        //   201: pop
        //   202: aload #4
        //   204: aload #5
        //   206: invokevirtual toString : ()Ljava/lang/String;
        //   209: invokestatic w : (Ljava/lang/String;Ljava/lang/String;)I
        //   212: pop
        //   213: goto -> 393
        //   216: aload_3
        //   217: iload_2
        //   218: aaload
        //   219: astore #4
        //   221: aload #4
        //   223: ifnull -> 396
        //   226: aload_0
        //   227: getfield mBufferInfo : Landroid/media/MediaCodec$BufferInfo;
        //   230: getfield flags : I
        //   233: iconst_2
        //   234: iand
        //   235: ifeq -> 447
        //   238: aload_0
        //   239: getfield mBufferInfo : Landroid/media/MediaCodec$BufferInfo;
        //   242: iconst_0
        //   243: putfield size : I
        //   246: goto -> 249
        //   249: aload_0
        //   250: getfield mBufferInfo : Landroid/media/MediaCodec$BufferInfo;
        //   253: getfield size : I
        //   256: ifeq -> 450
        //   259: aload_0
        //   260: getfield mMuxerStarted : Z
        //   263: ifeq -> 343
        //   266: aload #4
        //   268: aload_0
        //   269: getfield mBufferInfo : Landroid/media/MediaCodec$BufferInfo;
        //   272: getfield offset : I
        //   275: invokevirtual position : (I)Ljava/nio/Buffer;
        //   278: pop
        //   279: aload #4
        //   281: aload_0
        //   282: getfield mBufferInfo : Landroid/media/MediaCodec$BufferInfo;
        //   285: getfield offset : I
        //   288: aload_0
        //   289: getfield mBufferInfo : Landroid/media/MediaCodec$BufferInfo;
        //   292: getfield size : I
        //   295: iadd
        //   296: invokevirtual limit : (I)Ljava/nio/Buffer;
        //   299: pop
        //   300: aload_0
        //   301: getfield mBufferInfo : Landroid/media/MediaCodec$BufferInfo;
        //   304: aload_0
        //   305: getfield mFakePts : J
        //   308: putfield presentationTimeUs : J
        //   311: aload_0
        //   312: aload_0
        //   313: getfield mFakePts : J
        //   316: ldc2_w 50000
        //   319: ladd
        //   320: putfield mFakePts : J
        //   323: aload_0
        //   324: getfield mMuxer : Landroid/media/MediaMuxer;
        //   327: aload_0
        //   328: getfield mTrackIndex : I
        //   331: aload #4
        //   333: aload_0
        //   334: getfield mBufferInfo : Landroid/media/MediaCodec$BufferInfo;
        //   337: invokevirtual writeSampleData : (ILjava/nio/ByteBuffer;Landroid/media/MediaCodec$BufferInfo;)V
        //   340: goto -> 353
        //   343: new java/lang/RuntimeException
        //   346: dup
        //   347: ldc 'muxer hasn't started'
        //   349: invokespecial <init> : (Ljava/lang/String;)V
        //   352: athrow
        //   353: aload_0
        //   354: getfield mEncoder : Landroid/media/MediaCodec;
        //   357: iload_2
        //   358: iconst_0
        //   359: invokevirtual releaseOutputBuffer : (IZ)V
        //   362: aload_0
        //   363: getfield mBufferInfo : Landroid/media/MediaCodec$BufferInfo;
        //   366: getfield flags : I
        //   369: iconst_4
        //   370: iand
        //   371: ifeq -> 393
        //   374: iload_1
        //   375: ifne -> 390
        //   378: getstatic com/ais/canvasrecorddemo/RecordingHelper.TAG : Ljava/lang/String;
        //   381: ldc 'reached end of stream unexpectedly'
        //   383: invokestatic w : (Ljava/lang/String;Ljava/lang/String;)I
        //   386: pop
        //   387: goto -> 390
        //   390: aload_0
        //   391: monitorexit
        //   392: return
        //   393: goto -> 24
        //   396: new java/lang/StringBuilder
        //   399: dup
        //   400: invokespecial <init> : ()V
        //   403: astore_3
        //   404: aload_3
        //   405: ldc 'encoderOutputBuffer '
        //   407: invokevirtual append : (Ljava/lang/String;)Ljava/lang/StringBuilder;
        //   410: pop
        //   411: aload_3
        //   412: iload_2
        //   413: invokevirtual append : (I)Ljava/lang/StringBuilder;
        //   416: pop
        //   417: aload_3
        //   418: ldc ' was null'
        //   420: invokevirtual append : (Ljava/lang/String;)Ljava/lang/StringBuilder;
        //   423: pop
        //   424: new java/lang/RuntimeException
        //   427: dup
        //   428: aload_3
        //   429: invokevirtual toString : ()Ljava/lang/String;
        //   432: invokespecial <init> : (Ljava/lang/String;)V
        //   435: athrow
        //   436: astore_3
        //   437: aload_0
        //   438: monitorexit
        //   439: aload_3
        //   440: athrow
        //   441: goto -> 16
        //   444: goto -> 393
        //   447: goto -> 249
        //   450: goto -> 353
        // Exception table:
        //   from	to	target	type
        //   6	13	436	finally
        //   16	24	436	finally
        //   24	39	436	finally
        //   57	65	436	finally
        //   74	156	436	finally
        //   159	169	436	finally
        //   173	213	436	finally
        //   226	246	436	finally
        //   249	340	436	finally
        //   343	353	436	finally
        //   353	374	436	finally
        //   378	387	436	finally
        //   396	436	436	finally
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
            //   19: aload_0
            //   20: getfield mInputSurface : Landroid/view/Surface;
            //   23: aload_2
            //   24: invokevirtual unlockCanvasAndPost : (Landroid/graphics/Canvas;)V
            //   27: aload_0
            //   28: monitorexit
            //   29: return
            //   30: astore_2
            //   31: aload_0
            //   32: monitorexit
            //   33: aload_2
            //   34: athrow
            // Exception table:
            //   from	to	target	type
            //   2	27	30	finally
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
                    throw new RuntimeException(e);
                } finally {}
            }

            private void generateMovieOld(File paramFile) {
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
                releaseEncoder();

            }

            private void prepareEncoder(File paramFile) throws IOException {
                this.mBufferInfo = new MediaCodec.BufferInfo();
                MediaFormat mediaFormat = MediaFormat.createVideoFormat("video/avc", WIDTH, HEIGHT);
                mediaFormat.setInteger("color-format", 2130708361);
                mediaFormat.setInteger("bitrate", 300000);
                mediaFormat.setInteger("frame-rate", 20);
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

            public void startRecording() {
                try {
                    prepareEncoder(this.outputFile);
                    this.timer = new Timer();
                    this.timer.schedule(new TimerTask() {
                        public void run() { RecordingHelper.this.executorService.submit(new Runnable() {
                            public void run() {
                                long l = System.currentTimeMillis();
                                drainEncoder(false);
                                synchronized (mInputSurface) {
                                    generateFrame(0);

                                    StringBuilder stringBuilder = new StringBuilder();
                                    stringBuilder.append("Recording frame ");
                                    stringBuilder.append(System.currentTimeMillis() - l);
                                    Log.i(TAG, stringBuilder.toString());
                                    return;
                                }
                            }
                        }); }
                    }, 0L, 50L);
                    return;
                } catch (IOException iOException) {
                    iOException.printStackTrace();
                    return;
                }
            }

            public void stopRecording() {
                this.timer.cancel();
                this.executorService.execute(new Runnable() {
                    public void run() {
                        try {
                            synchronized (RecordingHelper.this.mEncoder) {
                                RecordingHelper.this.drainEncoder(true);
                            }
                        } catch (Exception exception) {
                            exception.printStackTrace();
                        }
                        RecordingHelper.this.releaseEncoder();
                    }
                });
            }
        }
