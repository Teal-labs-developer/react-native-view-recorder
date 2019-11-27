package com.toddle.Recorder;

import android.media.AudioRecord;
import android.util.Log;

import com.toddle.Recorder.AudioEncoder;

import java.util.concurrent.ArrayBlockingQueue;

public class AudioSoftwarePoller {
    public static final int AUDIO_FORMAT = 2;

    public static final int CHANNEL_CONFIG = 16;

    public static final int FRAMES_PER_BUFFER = 24;

    public static final int SAMPLE_RATE = 44100;

    public static final String TAG = "AudioSoftwarePoller";

    public static long US_PER_FRAME = 0L;

    public static boolean is_recording = false;

    final boolean VERBOSE = false;

    AudioEncoder audioEncoder;

    public RecorderTask recorderTask = new RecorderTask();

    public long getMicroSecondsPerFrame() {
        if (US_PER_FRAME == 0L)
            US_PER_FRAME = (44100 / this.recorderTask.samples_per_frame * 1000000);
        return US_PER_FRAME;
    }

    public void recycleInputBuffer(byte[] paramArrayOfByte) { this.recorderTask.data_buffer.offer(paramArrayOfByte); }

    public void setAudioEncoder(AudioEncoder paramAudioEncoder) { this.audioEncoder = paramAudioEncoder; }

    public void setSamplesPerFrame(int paramInt) {
        if (!is_recording) {
            this.recorderTask.samples_per_frame = paramInt;
            return;
        }
    }

    public void startPolling() { (new Thread(this.recorderTask)).start(); }

    public void stopPolling() { is_recording = false; }

    public class RecorderTask implements Runnable {
        public int buffer_size;

        public int buffer_write_index = 0;

        ArrayBlockingQueue<byte[]> data_buffer = new ArrayBlockingQueue(50);

        int read_result = 0;

        public int samples_per_frame = 2048;

        public int total_frames_written = 0;

        public void run() {
            int i = AudioRecord.getMinBufferSize(44100, 16, 2);
            int j = this.samples_per_frame;
            this.buffer_size = j * 24;
            if (this.buffer_size < i)
                this.buffer_size = (i / j + 1) * j * 2;
            for (i = 0; i < 25; i++)
                this.data_buffer.add(new byte[this.samples_per_frame]);
            AudioRecord audioRecord = new AudioRecord(1, 44100, 16, 2, this.buffer_size);
            audioRecord.startRecording();
            AudioSoftwarePoller.is_recording = true;
            Log.i("AudioSoftwarePoller", "SW recording begin");
            while (AudioSoftwarePoller.is_recording) {
                byte[] arrayOfByte;
                long l = System.nanoTime();
                if (this.data_buffer.isEmpty()) {
                    arrayOfByte = new byte[this.samples_per_frame];
                } else {
                    arrayOfByte = (byte[])this.data_buffer.poll();
                }
                this.read_result = audioRecord.read(arrayOfByte, 0, this.samples_per_frame);
                i = this.read_result;
                if (i == -2 || i == -3)
                    Log.e("AudioSoftwarePoller", "Read error");
                this.total_frames_written++;
                if (AudioSoftwarePoller.this.audioEncoder != null)
                    AudioSoftwarePoller.this.audioEncoder.offerAudioEncoder(arrayOfByte, l);
            }
            audioRecord.setRecordPositionUpdateListener(null);
            audioRecord.release();
            Log.i("AudioSoftwarePoller", "stopped");
        }
    }
}
