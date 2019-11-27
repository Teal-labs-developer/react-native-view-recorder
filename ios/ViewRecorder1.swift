//
//  ViewRecorder.swift
//  RNViewRecorder
//
//  Created by Toddle on 02/08/19.
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Foundation

class ViewRecorder1:NSObject, AVCaptureAudioDataOutputSampleBufferDelegate{
    
    var isRecording:Bool = false;
    var image:UIImage?
    var imageView:DrawView?
    var frame:CGRect?
    var drawView: DrawView?
    
    var captureSession:AVCaptureSession?
    var audioConnection:AVCaptureConnection?
    
    var assetWriter:AVAssetWriter?
    
    var audioWriterInput:AVAssetWriterInput?
    
    var videoAdaptor:AVAssetWriterInputPixelBufferAdaptor?
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        
        if(connection == audioConnection && audioWriterInput != nil && (audioWriterInput?.isReadyForMoreMediaData)! && isRecording && assetWriter?.status == AVAssetWriter.Status.writing){
            do{
                var appended = try audioWriterInput!.append(sampleBuffer)
            }
            catch{
                
            }
            //            print("audio appended", appended)
        }
        
    }
    
    
    init(image: UIImage) {
        self.image = image
    }
    
    init(imageView: DrawView,  frame: CGRect, drawView: DrawView) {
        super.init()
        self.imageView = imageView
        //        self.image = imageView.image!
        self.frame = frame
        self.drawView = drawView
        
        captureSession = AVCaptureSession()
        
        if (captureSession == nil) {
            fatalError("ERROR: Couldnt create a capture session")
        }
        
        captureSession?.beginConfiguration()
        
        
        
        
        
        do {
            let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
            let audioDeviceInput: AVCaptureDeviceInput
            do {
                audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            }
            catch {
                fatalError("Could not create AVCaptureDeviceInput instance with error: \(error).")
            }
            guard (captureSession?.canAddInput(audioDeviceInput))! else {
                fatalError()
            }
            captureSession?.addInput(audioDeviceInput)
        }
        
        do {
            let audioDataOutput = AVCaptureAudioDataOutput()
            let queue = DispatchQueue(label: "com.3DTOPO.audiosamplequeue")
            audioDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard (captureSession?.canAddOutput(audioDataOutput))! else {
                fatalError()
            }
            captureSession?.addOutput(audioDataOutput)
            
            audioConnection = audioDataOutput.connection(with: AVMediaType.audio)
        }
        
        captureSession?.commitConfiguration()
    }
    
    
    
    func startRecording(){
        if(!isRecording){
            print("start Recording")
            captureSession?.startRunning()
            isRecording = true
            
            self.recordWithTimer()
            
//            let backgroundDispatch:DispatchQueue =  DispatchQueue.global(qos: .userInitiated)
//
//            backgroundDispatch.async {
//                // Download file or perform expensive task
//                self.recordView(backgroundDispatch: backgroundDispatch)
//
//                DispatchQueue.main.async {
//                    // Update the UI
//
//                }
//            }
        }
    }
    
    func stopRecording(){
        print("stop Recording")
        timer?.cancel()
        timer = nil
        isRecording = false
        if let list = assetWriter?.inputs {
            for i in 0 ..< list.count {
                assetWriter?.inputs[i].markAsFinished()
            }
            
            assetWriter?.finishWriting(completionHandler: {
                NSLog("recording Video is created")
                print("recording ",self.assetWriter?.outputURL)
                self.drawView?.onRecordedLocal(result: ["uri":(self.assetWriter?.outputURL.absoluteString)!,  "path":(self.assetWriter?.outputURL.path)!])
                self.isRecording = false
            })
            captureSession?.stopRunning();
        }
        
        
        
        
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func setupWriters(){
        let filemgr = FileManager.default
        
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        
        let docsDir = dirPaths[0].path
        
        let fileUrl = URL(fileURLWithPath: docsDir+"/"+randomString(length: 5)+".mov")
        
        
        
        do{
            assetWriter = try AVAssetWriter(outputURL: fileUrl, fileType: AVFileType.mov)
        }catch{
            assetWriter = nil
        }
        
        // this will trigger capture on its own queue
        
        
        
        //        if #available(iOS 11.0, *){
        //            codec = AVVideoCodecType.h264
        //        }
        
        let videoSettings:[String:Any] = [
            //            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey:300000],
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoHeightKey: frame?.height,
            AVVideoWidthKey: frame?.width
        ]
        
        let audioSettings = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey : 2,
            AVSampleRateKey : 44100.0,
            AVEncoderBitRateKey: 192000
            ] as [String : Any]
        
        let assetWriterInput:AVAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        
        audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio,
                                              outputSettings: audioSettings)
        audioWriterInput!.expectsMediaDataInRealTime = true
        
        self.videoAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)
        
        assetWriter?.add(assetWriterInput)
        
        
        assetWriter?.add(audioWriterInput!)
    }
    
    func recordInArray(){
        setupWriters()
        
        
    }
    
    var timer: DispatchSourceTimer?
    func recordWithTimer(){
        setupWriters()
        
        assetWriter?.startWriting()
        //        assetWriter?.startSession(atSourceTime: CMTimeMake(value: 0, timescale: 60))
        assetWriter?.startSession(atSourceTime: CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 1000))
        
//        let queue = DispatchQueue(label: "com.firm.app.timer", attributes: .concurrent)
        let queue =  DispatchQueue.global(qos: .userInitiated)
        
        timer?.cancel()        // cancel previous timer if any
        
        timer = DispatchSource.makeTimerSource(queue: queue)
        
        timer?.schedule(deadline: .now(), repeating: 0.05, leeway: .milliseconds(0))
        
        
        timer?.setEventHandler { [weak self] in // `[weak self]` only needed if you reference `self` in this closure and you want to prevent strong reference cycle
//            print(CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 1000))
            // here we can get a frame on sync and then do async buffer creation and writing
            
            
            if(!(self?.videoAdaptor?.assetWriterInput.isReadyForMoreMediaData)! || !self!.isRecording){
                
            }
            else{
                DispatchQueue.main.sync {
                    let time = CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 1000);
                    
                    var imageBuffer:CVPixelBuffer?
                    //                print("before method call")
                    self!.getPixelBufferFromImage(imageBuffer:&imageBuffer, image: (self?.drawView?.getImage())!)
                    //            print(imageBuffer)
                    
                    queue.async {
                        do{
                            if(self!.assetWriter?.status == AVAssetWriter.Status.writing && self!.isRecording){
                                try self!.videoAdaptor!.append(imageBuffer as! CVPixelBuffer, withPresentationTime: time)
                                //                        i = i+1;
                            }
                        }
                        catch{
                            
                        }
                    }
                    
                }
                
            }
            
        }
        
        timer?.resume()
    }
    
    func recordView(backgroundDispatch:DispatchQueue){
        setupWriters()
        
        assetWriter?.startWriting()
        //        assetWriter?.startSession(atSourceTime: CMTimeMake(value: 0, timescale: 60))
        assetWriter?.startSession(atSourceTime: CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 1000))
        
        var i:Int = 0
        let fps: Int32 = 60
        let frameDuration = CMTimeMake(value:0, timescale: fps)
        let firstTimeStamp = CACurrentMediaTime()
        
        
        while(isRecording){
            if(!self.videoAdaptor!.assetWriterInput.isReadyForMoreMediaData){
                //                print("not ready for data")
            }
            else{
                let scale = CMTimeScale(NSEC_PER_SEC)
                let lastFrameTime = CMTimeMake(value: Int64(i), timescale: fps)
                let frameTime:CMTime = CMTimeMake(value: Int64(i), timescale: fps)
                let presentationTime = Int64(i) == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                
                
                var elapsed = (CACurrentMediaTime() - firstTimeStamp);
                var time = CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 1000);
                
                var imageBuffer:CVPixelBuffer?
                //                print("before method call")
                self.newPixelBufferFromCGImage(imageBuffer:&imageBuffer)
                //            print(imageBuffer)
                
                do{
                    if(assetWriter?.status == AVAssetWriter.Status.writing && isRecording){
                        let appended = try self.videoAdaptor!.append(imageBuffer as! CVPixelBuffer, withPresentationTime: time)
                        i = i+1;
                    }
                }
                catch{
                    
                }
                //                print("appended ",appended, i)
                
                
            }
        }
        
    }
    
    
    func newPixelBufferFromCGImage(imageBuffer: UnsafeMutablePointer<CVPixelBuffer?>) {
        let options:NSDictionary =  [kCVPixelBufferCGImageCompatibilityKey : true,kCVPixelBufferCGBitmapContextCompatibilityKey: true]
        
        var pxbuffer:CVPixelBuffer?
        
        
        CVPixelBufferCreate(kCFAllocatorDefault, Int((frame?.width)!), Int((frame?.height)!), kCVPixelFormatType_32ARGB, options, imageBuffer)
        
        CVPixelBufferLockBaseAddress(imageBuffer.pointee as! CVPixelBuffer,[])
        
        let pxData =  CVPixelBufferGetBaseAddress(imageBuffer.pointee as! CVPixelBuffer)
        
        let rgbColorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        
        //        print("suspending")
        //        backgroundDispatch.suspend()
        
        //        DispatchQueue.main.async {
        
        // Update the UI
        let context:CGContext = CGContext(data: pxData, width: Int((frame?.width)!) , height: Int((frame?.height)!), bitsPerComponent: 8, bytesPerRow: Int(frame!.width*4), space:CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        
        
        context.draw((self.imageView?.getImage())!, in: CGRect(x: 0, y: 0, width: Int((frame?.width)!), height: Int((frame?.height)!)))
        CVPixelBufferUnlockBaseAddress(imageBuffer.pointee!,[])
        //            backgroundDispatch.resume()
        //        print("resumed")
        //        }
        
        
        //        context.concatenate(frameTransform)
        //    return pxbuffer!;
    }
    
    func getPixelBufferFromImage(imageBuffer: UnsafeMutablePointer<CVPixelBuffer?>, image: CGImage){
        let options:NSDictionary =  [kCVPixelBufferCGImageCompatibilityKey : true,kCVPixelBufferCGBitmapContextCompatibilityKey: true]
        
        var pxbuffer:CVPixelBuffer?
        
        
        CVPixelBufferCreate(kCFAllocatorDefault, Int((frame?.width)!), Int((frame?.height)!), kCVPixelFormatType_32ARGB, options, imageBuffer)
        
        CVPixelBufferLockBaseAddress(imageBuffer.pointee as! CVPixelBuffer,[])
        
        let pxData =  CVPixelBufferGetBaseAddress(imageBuffer.pointee as! CVPixelBuffer)
        
        let rgbColorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        
        //        print("suspending")
        //        backgroundDispatch.suspend()
        
        //        DispatchQueue.main.async {
        
        // Update the UI
        let context:CGContext = CGContext(data: pxData, width: Int((frame?.width)!) , height: Int((frame?.height)!), bitsPerComponent: 8, bytesPerRow: Int(frame!.width*4), space:CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: Int((frame?.width)!), height: Int((frame?.height)!)))
        CVPixelBufferUnlockBaseAddress(imageBuffer.pointee!,[])
    }
    
}
