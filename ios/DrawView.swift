import UIKit
import Photos

public enum SketchToolType {
    case pen
    case eraser
    case stamp
    case line
    case arrow
    case rectangleStroke
    case rectangleFill
    case ellipseStroke
    case ellipseFill
    case star
    case fill
}

public enum ImageRenderingMode {
    case scale
    case original
}


class DrawView: UIView {
    
    
    public var lineColor = UIColor.black
    public var lineWidth = CGFloat(10)
    public var lineAlpha = CGFloat(1)
    public var stampImage: UIImage?
    public var drawTool: SketchToolType = .pen
    public var drawingPenType: PenType = .normal
    private var currentTool: SketchTool?
    private let pathArray: NSMutableArray = NSMutableArray()
    private let bufferArray: NSMutableArray = NSMutableArray()
    private var currentPoint: CGPoint?
    private var previousPoint1: CGPoint?
    private var previousPoint2: CGPoint?
    private var image: UIImage?
    private var backgroundImage: UIImage?
    private var drawMode: ImageRenderingMode = .scale
    
    
    @objc var brushWidth: CGFloat = 10.0
    @objc var colorString: String =  "#000000"
    @objc var isErasing: Bool = false
    @objc var imageBackgroundUri: String = ""
    @objc var drawingTool: String = "pen"
    @objc var opacity: CGFloat = 1
    @objc var forceOnTap: CGFloat = 0.5
    @objc var forceSensitive: CGFloat = 1
    @objc var pointStep: CGFloat = 0.5

    @objc var onEventStackUpdated: RCTDirectEventBlock?
    @objc var onImageStored: RCTDirectEventBlock?
    
    var enableForceTouch = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareForInitial()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        prepareForInitial()
    }
    

    private func prepareForInitial() {
        backgroundColor = UIColor.clear
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
//            self.backgroundColor = UIColor(patternImage: imageLocal!)
//            self.loadImage(image: imageLocal!)
            setNeedsDisplay()
        }
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        switch drawMode {
        case .original:
            image?.draw(at: CGPoint.zero)
            break
        case .scale:
            image?.draw(in: self.bounds)
            break
        }

        currentTool?.draw()
    }
    
    private func updateCacheImage(_ isUpdate: Bool) {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)

        if isUpdate {
            image = nil
//            switch drawMode {
//            case .original:
//                if let backgroundImage = backgroundImage  {
//                    (backgroundImage.copy() as! UIImage).draw(at: CGPoint.zero)
//                }
//                break
//            case .scale:
//                (backgroundImage?.copy() as! UIImage).draw(in: self.bounds)
//                break
//            }

            for obj in pathArray {
                if let tool = obj as? SketchTool {
                    tool.draw()
                }
            }
        } else {
            switch drawMode {
            case .original:
                image?.draw(at: .zero)
              case .scale:
                image?.draw(in: self.bounds)
            }
            currentTool?.draw()
        }

        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    private func toolWithCurrentSettings() -> SketchTool? {
        switch drawingTool {
        case "pen":
            return PenTool()
        case "eraser":
            return EraserTool()
        case "stamp":
            return StampTool()
        case "line":
            return LineTool()
        case "arrow":
            return ArrowTool()
        case "rectangleStroke":
            let rectTool = RectTool()
            rectTool.isFill = false
            return rectTool
        case "rectangleFill":
            let rectTool = RectTool()
            rectTool.isFill = true
            return rectTool
        case "ellipseStroke":
            let ellipseTool = EllipseTool()
            ellipseTool.isFill = false
            return ellipseTool
        case "ellipseFill":
            let ellipseTool = EllipseTool()
            ellipseTool.isFill = true
            return ellipseTool
        case "star":
            return StarTool()
        case "fill":
            return FillTool()
        default:
            return PenTool()
        }
    }
    
    func setCurrentTool(touch:UITouch, type: String, withForce: Bool = false){
//        touch.type
        if(type == "begin"){
            if currentTool != nil {
                finishDrawing()
            }
        }
        
        currentTool = toolWithCurrentSettings()
        if (withForce) {
            if #available(iOS 9.0, *){
                currentTool?.lineWidth = brushWidth + (touch.force * brushWidth)
            }
            else{
                currentTool?.lineWidth = brushWidth
            }
        } else {
            // Fallback on earlier versions
            currentTool?.lineWidth = brushWidth
        }
        
        currentTool?.lineColor = hexStringToUIColor(hex: colorString)
        currentTool?.lineAlpha = lineAlpha
        
        switch currentTool! {
        case is PenTool:
            guard let penTool = currentTool as? PenTool else { return }
            pathArray.add(penTool)
            penTool.drawingPenType = drawingPenType
            penTool.setInitialPoint(currentPoint!)
        case is StampTool:
            guard let stampTool = currentTool as? StampTool else { return }
            pathArray.add(stampTool)
            stampTool.setStampImage(image: stampImage)
            stampTool.setInitialPoint(currentPoint!)
        default:
            guard let currentTool = currentTool else { return }
            pathArray.add(currentTool)
            currentTool.setInitialPoint(currentPoint!)
        }
    }
    
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        

        previousPoint1 = touch.previousLocation(in: self)
        currentPoint = touch.location(in: self)
        
        self.setCurrentTool(touch: touch, type: "begin", withForce: enableForceTouch)
        
        
        
        onEventOccured()
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        previousPoint2 = previousPoint1
        previousPoint1 = touch.previousLocation(in: self)
        currentPoint = touch.location(in: self)
        
        if(enableForceTouch){
            self.setCurrentTool(touch: touch, type: "move", withForce: enableForceTouch)
        }

        if let penTool = currentTool as? PenTool {
            let renderingBox = penTool.createBezierRenderingBox(previousPoint2!, widhPreviousPoint: previousPoint1!, withCurrentPoint: currentPoint!)

            setNeedsDisplay(renderingBox)
        } else {
            currentTool?.moveFromPoint(previousPoint1!, toPoint: currentPoint!)
            setNeedsDisplay()
        }
        
        if enableForceTouch{
            finishDrawing()
            currentTool = nil
        }

        onEventOccured()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
        finishDrawing()
        onEventOccured()
    }
    
    fileprivate func finishDrawing() {
        updateCacheImage(false)
        bufferArray.removeAllObjects()
        currentTool = nil
    }
    
    public func loadImage(image: UIImage, drawMode: ImageRenderingMode = .original) {
        self.image = image
        self.drawMode = drawMode
        backgroundImage =  image.copy() as? UIImage
        bufferArray.removeAllObjects()
        pathArray.removeAllObjects()
        updateCacheImage(true)

        setNeedsDisplay()
    }
    
    private func resetTool() {
        currentTool = nil
    }
    
    public func undo() {
        if canUndo {
            guard let tool = pathArray.lastObject as? SketchTool else { return }
            resetTool()
            bufferArray.add(tool)
            pathArray.removeLastObject()
            updateCacheImage(true)

            setNeedsDisplay()
            onEventOccured()
        }
    }

    public func redo() {
        if canRedo {
            guard let tool = bufferArray.lastObject as? SketchTool else { return }
            resetTool()
            pathArray.add(tool)
            bufferArray.removeLastObject()
            updateCacheImage(true)

            setNeedsDisplay()
            onEventOccured()
        }
    }
    
    public func clear() {
        resetTool()
        bufferArray.removeAllObjects()
        pathArray.removeAllObjects()
        updateCacheImage(true)

        setNeedsDisplay()
    }
    
    @objc func resetCanvas(){
        self.clear()
        onEventOccured()
    }
    
    /// Determines whether a last change can be undone
    @objc public var canUndo: Bool {
        return pathArray.count > 0
    }
    
    /// Determines whether an undone change can be redone
    @objc public var canRedo: Bool {
        return bufferArray.count > 0
    }
    
    func onEventOccured(){
        if onEventStackUpdated != nil {
            DispatchQueue.main.async {
                self.onEventStackUpdated!(["canRedo": self.canRedo, "canUndo": self.canUndo])
            }
        }
    }

    
    
    /****************************** Util functions start ********************************/
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
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
               alpha: CGFloat(1.0)
           )
       }
    /****************************** Util functions end ********************************/
    
}
