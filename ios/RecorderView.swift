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
class RecorderView: UIView, ViewRecorderDelegate {
    func onRecordedLocal(_ view: ViewRecorder, result: Dictionary<String, Any>) {
        self.onRecordedLocal(result: result);
    }
    
    func getImage(_ view: ViewRecorder, context: CGContext) {
        self.getImage(context: context)
    }
    
    
    @objc var onImageStored: RCTDirectEventBlock?
    @objc var onRecorded: RCTDirectEventBlock?
    @objc var onSetupDone: RCTDirectEventBlock?
    
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

    @objc func pauseRecording(){
        if(viewRecorder != nil){
            viewRecorder.pauseRecording()
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
