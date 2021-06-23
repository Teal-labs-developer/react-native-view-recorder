package com.toddle.Recorder;

import android.content.Context;
import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaFormat;
import android.os.Environment;
import android.util.Log;

import com.toddle.Recorder.EncoderListener;

import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.Date;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class AudioEncoder2 {
    private static final String AUDIO_MIME_TYPE = "audio/mp4a-latm";

    private static final String TAG = "AudioEncoder";

    private static final int TOTAL_NUM_TRACKS = 1;

    private static final boolean VERBOSE = false;

    private static long audioBytesReceived = 0L;

    private static int numTracksAdded = 0;

    private MediaFormat audioFormat;

    AudioSoftwarePoller audioSoftwarePoller;

    long audioStartTime = 0L;

    Context c;

    private EncoderListener encoderListener;

    private ExecutorService encodingService = Executors.newSingleThreadExecutor();

    int encodingServiceQueueLength = 0;

    boolean eosReceived = false;

    boolean eosSentToAudioEncoder = false;

    int frameCount = 0;

    private MediaCodec.BufferInfo mAudioBufferInfo;

    private MediaCodec mAudioEncoder;

    private TrackIndex mAudioTrackIndex = new TrackIndex();

    private boolean mMuxerStarted;

    boolean stopReceived = false;

    int totalInputAudioFrameCount = 0;

    int totalOutputAudioFrameCount = 0;

    public AudioEncoder2(EncoderListener paramEncoderListener) throws IOException {
        this.encoderListener = paramEncoderListener;
        prepare();
    }

    private void _offerAudioEncoder(byte[] paramArrayOfByte, long paramLong) throws IOException {
        if (audioBytesReceived == 0L)
            this.audioStartTime = paramLong;
        this.totalInputAudioFrameCount++;
        audioBytesReceived += paramArrayOfByte.length;
        if ((this.eosSentToAudioEncoder && this.stopReceived) || paramArrayOfByte == null) {
            logStatistics();
            if (this.eosReceived) {
//                Log.i("AudioEncoder", "EOS received in offerAudioEncoder");
                closeEncoder(this.mAudioEncoder, this.mAudioBufferInfo, this.mAudioTrackIndex);
                this.eosSentToAudioEncoder = true;
                if (!this.stopReceived) {
                    prepare();
                    return;
                }
//                Log.i("AudioEncoder", "Stopping Encoding Service");
                this.encodingService.shutdown();
                return;
            }
            return;
        }
        drainEncoder(this.mAudioEncoder, this.mAudioBufferInfo, this.mAudioTrackIndex, false);
        try {
            ByteBuffer[] arrayOfByteBuffer = this.mAudioEncoder.getInputBuffers();
            int i = this.mAudioEncoder.dequeueInputBuffer(-1L);
            if (i >= 0) {
                ByteBuffer byteBuffer = arrayOfByteBuffer[i];
                byteBuffer.clear();
                byteBuffer.put(paramArrayOfByte);
                if (this.audioSoftwarePoller != null)
                    this.audioSoftwarePoller.recycleInputBuffer(paramArrayOfByte);
                paramLong = (paramLong - this.audioStartTime) / 1000L;
                if (this.eosReceived) {
//                    Log.i("AudioEncoder", "EOS received in offerEncoder");
                    this.mAudioEncoder.queueInputBuffer(i, 0, paramArrayOfByte.length, paramLong, 4);
                    closeEncoder(this.mAudioEncoder, this.mAudioBufferInfo, this.mAudioTrackIndex);
                    this.eosSentToAudioEncoder = true;
                    if (this.stopReceived) {
//                        Log.i("AudioEncoder", "Stopping Encoding Service");
                        this.encodingService.shutdown();
                        return;
                    }
                } else {
                    this.mAudioEncoder.queueInputBuffer(i, 0, paramArrayOfByte.length, paramLong, 0);
                    return;
                }
            } else {
                return;
            }
        } catch (Throwable e) {
            Log.e("AudioEncoder", "_offerAudioEncoder exception");
            e.printStackTrace();
            return;
        }
    }

    private void drainEncoder(MediaCodec paramMediaCodec, MediaCodec.BufferInfo paramBufferInfo, TrackIndex paramTrackIndex, boolean paramBoolean) {
        int i;
        ByteBuffer[] arrayOfByteBuffer = paramMediaCodec.getOutputBuffers();
        while (true) {
            i = paramMediaCodec.dequeueOutputBuffer(paramBufferInfo, 100L);
            if (i == -1) {
                if (!paramBoolean) {
                    System.nanoTime();
                    return;
                }
                continue;
            }
            if (i == -3) {
                arrayOfByteBuffer = paramMediaCodec.getOutputBuffers();
                continue;
            }
            if (i == -2) {
                EncoderListener encoderListener1 = this.encoderListener;
                if (encoderListener1 == null || !encoderListener1.isMuxerStarted()) {
                    MediaFormat mediaFormat = paramMediaCodec.getOutputFormat();
                    EncoderListener encoderListener2 = this.encoderListener;
                    if (encoderListener2 != null) {
                        paramTrackIndex.index = encoderListener2.addTrackToMuxer(mediaFormat);
                        this.encoderListener.startMuxer();
                    }
                    continue;
                }
                throw new RuntimeException("format changed after muxer start");
            }
            if (i < 0) {
                StringBuilder stringBuilder1 = new StringBuilder();
                stringBuilder1.append("unexpected result from encoder.dequeueOutputBuffer: ");
                stringBuilder1.append(i);
                Log.w("AudioEncoder", stringBuilder1.toString());
                continue;
            }
            ByteBuffer byteBuffer = arrayOfByteBuffer[i];
            if (byteBuffer != null) {
                if ((paramBufferInfo.flags & 0x2) != 0)
                    paramBufferInfo.size = 0;
                if (paramBufferInfo.size != 0) {
                    EncoderListener encoderListener1 = this.encoderListener;
                    if (encoderListener1 == null || encoderListener1.isMuxerStarted()) {
                        byteBuffer.position(paramBufferInfo.offset);
                        byteBuffer.limit(paramBufferInfo.offset + paramBufferInfo.size);
                        encoderListener1 = this.encoderListener;
                        if (encoderListener1 != null)
                            encoderListener1.writeSampleData(paramTrackIndex.index, byteBuffer, paramBufferInfo);
                    } else {
                        throw new RuntimeException("muxer hasn't started");
                    }
                }
                paramMediaCodec.releaseOutputBuffer(i, false);
                if ((paramBufferInfo.flags & 0x4) != 0) {
                    if (!paramBoolean)
                        Log.w("AudioEncoder", "reached end of stream unexpectedly");
                } else {
                    continue;
                }
            } else {
                break;
            }
            System.nanoTime();
            return;
        }
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("encoderOutputBuffer ");
        stringBuilder.append(i);
        stringBuilder.append(" was null");
        throw new RuntimeException(stringBuilder.toString());
    }

    private void logStatistics() {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("audio frames input: ");
        stringBuilder.append(this.totalInputAudioFrameCount);
        stringBuilder.append(" output: ");
        stringBuilder.append(this.totalOutputAudioFrameCount);
//        Log.i("AudioEncoder-Stats", stringBuilder.toString());
    }

    private void prepare() throws IOException {
        audioBytesReceived = 0L;
        numTracksAdded = 0;
        this.frameCount = 0;
        this.eosReceived = false;
        this.eosSentToAudioEncoder = false;
        this.stopReceived = false;
        File file = Environment.getExternalStorageDirectory();
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("test_");
        stringBuilder.append((new Date()).getTime());
        stringBuilder.append(".m4a");
        new File(file, stringBuilder.toString());
        this.mAudioBufferInfo = new MediaCodec.BufferInfo();
        this.audioFormat = new MediaFormat();
        this.audioFormat.setString("mime", MediaFormat.MIMETYPE_AUDIO_AAC);
        this.audioFormat.setInteger("aac-profile", 2);
        this.audioFormat.setInteger("sample-rate", 44100);
        this.audioFormat.setInteger("channel-count", 1);
        this.audioFormat.setInteger("bitrate", 128000);
        this.audioFormat.setInteger("max-input-size", 16384);
        this.audioFormat.setInteger(MediaFormat.KEY_AAC_PROFILE,
                MediaCodecInfo.CodecProfileLevel.AACObjectLC);
        this.mAudioEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC);
        this.mAudioEncoder.configure(this.audioFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
        this.mAudioEncoder.start();
    }

    public void closeEncoder(MediaCodec paramMediaCodec, MediaCodec.BufferInfo paramBufferInfo, TrackIndex paramTrackIndex) {
        drainEncoder(paramMediaCodec, paramBufferInfo, paramTrackIndex, true);
        try {
            paramMediaCodec.stop();
            paramMediaCodec.release();
            EncoderListener encoderListener1 = this.encoderListener;
            return;
        } catch (Exception e) {
            e.printStackTrace();
            return;
        }
    }

    public void offerAudioEncoder(final byte[] input, final long presentationTimeStampNs) throws IOException {
        if (!this.encodingService.isShutdown()) {
            this.encodingService.submit(new Runnable() {
                public void run() {
                    StringBuilder stringBuilder = new StringBuilder();
                    stringBuilder.append("drained encoder audio ");
                    stringBuilder.append(Thread.currentThread().getId());
//                    Log.i("AudioEncoder", stringBuilder.toString());
                    try {
                        AudioEncoder2.this._offerAudioEncoder(input, presentationTimeStampNs);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    encodingServiceQueueLength--;
                }
            });
            this.encodingServiceQueueLength++;
            return;
        }
    }

    public void setEncoderListener(EncoderListener paramEncoderListener) throws IOException { this.encoderListener = paramEncoderListener; }

    public void stop() {
        this.stopReceived = true;
        this.eosReceived = true;
        logStatistics();
    }

    class TrackIndex {
        int index = 0;
    }
}
