package com.toddle.Recorder;

import android.media.AudioRecord;
import android.util.Log;
import java.io.IOException;
import java.util.concurrent.ArrayBlockingQueue;

public class AudioRecorder {
    public static final int AUDIO_FORMAT = 2;

    public static final int CHANNEL_CONFIG = 16;

    public static final int FRAMES_PER_BUFFER = 20;

    public static final int SAMPLE_RATE = 44100;

    public static final String TAG = "AudioSoftwarePoller";

    public static long US_PER_FRAME = 0L;

    final boolean VERBOSE = false;

    boolean isRecording = false;

    AudioEncoder2 audioEncoder;

    EncoderListener encoderListener;

    public AudioRecorder(EncoderListener paramEncoderListener) { this.encoderListener = paramEncoderListener; }

    public void startRecording() throws IOException {
        this.isRecording = true;
        this.audioEncoder = new AudioEncoder2(this.encoderListener);
        (new Thread(new RecorderTask())).start();
    }

    public void stopRecording() throws IOException { this.isRecording = false; }

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
            this.buffer_size = j * 20;
            if (this.buffer_size < i)
                this.buffer_size = (i / j + 1) * j * 2;
            for (i = 0; i < 25; i++)
                this.data_buffer.add(new byte[this.samples_per_frame]);
            AudioRecord audioRecord = new AudioRecord(1, 44100, 16, 2, this.buffer_size);
            audioRecord.startRecording();
//            AudioRecorder.access$002(AudioRecorder.this, true);
            Log.i("AudioSoftwarePoller", "SW recording begin");
            while (AudioRecorder.this.isRecording) {
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
                if (AudioRecorder.this.audioEncoder != null) {
                    try {
                        AudioRecorder.this.audioEncoder.offerAudioEncoder(arrayOfByte, l);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
            if (AudioRecorder.this.audioEncoder != null)
                AudioRecorder.this.audioEncoder.stop();
            audioRecord.setRecordPositionUpdateListener(null);
            audioRecord.release();
            Log.i("AudioSoftwarePoller", "stopped");
        }
    }
}
