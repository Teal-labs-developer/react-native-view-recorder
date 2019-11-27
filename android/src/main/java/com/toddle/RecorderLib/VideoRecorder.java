package com.toddle.RecorderLib;

import android.os.AsyncTask;
import android.util.Log;

import com.toddle.Recorder.EncoderListener;
import com.toddle.Sketch.DrawView;

import java.io.IOException;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class VideoRecorder {
    private static final int FRAMES_PER_SECOND = 20;

    public static String TAG = "VideoRecorder";

    private boolean isRecording = false;

    private DrawView drawView;

    private EncoderListener encoderListener;

    ExecutorService executorService = Executors.newFixedThreadPool(1);

    Timer timer;

    VideoEncoder videoEncoder;

    public VideoRecorder(EncoderListener paramEncoderListener, DrawView paramDrawView) {
        this.encoderListener = paramEncoderListener;
        this.drawView = paramDrawView;
    }

    int frameNum = 0;

    public void startRecording() throws IOException {
        isRecording = true;
        this.videoEncoder = new VideoEncoder(this.encoderListener, this.drawView);


//        new Thread(new Runnable() {
//            @Override
//            public void run() {
//                while (isRecording){
//                    videoEncoder.drainEncoder(false);
//                    videoEncoder.generateFrame(frameNum);
//                    frameNum++;
//                }
//                try {
//                    videoEncoder.drainEncoder(true);
//                    videoEncoder.releaseEncoder();
//                } catch (Exception exception) {
//                    exception.printStackTrace();
//                }
//            }
//        }).start();




        executorService.submit(new Runnable() {
            @Override
            public void run() {
                while (isRecording){
                    videoEncoder.drainEncoder(false);
                    videoEncoder.generateFrame(frameNum);
                    frameNum++;
                }
            }
        });

        this.timer = new Timer();
//        this.timer.schedule(new TimerTask() {
//            public void run() {
//                executorService.submit(new Runnable() {
//                    public void run() {
//
//                        long l = System.currentTimeMillis();
//                        videoEncoder.drainEncoder(false);
//                        synchronized (videoEncoder.mInputSurface) {
//                            videoEncoder.generateFrame(frameNum);
//                            frameNum++;
//                        }
//                    }
//                });
//            }
//        },0, 50);
    }

    public void stopRecording() throws IOException {
        Log.i(TAG, "stopRecording ");
        isRecording = false;
//        this.timer.cancel();

        this.executorService.execute(new Runnable() {
            public void run() {
                try {
                    videoEncoder.drainEncoder(true);
                    videoEncoder.releaseEncoder();
                } catch (Exception exception) {
                    exception.printStackTrace();
                }

            }
        });
    }
}
