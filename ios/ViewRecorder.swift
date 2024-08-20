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

@objc public protocol ViewRecorderDelegate: NSObjectProtocol  {
    func onRecordedLocal(_ view: ViewRecorder, result:Dictionary<String, Any>)
    func storeVideoURL(_ view: ViewRecorder, result: Dictionary<String, Any>, completion: @escaping () -> Void)
    func getImage(_ view: ViewRecorder, context:CGContext)
}



public class ViewRecorder:NSObject, AVCaptureAudioDataOutputSampleBufferDelegate{

    var isRecording:Bool = false;
    var image:UIImage?
    var frame:CGRect?

    var captureSession:AVCaptureSession?
    var audioConnection:AVCaptureConnection?

    var adapter:AVAssetWriterInputPixelBufferAdaptor?

    var assetWriter:AVAssetWriter?

    var audioWriterInput:AVAssetWriterInput?
    var videoWriterInput:AVAssetWriterInput?

    var setupDone:Bool?
    
    var delegate:ViewRecorderDelegate?


    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {


        if(connection == audioConnection && audioWriterInput != nil && (audioWriterInput?.isReadyForMoreMediaData)! && isRecording && assetWriter?.status == AVAssetWriter.Status.writing){
            do{
                var appended = try audioWriterInput!.append(sampleBuffer)
            }
            catch{

            }
        }

    }


    init(image: UIImage) {
        self.image = image
    }

    init(frame: CGRect) {
        super.init()
        self.frame = frame
    }



    /************************   Setup Start   **********************/
    private func setupMicSession(){
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

    private func setupAssetWriter(){
        let filemgr = FileManager.default

        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)

        let docsDir = dirPaths[0].path

        let fileUrl = URL(fileURLWithPath: docsDir+"/"+randomString(length: 5)+".mov")


        do{
            assetWriter = try AVAssetWriter(outputURL: fileUrl, fileType: AVFileType.mov)
        }catch{
            assetWriter = nil
        }
    }

    private func setupAudioInput(){
        let audioSettings = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey : 2,
            AVSampleRateKey : 44100.0,
            AVEncoderBitRateKey: 192000
            ] as [String : Any]

        audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio,
                                              outputSettings: audioSettings)
        audioWriterInput!.expectsMediaDataInRealTime = true
    }

    private func setupVideoInput(){
        let videoSettings:[String:Any] = [
            //            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey:300000],
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoHeightKey: frame?.height,
            AVVideoWidthKey: frame?.width
        ]

        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)



        adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput!, sourcePixelBufferAttributes: nil)
    }

    private func setupInputs(){
        setupAssetWriter()
        setupAudioInput()
        setupVideoInput()

        assetWriter?.add(videoWriterInput!)
        assetWriter?.add(audioWriterInput!)
    }



    public func setupRecorder(){
        self.setupMicSession()
        self.setupInputs()

        setupDone = true;
    }
    /************************   Setup end   **********************/




    private func startWritingSession(){
        assetWriter?.startWriting()
        let startingTimeDelay = CMTimeMakeWithSeconds(0, preferredTimescale: 1000)

        assetWriter?.startSession(atSourceTime: CMTimeAdd(CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 1000), startingTimeDelay))
        captureSession?.startRunning()
    }

    func startRecording(){
        if(!isRecording){
            print("start Recording")

            isRecording = true
            let backgroundDispatch:DispatchQueue =  DispatchQueue.global(qos: .userInitiated)

            backgroundDispatch.async {
                self.recordView(backgroundDispatch: backgroundDispatch)
            }
        }
    }

    func stopRecording(){
        print("stop Recording")
        isRecording = false
        if let list = assetWriter?.inputs {
            for i in 0 ..< list.count {
                do{
                    try ObjC.catchException{
                        self.assetWriter?.inputs[i].markAsFinished()
                    }
                }
                catch{
                    
                }
            }

            do{
                try ObjC.catchException{
                    self.assetWriter?.finishWriting(completionHandler: {
                        NSLog("recording Video is created")
                        print("recording ",self.assetWriter?.outputURL)
                        self.delegate?.onRecordedLocal(self, result: ["uri":(self.assetWriter?.outputURL.absoluteString)!,  "path":(self.assetWriter?.outputURL.path)!])
                        self.isRecording = false
                    })
                    self.captureSession?.stopRunning();
                }
            }
            catch{
                self.delegate?.onRecordedLocal(self, result: ["uri":(self.assetWriter?.outputURL.absoluteString)!,  "path":(self.assetWriter?.outputURL.path)!])
                self.isRecording = false
                captureSession?.stopRunning();
            }
        }
    }

    func createScreenRecording(completion: (() -> Void)? = nil){
        if let list = assetWriter?.inputs {
            for i in 0 ..< list.count {
                do{
                    try ObjC.catchException{
                        self.assetWriter?.inputs[i].markAsFinished()
                    }
                }
                catch{}
            }

            do{
                try ObjC.catchException{
                    self.assetWriter?.finishWriting(completionHandler: {
                        self.delegate?.storeVideoURL(self, result: ["uri":(self.assetWriter?.outputURL.absoluteString)!]) {
                            completion?()
                        }
                        self.isRecording = false
                    })
                    self.captureSession?.stopRunning();
                }
            }
            catch{
                self.delegate?.storeVideoURL(self, result: ["uri":(self.assetWriter?.outputURL.absoluteString)!]) {
                    completion?()
                }
                self.isRecording = false
                captureSession?.stopRunning();
            }
        }
    }


    func recordView(backgroundDispatch:DispatchQueue){
        if(!setupDone!){
            setupRecorder()
        }
        self.startWritingSession()
        var i:Int = 0

        while(isRecording){
            if(!adapter!.assetWriterInput.isReadyForMoreMediaData){
//                print("not ready for data")
            }
            else{
                let time = CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 1000);
                var imageBuffer:CVPixelBuffer?
                self.newPixelBufferFromCGImage(imageBuffer:&imageBuffer, backgroundDispatch: backgroundDispatch)

                do{
                    if(assetWriter?.status == AVAssetWriter.Status.writing && isRecording){
                        let appended = try adapter!.append(imageBuffer!, withPresentationTime: time)
                        i = i+1;
                    }
                }
                catch{
                }
            }
        }

    }



    /************************   Utils start   **********************/
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }

    func newPixelBufferFromCGImage(imageBuffer: UnsafeMutablePointer<CVPixelBuffer?>, backgroundDispatch:DispatchQueue) {
        let options:NSDictionary =  [kCVPixelBufferCGImageCompatibilityKey : true,kCVPixelBufferCGBitmapContextCompatibilityKey: true]

        CVPixelBufferCreate(kCFAllocatorDefault, Int((frame?.width)!), Int((frame?.height)!), kCVPixelFormatType_32ARGB, options, imageBuffer)


        CVPixelBufferLockBaseAddress(imageBuffer.pointee!,[])


        let pxData =  CVPixelBufferGetBaseAddress(imageBuffer.pointee!)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer.pointee!)
        let contextWidth = CVPixelBufferGetWidth(imageBuffer.pointee!)
        let contextHeight = CVPixelBufferGetHeight(imageBuffer.pointee!)


        let context:CGContext = CGContext(data: pxData, width: contextWidth, height: contextHeight, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space:CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: contextWidth, height: contextHeight))

        let transform:CGAffineTransform = __CGAffineTransformMake(1, 0, 0, -1, 0, frame!.height)

        context.concatenate(transform)


//        DispatchQueue.main.sync {
            // Update the UI
        autoreleasepool {
               self.delegate?.getImage(self, context: context);
            }
//        }

        CVPixelBufferUnlockBaseAddress(imageBuffer.pointee!,[])
    }
    /************************   Utils end   **********************/
}


        //        assetWriter?.startSession(atSourceTime: CMTimeMake(value: 0, timescale: 60))
//        context.draw(image!, in: CGRect(x: 0, y: 0, width: Int((frame?.width)!), height: Int((frame?.height)!)))

//        let fps: Int32 = 60
//        let frameDuration = CMTimeMake(value:0, timescale: fps)
//        let firstTimeStamp = CACurrentMediaTime()

//                let scale = CMTimeScale(NSEC_PER_SEC)
//                let lastFrameTime = CMTimeMake(value: Int64(i), timescale: fps)
//                let frameTime:CMTime = CMTimeMake(value: Int64(i), timescale: fps)
//                let presentationTime = Int64(i) == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
//                var elapsed = (CACurrentMediaTime() - firstTimeStamp);
