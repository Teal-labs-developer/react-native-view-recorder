//
//  RecorderView.swift
//  RNViewRecorder
//
//  Created by Toddle on 13/12/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

import UIKit
import Photos
import MetalKit
import Foundation
import AVKit

class RecorderView: UIView, ViewRecorderDelegate {
    func onRecordedLocal(_ view: ViewRecorder, result: Dictionary<String, Any>) {
        self.onRecordedLocal(result: result);
    }
    
    func storeVideoURL(_ view: ViewRecorder, result: Dictionary<String, Any>, completion: @escaping () -> Void) {
        self.storeVideoURL(result: result)
        completion()
    }
    
    func getImage(_ view: ViewRecorder, context: CGContext) {
        self.getImage(context: context)
    }
    
    
    @objc var onImageStored: RCTDirectEventBlock?
    @objc var onRecorded: RCTDirectEventBlock?
    @objc var onSetupDone: RCTDirectEventBlock?
    var isRecordingPaused: Bool = false
    var videoURIs: [URL?] = []
    
    @objc var backgroundType: String = ""{
        didSet{
            setNeedsDisplay()
        }
    }
    @objc var backgroundColorString: String = "#dbdbdb"
    
    let space = 48
    
    let utils:DrawUtils = DrawUtils()
        
    let tan30 = tan(30.0*(M_PI / 180))
    
    var viewRecorder: ViewRecorder!
    
    @objc var imageBackgroundUri: String = ""
    
    @objc func setupRecorder(){
        viewRecorder = ViewRecorder(frame: frame)
        viewRecorder.delegate = self
        viewRecorder.setupRecorder()
        
        if onSetupDone != nil {
            DispatchQueue.main.async {
                self.onSetupDone!(["error":""])
            }
        }
    }
    
    @objc func startRecording(){
        if(viewRecorder != nil) {
            viewRecorder.startRecording()
        }
    }
    
    @objc func stopRecording(){
        if(viewRecorder != nil){
            viewRecorder.stopRecording()
        }
    }
    
    public func resetVariables() {
        videoURIs = []
        isRecordingPaused = false
    }
    
    /** Merge all the videos that were recorded */
    @objc func stopRecordingV2() {
        if (videoURIs.count == 0) {
            stopRecording()
            resetVariables()
            return
        }
        
        if (viewRecorder != nil && !isRecordingPaused) {
            viewRecorder.createScreenRecording() {
                self.isRecordingPaused = true
                self.stopRecordingV2()
            }
            return;
        }
        
        if (videoURIs.count == 1 && self.onRecorded != nil) {
            let uri = videoURIs[0]
            if let uri = uri {
                DispatchQueue.main.async {
                    self.onRecorded!(["uri": String(describing: uri), "width": self.frame.width, "height": self.frame.height])
                }
            }
            resetVariables()
            return
        }

        let composition = AVMutableComposition()
        let nonOptionalURLs = videoURIs.compactMap { $0 }
        composition.mergeVideo(nonOptionalURLs) { (url, error) in
            if let url = url {
                if self.onRecorded != nil {
                    DispatchQueue.main.async {
                        self.onRecorded!(["uri": String(describing: url), "width": self.frame.width, "height": self.frame.height])
                    }
                }
            } else {
                print("Error: \(String(describing:  error))")
            }
        }
        resetVariables()
    }
    
    public func storeVideoURL(result:Dictionary<String, Any>){
        let uri = result["uri"]
        if let fileUri = uri {
            let videoUrl = URL(string: String(describing: fileUri))
            videoURIs.append(videoUrl)
        }
    }

    @objc func pauseRecording(){
        if(viewRecorder != nil) {
            if (isRecordingPaused) {
                viewRecorder = ViewRecorder(frame: frame)
                viewRecorder.delegate = self
                viewRecorder.setupRecorder()
                
                if onSetupDone != nil {
                    DispatchQueue.main.async {
                        self.onSetupDone!(["error":""])
                    }
                }
                isRecordingPaused = false
            } else {
                viewRecorder.createScreenRecording()
                isRecordingPaused = true
            }
        }
   }
    
    public func onRecordedLocal(result:Dictionary<String, Any>){
        print("onRecordedLocal ",result)
        if onRecorded != nil {
            print("onRecordedLocal ",result)
            DispatchQueue.main.async {
                self.onRecorded!(["uri":self.viewRecorder.assetWriter?.outputURL.absoluteString,  "path":self.viewRecorder.assetWriter?.outputURL.path, "width": self.frame.width, "height": self.frame.height])
            }
        }
    }
    
    func getColor()->CGColor{
        return utils.hexStringToUIColor(hex: backgroundColorString).cgColor;
    }
    
    
    
    
    override func layoutSubviews() {
    //            print("run when UIView appears on screen ",brushWidth,hexStringToUIColor(hex: colorString))
        //        color = hexStringToUIColor(hex: colorString)
                // you can update your label's text or etc.
                
                
                
                
                let rect = CGRect(origin: .zero, size: frame.size)
                UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
    //            UIColor.white.setFill()
    //            UIRectFill(rect)
                var imageLocal = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                
            
                
    //            mainImageView.contentMode = UIView.ContentMode.scaleAspectFit
                
                if(imageBackgroundUri != nil){
                    print("imageBackgroundUri ",imageBackgroundUri)
                    if(imageBackgroundUri.contains("://")){
                        if(imageBackgroundUri.contains("assets-library://")){
                            let assetUrl = URL(string: imageBackgroundUri)!
                            
                            // retrieve the list of matching results for your asset url
                            let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [assetUrl], options: nil)
                            
                            
                            if let photo = fetchResult.firstObject {
                                
                                // retrieve the image for the first result
                                PHImageManager.default().requestImage(for: photo, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil) {
                                    image, info in
                                    
                                    imageLocal = image
                                }
                            }
                            
                        }
                        else{
                            do {
                                imageLocal = try UIImage(data: Data(contentsOf: URL(string: imageBackgroundUri)!))
                                
                            }
                            catch {
                                fatalError("Could not create UIImage from data error: \(error).")
                            }
                        }
                        
                    }
                    else{
                        imageLocal =  UIImage(contentsOfFile: imageBackgroundUri)
                    }
                    
                }
                
                
        //        mainImageView.alpha = 0
                
                
    //            self.backgroundColor = .white

            if(imageLocal != nil){
//                let myLayer = CALayer()
//                let myImage = imageLocal?.cgImage
//                myLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
//                myLayer.contents = myImage
//                self.layer.addSublayer(myLayer)
                setNeedsDisplay()
            }
        }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        if(backgroundType == "dots"){
            self.drawDots(in: context!)
        }
        else if(backgroundType == "math"){
            self.drawVerticalLines(in: context!)
            self.drawHorizontalLines(in: context!)
        }
        else if(backgroundType == "lines"){
            self.drawHorizontalLines(in: context!)
        }
        else if(backgroundType == "orthogonal"){
            self.drawDiagnalRightLines(in: context!)
            self.drawDiagonalLeftLines(in: context!)
        }
    }
    
    @objc func saveAsImage(){
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Download file or perform expensive task
            
            let image:UIImage = self.getImage();
            
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            if let filePath = paths.first?.appendingPathComponent(self.randomString(length: 5)+".png") {
                // Save image.
                do {
                    try image.jpegData(compressionQuality: 1.0)?.write(to: filePath, options: .atomic)
                    DispatchQueue.main.sync {
                        // Update the UI
                        
                        if self.onImageStored != nil {
                            DispatchQueue.main.async {
                                self.onImageStored!(["uri":filePath.absoluteString,  "path":filePath.path, "width": self.frame.width, "height": self.frame.height])
                            }
                        }
                    }
                } catch {
                    // Handle the error
                }
            }
            
            
        }
        
    }
    
    public func getImage(context:CGContext){
            let start = DispatchTime.now()
            
            
            UIGraphicsPushContext(context);
            
            
            // Fallback on earlier versions
            //  self.layer.render(in: context)
//        self.layer.presentation()?.render(in: context)
    //        self.layer.renderIn
            let scale = 50 / 100
            // let newRect = self.bounds.applying(CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale)))
           self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
            
            
            
            UIGraphicsPopContext();

            
//            print("Time to get image  \(Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000) seconds")
        }
    
    func bytes() -> UnsafeMutableRawPointer {
        let width = self.bounds.width
        let height   = self.bounds.height
        let rowBytes = self.bounds.width * 4
        let p = malloc(Int(width * height * 4))

//        self.getBytes(p!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)

        return p!
    }
    
    func toImage() -> CGImage? {
        let p = bytes()

        let pColorSpace = CGColorSpaceCreateDeviceRGB()

        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)

        let selftureSize = self.bounds.width * self.bounds.height * 4
        let rowBytes = self.bounds.width * 4
        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            return
        }
        let provider = CGDataProvider(dataInfo: nil, data: p, size: Int(selftureSize), releaseData: releaseMaskImagePixelData)
        let cgImageRef = CGImage(width: Int(self.bounds.width), height: Int(self.bounds.height), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: Int(rowBytes), space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!
        
        

        return cgImageRef
    }
    
    public func getImage() -> UIImage{
            let start = DispatchTime.now()
            var resultImage:UIImage = UIImage()
            
            if #available(iOS 10.0, *), false {
                let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
                
                resultImage = renderer.image { ctx in
                    self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
                }
                
                
            } else {
                
                // Fallback on earlier versions
                UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
                defer { UIGraphicsEndImageContext() }
                if let context = UIGraphicsGetCurrentContext() {
                    context.setFillColor(UIColor.white.cgColor)
                    context.fill(CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
//                    self.layer.render(in: context)
                    self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
                    
                    resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
                }
            }
            print("Time to get image  \(Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000) seconds")
            
            return resultImage
        }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    
    func drawHorizontalLines(in context: CGContext){
            var startY = space / 2;
            
            var width = Int(self.bounds.width)
            var height = Int(self.bounds.height)
            
            while(startY < height){
                context.setLineWidth(1)
                context.setStrokeColor(self.getColor())
                context.move(to: CGPoint(x: 0, y: startY))
                context.addLine(to: CGPoint(x: width, y: startY))
                context.strokePath()
                
                startY = startY + space
            }
        }
        
        func drawVerticalLines(in context: CGContext){
            var startX = space / 2;
            
            var width = Int(self.bounds.width)
            var height = Int(self.bounds.height)
            
            while(startX < width){
                context.setLineWidth(1)
                context.setStrokeColor(self.getColor())
                context.move(to: CGPoint(x: startX, y: 0))
                context.addLine(to: CGPoint(x: startX, y: height))
                context.strokePath()
                
                startX = startX + space
            }
        }
        
        func drawDots(in context: CGContext){
            var startX = 0
            var startY = 0
            
            let width = Int(self.bounds.width)
            let height = Int(self.bounds.height)
            
            let size = CGSize(width: 2, height: 2)
            
            while(startY < height){
                startX = space / 2
                while(startX < width){
                    context.setStrokeColor(self.getColor())
                    let path = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: startX-1, y: startY-1), size: size))
                    utils.hexStringToUIColor(hex: backgroundColorString).setFill()
                    path.fill()
                    context.addPath(path.cgPath)
                    context.strokePath()
                    startX = startX + space
                }
                startY = startY + space
            }
        }
        
        func drawDiagnalRightLines(in context: CGContext){
            var startX = Double(space) / tan30
            var startY = Double(space)

            let width = Double(self.bounds.width)
            let height = Double(self.bounds.height)
            
            let xSegment = Double(space) / tan30
            let ySegment = Double(space)
            
            let numberOfLines = width / xSegment + height / ySegment
            
            var i = 0.0
            
            while(i < numberOfLines){
                context.setLineWidth(1)
                context.setStrokeColor(self.getColor())
                context.move(to: CGPoint(x: 0, y: startY))
                context.addLine(to: CGPoint(x: startX, y: 0))
                context.strokePath()
                
                startX = startX + Double(space) / tan30
                startY = startY + Double(space)
                i = i + 1
            }
            
            startX = (Double(space) / tan30)/2
            while(startX < width){
                context.setLineWidth(1)
                context.setStrokeColor(self.getColor())
                context.move(to: CGPoint(x: startX, y: 0))
                context.addLine(to: CGPoint(x: startX, y: height))
                context.strokePath()
                
                startX = startX + (Double(space) / tan30)/2
            }
            
        }
        
        func drawDiagonalLeftLines(in context: CGContext){
            let width = Double(self.bounds.width)
            let height = Double(self.bounds.height)
            
            var i = 0.0
            
            let xSegment = Double(space) / tan30
            let ySegment = Double(space)
            
            let numberOfLines = width / xSegment + height / ySegment
            
            let tempStartY = height.remainder(dividingBy: ySegment)
            
            var startX =  (tempStartY / tan30)
            var startY = height - tempStartY
            while(i < numberOfLines){
                context.setLineWidth(1)
                context.setStrokeColor(self.getColor())
                context.move(to: CGPoint(x: 0, y: startY))
                context.addLine(to: CGPoint(x: startX, y: height))
                context.strokePath()
                
                startX = startX + Double(space) / tan30
                startY = startY - Double(space)
                i = i + 1
            }
        }
}

// Reference: https://medium.com/goodrequest/merge-multiple-videos-with-correct-orientations-on-ios-in-swift-e24548037279
extension AVMutableComposition {
    
    public func mergeVideo(_ urls: [URL], completion: @escaping (_ url: URL?, _ error: Error?) -> Void) {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            completion(nil, nil)
            return
        }
        
        let outputURL = documentDirectory.appendingPathComponent("mergedVideo_\(AVMutableComposition.randomString(length: 5)).mp4")
        
        // If there is only one video, we dont to touch it to save export time.
        if let url = urls.first, urls.count == 1 {
            do {
                try FileManager().copyItem(at: url, to: outputURL)
                completion(outputURL, nil)
            } catch let error {
                completion(nil, error)
            }
            return
        }
        
        /** Video frame's width looks a little cropped from the right, so adding a 20 pixel offset */
        let maxRenderSize = CGSize(width: UIScreen.main.bounds.width + 20, height: UIScreen.main.bounds.height)
        var currentTime = CMTime.zero
        var renderSize = CGSize.zero
        // Create empty Layer Instructions, that we will be passing to Video Composition and finally to Exporter.
        var instructions = [AVMutableVideoCompositionInstruction]()

        urls.enumerated().forEach { index, url in
            let asset = AVAsset(url: url)
            let assetTrack = asset.tracks.first!
            
            // Create instruction for a video and append it to array.
            let instruction = AVMutableComposition.instruction(assetTrack, asset: asset, time: currentTime, duration: assetTrack.timeRange.duration, maxRenderSize: maxRenderSize)
            instructions.append(instruction.videoCompositionInstruction)
            
            // Set render size (orientation) according first video.
            if index == 0 {
                renderSize = CGSize(width: maxRenderSize.width, height: maxRenderSize.height)
            }
            
            do {
                let timeRange = CMTimeRangeMake(start: .zero, duration: assetTrack.timeRange.duration)
                // Insert video to Mutable Composition at right time.
                try insertTimeRange(timeRange, of: asset, at: currentTime)
                currentTime = CMTimeAdd(currentTime, assetTrack.timeRange.duration)
            } catch let error {
                completion(nil, error)
            }
        }
        
        // Create Video Composition and pass Layer Instructions to it.
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = instructions
        // Do not forget to set frame duration and render size. It will crash if you dont.
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = renderSize
        
        guard let exporter = AVAssetExportSession(asset: self, presetName: AVAssetExportPreset1280x720) else {
            completion(nil, nil)
            return
        }
        exporter.outputURL = outputURL
        exporter.outputFileType = .mp4
        // Pass Video Composition to the Exporter.
        exporter.videoComposition = videoComposition
        
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                completion(exporter.outputURL, nil)
            }
        }
    }
    
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    static func instruction(_ assetTrack: AVAssetTrack, asset: AVAsset, time: CMTime, duration: CMTime, maxRenderSize: CGSize)
        -> (videoCompositionInstruction: AVMutableVideoCompositionInstruction, isPortrait: Bool) {
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)

            // Find out orientation from preffered transform.
            let assetInfo = orientationFromTransform(assetTrack.preferredTransform)
            
            // Calculate scale ratio according orientation.
            var scaleRatio = maxRenderSize.width / assetTrack.naturalSize.width
            if assetInfo.isPortrait {
                scaleRatio = maxRenderSize.height / assetTrack.naturalSize.height
            }
            
            // Set correct transform.
            var transform = CGAffineTransform(scaleX: scaleRatio, y: scaleRatio)
            transform = assetTrack.preferredTransform.concatenating(transform)
            layerInstruction.setTransform(transform, at: .zero)
            
            // Create Composition Instruction and pass Layer Instruction to it.
            let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
            videoCompositionInstruction.timeRange = CMTimeRangeMake(start: time, duration: duration)
            videoCompositionInstruction.layerInstructions = [layerInstruction]
            
            return (videoCompositionInstruction, assetInfo.isPortrait)
    }
    
    static func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = true
        
        switch [transform.a, transform.b, transform.c, transform.d] {
        case [0.0, 1.0, -1.0, 0.0]:
            assetOrientation = .right
            isPortrait = true
            
        case [0.0, -1.0, 1.0, 0.0]:
            assetOrientation = .left
            isPortrait = true
            
        case [1.0, 0.0, 0.0, 1.0]:
            assetOrientation = .up
            
        case [-1.0, 0.0, 0.0, -1.0]:
            assetOrientation = .down

        default:
            break
        }
    
        return (assetOrientation, isPortrait)
    }
    
}
