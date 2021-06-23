//
//  DrawingCanvas.swift
//  RNViewRecorder
//
//  Created by Toddle on 23/12/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation

class DrawingCanvas : UIView, MyLayerDelegate{
    
    public func getCanvas(_ view: MyLayer) -> Canvas {
        return self.canvas!;
    }
    
    class BrushWrapper{
        var brush:Brush?
    }
    
    var _bounds: CGRect?
    
    override var bounds: CGRect {
        didSet {
            // ...
//            if(_bounds != nil){
//                if(_bounds?.width != bounds.width && _bounds?.height != bounds.height && _bounds!.height > CGFloat(0) && bounds.height > CGFloat(0)){
//                    if(canvas != nil){
//                        let scale:CGFloat = self.bounds.height / self._bounds!.height;
////                        canvas?.scale = scale
////                        canvas?.redraw()
//                        print("bounds ####### ",scale)
//                    }
//                }
//            }
//             _bounds = bounds
//            print("bounds ####### ",self.bounds)
        }
    }
    
    override var frame: CGRect {
        didSet {
//            print("frame ####### ",self.frame)
        }
    }
    
    var _brushes:NSMutableDictionary = [:]
    
    var _colorString: String = "#000000"
    var _brushWidth: CGFloat = 10.0
    var _drawingTool: String = "pen"
    var _pointPaint: String = ""
    
    @objc var brushes:NSArray = []
    @objc var brushWidth: CGFloat {
        get{return self._brushWidth}
        set {
            self._brushWidth = newValue
//            self.selectDrawingTool(drawingTool: drawingTool)
            self.styleChanged()
            canvas?.currentBrush.pointSize = newValue
        }
    }
    @objc var colorString: String = "#000000" {
        didSet{
            self.styleChanged()
        }
    }
    @objc var colorAlpha: CGFloat = 1{
        didSet{
            self.styleChanged()
        }
    }
    @objc var opacity: CGFloat = 1 {
        didSet{
            self.styleChanged()
        }
    }
    @objc var forceOnTap: CGFloat = 0.5
    @objc var forceSensitive: CGFloat = 1
    @objc var pointStep: CGFloat = 0.5
    @objc var coreProportion: CGFloat = 0.2
    @objc var isErasing: Bool = false
    @objc var imageBackgroundUri: String = ""
    @objc var pointPath: String {
        get{return self._pointPaint}
        set{
            self._pointPaint = newValue
//            self.selectDrawingTool(drawingTool: drawingTool)
            self.styleChanged()
//            self.setupDrawingTool(drawingTool: drawingTool)
        }
    }
    @objc var drawingTool: String{
        get{return self._drawingTool}
        set {
            self._drawingTool = newValue
//            self.selectDrawingTool(drawingTool: newValue)
            self.styleChanged()
            
//            self.setupDrawingTool(drawingTool: newValue)
//            canvas?.currentBrush.pointSize = newValue
        }
    }

    @objc var onEventStackUpdated: RCTDirectEventBlock?
    @objc var onImageStored: RCTDirectEventBlock?
    @objc var onViewMount: RCTDirectEventBlock?
    
    var canvas:Canvas?
  
    
    func initCanvas(){
        if(self.canvas == nil){
            canvas = Canvas(frame: self.frame)
            canvas!.autoResizeDrawable = true
        }
    }
    
    override func layoutSubviews() {
        self.initCanvas()
        
        if(self.canvas != nil){
            canvas?.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
//            canvas?.setNeedsLayout()
//            print("##### transforming the data")
//            canvas?.data.transformData(renderIn: self.frame)
            canvas?.redraw()
//            canvas?.redraw()
        }
        
//        if(self isDescendantOfView:self.view)
        if(self.canvas != nil && !self.canvas!.isDescendant(of: self)){
//            print("##### transformData ", self.frame )
            
            canvas!.onEventOccured = {() in
                self.onEventOccured()
            }
            canvas!.isOpaque = false;
            canvas!.backgroundColor = .clear
            canvas!.alpha = 1
            canvas!.isUserInteractionEnabled = true
            
//            addSubview(canvasShadow!)
            addSubview(canvas!)
            
            let layer:MyLayer = self.layer as! MyLayer
            layer.myDelegate = self
        }
        
        
        
        do{
            try self.registerBrushes()
        }catch{
            
        }
        
        if(onViewMount != nil){
            DispatchQueue.main.async {
                self.onViewMount!(["doesPhysicalHomeExist": self.isPhysicalHomeExist()])
            }
        }
    }
    
    func setupDrawingTool(values:Dictionary<String, Any>)throws -> Brush?{
        let color = hexStringToUIColor(hex: colorString)
        let name:String = values["id"] as! String
        let opacity:CGFloat? = values["opacity"] as? CGFloat
        let pointStep:CGFloat? = values["pointStep"] as? CGFloat
        let forceOnTap:CGFloat? = values["forceOnTap"] as? CGFloat
        let forceSensitive:CGFloat? = values["forceSensitive"] as? CGFloat
        let pointPath:String? = values["pointPath"] as? String
        let coreProportion:CGFloat? = (values["coreProportion"] as? CGFloat)
        var tool:Brush?
        do{
            if(canvas != nil){
                let existingTool = canvas?.findBrushBy(name: name)
                if(name == "pen"){
                    let pen = canvas!.defaultBrush!
                    pen.name = name
                    pen.pointSize = self.brushWidth
                    pen.color = color
                    if(opacity != nil){
                        pen.opacity = opacity!
                    }
                    if(pointStep != nil){
                        pen.pointStep = pointStep!
                    }
                    if(forceOnTap != nil){
                        pen.forceOnTap = forceOnTap!
                    }
                    if(forceSensitive != nil){
                        pen.forceSensitive = forceSensitive!
                    }
                }
                else if(name == "eraser"){
                    let eraser = existingTool != nil ? existingTool : try! canvas!.registerBrush(name: name) as Eraser
                    eraser!.pointSize = self.brushWidth
                    tool = eraser
                }
                else if(name == "brush"){
                    let brush = existingTool != nil ? existingTool : try registerBrush(with: name, pointPath: pointPath)
                    brush!.rotation = .ahead
                    brush!.pointSize = self.brushWidth
                    if(pointStep != nil){
                        brush!.pointStep = pointStep!
                    }
                    if(forceSensitive != nil){
                        brush!.forceSensitive = forceSensitive!
                    }
                    if(opacity != nil){
                        brush!.opacity = opacity!
                    }
                    brush!.color = color
                    tool = brush
                }
                else if(name == "pencil"){
                    let brush = existingTool != nil ? existingTool : try registerBrush(with: name, pointPath: pointPath)
                    brush!.rotation = .random
                    brush!.pointSize = self.brushWidth
                    brush!.color = color
                    if(opacity != nil){
                        brush!.opacity = opacity!
                    }
                    if(forceSensitive != nil){
                        brush!.forceSensitive = forceSensitive!
                    }
                    if(pointStep != nil){
                        brush!.pointStep = pointStep!
                    }
                    tool = brush
                }
                else if(name == "glow"){
                    let brush = existingTool != nil ? existingTool : try registerGlowingBrush(with: name, pointPath: pointPath)
                    let brushTool:GlowingBrush = brush as! GlowingBrush
                    brushTool.rotation = .ahead
                    brushTool.pointSize = self.brushWidth
                    brush!.color = color
                    if(coreProportion != nil){
                        brushTool.coreProportion = coreProportion!
                    }
                    if(opacity != nil){
                        brushTool.opacity = opacity!
                    }
                    tool = brushTool
                }
                else{
                    let pen = existingTool != nil ? existingTool : try registerBrush(with: name, pointPath: pointPath)
                    if(pen != nil){
//                    pen.rotation = .ahead
                        pen!.name = name
                        if(opacity != nil){
                            pen!.opacity = opacity!
                        }
                        if(pointStep != nil){
                            pen!.pointStep = pointStep!
                        }
                        if(forceOnTap != nil){
                            pen!.forceOnTap = forceOnTap!
                        }
                        if(forceSensitive != nil){
                            pen!.forceSensitive = forceSensitive!
                        }
                        pen!.pointSize = self.brushWidth
                        
                        pen!.color = color
                        
                        
                        tool = pen
                    }
                }
            }
        }catch{
            
        }
        return tool
    }
    
    func selectDrawingTool(drawingTool:String){
        if(_brushes.count > 0){
            let brush = _brushes[drawingTool]
            if(brush != nil){
                (brush as! Brush).use()
            }
        }
    }
    
    func styleChanged(){
        if(_brushes.count > 0){
            self.setupDrawingTool(drawingTool: drawingTool)
        }
        
    }
    
    
    func setupDrawingTool(drawingTool:String){
        let color = hexStringToUIColor(hex: colorString)
        do{
            if(canvas != nil){
                var existingTool = canvas?.findBrushBy(name: drawingTool)
//                existingTool = nil
                if(drawingTool == "pen"){
                    let pen = canvas!.defaultBrush!
                    pen.name = drawingTool
                    pen.opacity = opacity
                    pen.pointSize = self.brushWidth
                    pen.pointStep = pointStep
                    pen.color = color
                    pen.forceOnTap = forceOnTap
                    pen.forceSensitive = forceSensitive
                    pen.use()
                }
                else if(drawingTool == "eraser"){
                    do{
                        let eraser = existingTool != nil ? existingTool : try! canvas!.registerBrush(name: drawingTool) as Eraser
                        eraser!.pointSize = self.brushWidth
                        eraser!.use()
                    }catch{
                        
                    }
                }
                else if(drawingTool == "brush"){
                    let brush = existingTool != nil ? existingTool : try registerBrush(with: drawingTool, pointPath: pointPath)
                    brush!.rotation = .ahead
                    brush!.pointSize = self.brushWidth
                    brush!.pointStep = pointStep
                    brush!.forceSensitive = forceSensitive
                    brush!.opacity = opacity
                    brush!.color = color
                    brush!.use()
                }
                else if(drawingTool == "pencil"){
                    let brush = existingTool != nil ? existingTool : try registerBrush(with: drawingTool, pointPath: pointPath)
                    brush!.rotation = .random
                    brush!.pointSize = self.brushWidth
                    brush!.pointStep = pointStep
                    brush!.forceSensitive = forceSensitive
                    brush!.color = color
                    brush!.opacity = opacity
                    brush!.use()
                }
                else if(drawingTool == "glow"){
                    let brush = existingTool != nil ? existingTool  : try registerGlowingBrush(with: drawingTool, pointPath: pointPath)
                    let brushTool:GlowingBrush = brush as! GlowingBrush
                    brushTool.rotation = .ahead
                    brushTool.pointSize = self.brushWidth
                    brushTool.coreProportion = coreProportion
                    brushTool.opacity = opacity
                    brushTool.color = color
                    brushTool.use()
                }
                else{
                    let pen = existingTool != nil ? existingTool : try registerBrush(with: drawingTool, pointPath: pointPath)
                    if(pen != nil){
//                    pen.rotation = .ahead
                        pen!.name = drawingTool
                        pen!.opacity = opacity
                        pen!.pointSize = self.brushWidth
                        pen!.pointStep = pointStep
                        pen!.color = color
                        pen!.forceOnTap = forceOnTap
                        pen!.forceSensitive = forceSensitive
                        pen!.use()
                    }
                }
            }
        }
        catch{
            
        }
    }
    
    func undo(){
        canvas?.undo()
        self.onEventOccured()
    }
    
    func clear(){
        canvas?.clear(display: false)
        self.onEventOccured()
    }
    
    func redo(){
        canvas?.redo()
        self.onEventOccured()
    }
    
    func onEventOccured(){
        if onEventStackUpdated != nil {
            DispatchQueue.main.async {
                self.onEventStackUpdated!(["canRedo": self.canRedo, "canUndo": self.canUndo])
            }
        }
    }
    
    /// Determines whether a last change can be undone
    @objc public var canUndo: Bool {
        return (self.canvas?.data.canUndo)!
    }
    
    /// Determines whether an undone change can be redone
    @objc public var canRedo: Bool {
        return (self.canvas?.data.canRedo)!
    }

    
    override open class var layerClass: AnyClass{
        
        return MyLayer.self;
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
                    
                    
                    canvas?.renderIn(context: context)
                    
    //                self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
                    
                    resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
                }
            }
            print("Time to get image  \(Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000) seconds")
            
            return resultImage
        }
    
    public func getImage(context:CGContext){
                let start = DispatchTime.now()
                
                
                UIGraphicsPushContext(context);
                
                
                // Fallback on earlier versions
                 self.layer.render(in: context)
    //        self.layer.presentation()?.render(in: context)
        //        self.layer.renderIn
                let scale = 50 / 100
                let newRect = self.bounds.applying(CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale)))
            //417, 563
//            self.snapshotView(afterScreenUpdates: false)?.layer.render(in: context)
    //        self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
            
                
                
                UIGraphicsPopContext();

                
            print("Time to get image  \(Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000) seconds ",self.bounds.width, self.bounds.height)
            }
    
    private func registerBrushes() throws {
        let start = DispatchTime.now()
        if(brushes.count > 0){
            for (index, brush) in brushes.enumerated() {
                // create the brush here
                do{
                    let values = brush as! Dictionary<String,Any>
                    let name = values["id"] as! String
                    var newBrush = try setupDrawingTool(values: values)
                    if(newBrush != nil){
                        _brushes.setValue(newBrush, forKey: name)
                    }
                } catch{
                    
                }
            }
        }
        print("Time to register brush  \(Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000) seconds")
    }
    
    private func registerBrush(with imageName: String, pointPath: String?) throws -> Brush {
        if(pointPath == nil || pointPath == ""){
            let existingTool = canvas?.findBrushBy(name: imageName)
            return existingTool != nil ? existingTool! : try canvas!.registerBrush(name: imageName)
        }
//        let texture = try self.canvas?.makeTexture(with: UIImage(named: imageName)!.pngData()!)
//        UIImage(data: Data(contentsOf: URL(string: pointPath)!))
        var data:Data?
        DispatchQueue.global(qos: .background).sync {
            let url = URL(string: pointPath!)
            data = try! Data.init(contentsOf: url!)
        }
        
        let texture = try self.canvas?.makeTexture(with: (UIImage(data: data!)?.pngData())!)
//        let texture = try self.canvas?.makeTexture(with: UIImage(data: URL(string: pointPath)!)
        return try (canvas?.registerBrush(name: imageName, textureID: texture?.id))!
    }
    
    private func  registerGlowingBrush(with imageName: String, pointPath: String?) throws -> GlowingBrush{
        if(pointPath == nil || pointPath == ""){
            let existingTool = canvas?.findBrushBy(name: imageName)
            if(existingTool != nil){
                return existingTool! as! GlowingBrush;
            }
            else{
                return try canvas!.registerBrush(name: imageName);
            }
        }
        
        var data:Data?
        DispatchQueue.global(qos: .background).sync {
            let url = URL(string: pointPath!)
            data = try! Data.init(contentsOf: url!)
        }
        let texture = try self.canvas?.makeTexture(with: (UIImage(data: data!)?.pngData())!)
        
        return try (canvas?.registerBrush(name: imageName, textureID: texture?.id))!
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
//        print("colorAlpha ",colorAlpha, CGFloat(colorAlpha))
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(colorAlpha)
        )
    }
    
    func isPhysicalHomeExist() -> Bool {
        if #available(iOS 11.0, *), let keyWindow = UIApplication.shared.keyWindow, keyWindow.safeAreaInsets.bottom > 0 { return true }; return false
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
