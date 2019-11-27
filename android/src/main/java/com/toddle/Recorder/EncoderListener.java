package com.toddle.Recorder;

import android.media.MediaCodec;
import android.media.MediaFormat;


import java.nio.ByteBuffer;

import androidx.annotation.NonNull;

public interface EncoderListener {
    int addTrackToMuxer(MediaFormat paramMediaFormat);

    boolean isMuxerStarted();

    void releaseMuxer();

    void startMuxer();

    void writeSampleData(int paramInt, @NonNull ByteBuffer paramByteBuffer, @NonNull MediaCodec.BufferInfo paramBufferInfo);

    void runOnUiThread(Runnable runnable);

    void onRecorded();
}
