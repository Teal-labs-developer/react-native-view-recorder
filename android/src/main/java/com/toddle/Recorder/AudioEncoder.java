package com.toddle.Recorder;

import android.content.Context;
import android.media.MediaCodec;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.os.Environment;
import android.util.Log;
import android.widget.Toast;
import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.Date;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class AudioEncoder {
    private static final String AUDIO_MIME_TYPE = "audio/mp4a-latm";

    private static final String TAG = "AudioEncoder";

    private static final int TOTAL_NUM_TRACKS = 1;

    private static final boolean VERBOSE = true;

    private static long audioBytesReceived = 0L;

    private static int numTracksAdded = 0;

    private MediaFormat audioFormat;

    AudioSoftwarePoller audioSoftwarePoller;

    long audioStartTime = 0L;

    Context c;

    private ExecutorService encodingService = Executors.newSingleThreadExecutor();

    int encodingServiceQueueLength = 0;

    boolean eosReceived = false;

    boolean eosSentToAudioEncoder = false;

    int frameCount = 0;

    private MediaCodec.BufferInfo mAudioBufferInfo;

    private MediaCodec mAudioEncoder;

    private TrackIndex mAudioTrackIndex = new TrackIndex();

    private MediaMuxer mMuxer;

    private boolean mMuxerStarted;

    boolean stopReceived = false;

    int totalInputAudioFrameCount = 0;

    int totalOutputAudioFrameCount = 0;

    public AudioEncoder(Context paramContext) {
        this.c = paramContext;
        try {
            prepare();
            return;
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }
    }

    private void _offerAudioEncoder(byte[] paramArrayOfByte, long paramLong) {
        if (audioBytesReceived == 0L)
            this.audioStartTime = paramLong;
        this.totalInputAudioFrameCount++;
        audioBytesReceived += paramArrayOfByte.length;
        if ((this.eosSentToAudioEncoder && this.stopReceived) || paramArrayOfByte == null) {
            logStatistics();
            if (this.eosReceived) {
                Log.i("AudioEncoder", "EOS received in offerAudioEncoder");
                closeEncoderAndMuxer(this.mAudioEncoder, this.mAudioBufferInfo, this.mAudioTrackIndex);
                this.eosSentToAudioEncoder = true;
                if (!this.stopReceived)
                    return;
                Log.i("AudioEncoder", "Stopping Encoding Service");
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
                    Log.i("AudioEncoder", "EOS received in offerEncoder");
                    this.mAudioEncoder.queueInputBuffer(i, 0, paramArrayOfByte.length, paramLong, 4);
                    closeEncoderAndMuxer(this.mAudioEncoder, this.mAudioBufferInfo, this.mAudioTrackIndex);
                    this.eosSentToAudioEncoder = true;
                    if (this.stopReceived) {
                        Log.i("AudioEncoder", "Stopping Encoding Service");
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
        } catch (Exception e) {
            Log.e("AudioEncoder", "_offerAudioEncoder exception");
            e.printStackTrace();
            return;
        }
    }

    private void drainEncoder(MediaCodec paramMediaCodec, MediaCodec.BufferInfo paramBufferInfo, TrackIndex paramTrackIndex, boolean paramBoolean) {
        int i;
        StringBuilder stringBuilder2 = new StringBuilder();
        stringBuilder2.append("drainEncoder(");
        stringBuilder2.append(paramBoolean);
        stringBuilder2.append(")");
        Log.d("AudioEncoder", stringBuilder2.toString());
        ByteBuffer[] arrayOfByteBuffer = paramMediaCodec.getOutputBuffers();
        while (true) {
            i = paramMediaCodec.dequeueOutputBuffer(paramBufferInfo, 100L);
            if (i == -1) {
                if (paramBoolean) {
                    Log.d("AudioEncoder", "no output available, spinning to await EOS");
                    continue;
                }
            } else {
                if (i == -3) {
                    arrayOfByteBuffer = paramMediaCodec.getOutputBuffers();
                    continue;
                }
                if (i == -2) {
                    if (!this.mMuxerStarted) {
                        MediaFormat mediaFormat = paramMediaCodec.getOutputFormat();
                        paramTrackIndex.index = this.mMuxer.addTrack(mediaFormat);
                        numTracksAdded++;
                        StringBuilder stringBuilder = new StringBuilder();
                        stringBuilder.append("encoder output format changed: ");
                        stringBuilder.append(mediaFormat);
                        stringBuilder.append(". Added track index: ");
                        stringBuilder.append(paramTrackIndex.index);
                        Log.d("AudioEncoder", stringBuilder.toString());
                        if (numTracksAdded == 1) {
                            this.mMuxer.start();
                            this.mMuxerStarted = true;
                            Log.i("AudioEncoder", "All tracks added. Muxer started");
                        }
                        continue;
                    }
                    throw new RuntimeException("format changed after muxer start");
                }
                if (i < 0) {
                    StringBuilder stringBuilder = new StringBuilder();
                    stringBuilder.append("unexpected result from encoder.dequeueOutputBuffer: ");
                    stringBuilder.append(i);
                    Log.w("AudioEncoder", stringBuilder.toString());
                    continue;
                }
                ByteBuffer byteBuffer = arrayOfByteBuffer[i];
                if (byteBuffer != null) {
                    if ((paramBufferInfo.flags & 0x2) != 0) {
                        Log.d("AudioEncoder", "ignoring BUFFER_FLAG_CODEC_CONFIG");
                        paramBufferInfo.size = 0;
                    }
                    if (paramBufferInfo.size != 0)
                        if (this.mMuxerStarted) {
                            byteBuffer.position(paramBufferInfo.offset);
                            byteBuffer.limit(paramBufferInfo.offset + paramBufferInfo.size);
                            this.mMuxer.writeSampleData(paramTrackIndex.index, byteBuffer, paramBufferInfo);
                        } else {
                            throw new RuntimeException("muxer hasn't started");
                        }
                    paramMediaCodec.releaseOutputBuffer(i, false);
                    if ((paramBufferInfo.flags & 0x4) != 0) {
                        if (!paramBoolean) {
                            Log.w("AudioEncoder", "reached end of stream unexpectedly");
                        } else {
                            Log.d("AudioEncoder", "end of stream reached");
                        }
                    } else {
                        continue;
                    }
                } else {
                    break;
                }
            }
            System.nanoTime();
            return;
        }
        StringBuilder stringBuilder1 = new StringBuilder();
        stringBuilder1.append("encoderOutputBuffer ");
        stringBuilder1.append(i);
        stringBuilder1.append(" was null");
        throw new RuntimeException(stringBuilder1.toString());
    }

    private void logStatistics() {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("audio frames input: ");
        stringBuilder.append(this.totalInputAudioFrameCount);
        stringBuilder.append(" output: ");
        stringBuilder.append(this.totalOutputAudioFrameCount);
        Log.i("AudioEncoder-Stats", stringBuilder.toString());
    }

    private void prepare() throws IOException {
        audioBytesReceived = 0L;
        numTracksAdded = 0;
        this.frameCount = 0;
        this.eosReceived = false;
        this.eosSentToAudioEncoder = false;
        this.stopReceived = false;
        File file = Environment.getExternalStorageDirectory();
        StringBuilder stringBuilder1 = new StringBuilder();
        stringBuilder1.append("test_");
        stringBuilder1.append((new Date()).getTime());
        stringBuilder1.append(".m4a");
        file = new File(file, stringBuilder1.toString());
        Context context = this.c;
        StringBuilder stringBuilder2 = new StringBuilder();
        stringBuilder2.append("Saving audio to: ");
        stringBuilder2.append(file.getAbsolutePath());
//        Toast.makeText(context, stringBuilder2.toString(), Toast.LENGTH_SHORT).show();
        this.mAudioBufferInfo = new MediaCodec.BufferInfo();
        this.audioFormat = new MediaFormat();
        this.audioFormat.setString("mime", "audio/mp4a-latm");
        this.audioFormat.setInteger("aac-profile", 2);
        this.audioFormat.setInteger("sample-rate", 44100);
        this.audioFormat.setInteger("channel-count", 1);
        this.audioFormat.setInteger("bitrate", 128000);
        this.audioFormat.setInteger("max-input-size", 16384);
        this.mAudioEncoder = MediaCodec.createEncoderByType("audio/mp4a-latm");
        this.mAudioEncoder.configure(this.audioFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
        this.mAudioEncoder.start();
        this.mMuxer = new MediaMuxer(file.getAbsolutePath(), MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
    }

    public void _stop() {
        this.stopReceived = true;
        this.eosReceived = true;
        logStatistics();
        Log.i(TAG, "Audio stopped");
    }

    public void closeEncoder(MediaCodec paramMediaCodec, MediaCodec.BufferInfo paramBufferInfo, TrackIndex paramTrackIndex) {
        drainEncoder(paramMediaCodec, paramBufferInfo, paramTrackIndex, true);
        try {
            paramMediaCodec.stop();
            paramMediaCodec.release();
            return;
        } catch (Exception e) {
            e.printStackTrace();
            return;
        }
    }

    public void closeEncoderAndMuxer(MediaCodec paramMediaCodec, MediaCodec.BufferInfo paramBufferInfo, TrackIndex paramTrackIndex) {
        drainEncoder(paramMediaCodec, paramBufferInfo, paramTrackIndex, true);
        try {
            paramMediaCodec.stop();
            paramMediaCodec.release();
            closeMuxer();
            return;
        } catch (Exception e) {
            e.printStackTrace();
            return;
        }
    }

    public void closeMuxer() {
        this.mMuxer.stop();
        this.mMuxer.release();
        this.mMuxer = null;
        this.mMuxerStarted = false;
    }

    public void offerAudioEncoder(byte[] paramArrayOfByte, long paramLong) {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("offerAudioEncoder ");
        stringBuilder.append(this.encodingService.isShutdown());
        Log.i("AudioEncoder", stringBuilder.toString());
        if (!this.encodingService.isShutdown()) {
            this.encodingService.submit(new EncoderTask(this, paramArrayOfByte, paramLong));
            this.encodingServiceQueueLength++;
            return;
        }
    }

    public void setAudioSoftwarePoller(AudioSoftwarePoller paramAudioSoftwarePoller) { this.audioSoftwarePoller = paramAudioSoftwarePoller; }

    public void stop() {
        if (!this.encodingService.isShutdown()) {
            this.encodingService.submit(new EncoderTask(this, EncoderTaskType.FINALIZE_ENCODER));
            return;
        }
    }

    private class EncoderTask implements Runnable {
        private static final String TAG = "encoderTask";

        private byte[] audio_data;

        private AudioEncoder encoder;

        boolean is_initialized = false;

        long presentationTimeNs;

        private AudioEncoder.EncoderTaskType type;

        public EncoderTask(AudioEncoder param1AudioEncoder1) {
            setEncoder(param1AudioEncoder1);
            setFinalizeEncoderParams();
        }

        public EncoderTask(AudioEncoder param1AudioEncoder1, AudioEncoder.EncoderTaskType param1EncoderTaskType) {
            setEncoder(param1AudioEncoder1);
            this.type = param1EncoderTaskType;

            setFinalizeEncoderParams();
        }

        public EncoderTask(AudioEncoder param1AudioEncoder1, byte[] param1ArrayOfByte, long param1Long) {
            setEncoder(param1AudioEncoder1);
            setEncodeFrameParams(param1ArrayOfByte, param1Long);
        }

        private void encodeFrame() {
            AudioEncoder audioEncoder = this.encoder;
            if (audioEncoder != null) {
                byte[] arrayOfByte = this.audio_data;
                if (arrayOfByte != null) {
                    audioEncoder._offerAudioEncoder(arrayOfByte, this.presentationTimeNs);
                    this.audio_data = null;
                    return;
                }
            }
        }

        private void finalizeEncoder() { this.encoder._stop(); }

        private void setEncodeFrameParams(byte[] param1ArrayOfByte, long param1Long) {
            this.audio_data = param1ArrayOfByte;
            this.presentationTimeNs = param1Long;
            this.is_initialized = true;
            this.type = AudioEncoder.EncoderTaskType.ENCODE_FRAME;
        }

        private void setEncoder(AudioEncoder param1AudioEncoder) { this.encoder = param1AudioEncoder; }

        private void setFinalizeEncoderParams() { this.is_initialized = true; }

        public void run() {
            if (this.is_initialized) {
                switch (this.type) {
                    case ENCODE_FRAME:
                        encodeFrame();
                        break;
                    case FINALIZE_ENCODER:
                        finalizeEncoder();
                        break;
                }
                this.is_initialized = false;
                AudioEncoder audioEncoder = AudioEncoder.this;
                audioEncoder.encodingServiceQueueLength--;
                return;
            }
            Log.e("encoderTask", "run() called but EncoderTask not initialized");
        }
    }

    enum EncoderTaskType {
        ENCODE_FRAME, FINALIZE_ENCODER;

    }

    class TrackIndex {
        int index = 0;
    }
}
