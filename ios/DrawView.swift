import UIKit
import Photos

class DrawView: UIView {
    
    public var isEnabled = true
    
    public var brush: Brush = .default {
        didSet{
            previousBrush = oldValue
        }
    }
    
    private var previousBrush: Brush = .default
    
    
    
    public struct Line {
        public var path: CGMutablePath
        public var brush: Brush
        public var isErasing: Bool = false
        public var drewFrame: CGRect?
        
        init(path: CGMutablePath, brush: Brush) {
            self.path = path
            self.brush = brush
        }
        
        init(path: CGMutablePath, brush: Brush, drewFrame: CGRect){
            self.path = path
            self.brush = brush
            self.drewFrame = drewFrame;
        }
    }
    
    public var lines: [Line] = []
    public var drawingHistory: [Line] = []
    private var currentPoint: CGPoint = .zero
    private var previousPoint: CGPoint = .zero
    private var previousPreviousPoint: CGPoint = .zero
    
    var drawColor = UIColor.black
    var lineWidth: CGFloat = 5
    
    //    private var lastPoint: CGPoint!
    private var bezierPath: UIBezierPath!
    private var pointCounter: Int = 0
    private let pointLimit: Int = 128
    public var preRenderImage: UIImage!
    
    public var tempImageView:UIImageView!
    public var mainImageView:UIImageView!
    
    var viewRecorder: ViewRecorder!
    
    
    
    var lastPoint = CGPoint.zero
    var color = UIColor.black
    
//    var tempColor = hexStringToUIColor("#ff0000")
    
    @objc var brushWidth: CGFloat = 10.0
    @objc var colorString: String =  "#000000"
    @objc var isErasing: Bool = false
    @objc var imageBackgroundUri: String = ""
    var opacity: CGFloat = 1.0
    var swiped = false
    
    
    
    
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
    
    @objc func demoStartRecord(value: NSNumber) {
        print("demoStartRecord")
        
        
    }
    
    @objc func setupRecorder(){
        viewRecorder = ViewRecorder(frame: frame, drawView: self)
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
    
    @objc func resetCanvas(){
        lines = []
        drawingHistory = []
        self.setNeedsDisplay()
        onEventOccured()
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
    
    public func onRecordedLocal(result:Dictionary<String, Any>){
        if onRecorded != nil {
            print("onRecordedLocal ",result)
            DispatchQueue.main.async {
                self.onRecorded!(["uri":self.viewRecorder.assetWriter?.outputURL.absoluteString,  "path":self.viewRecorder.assetWriter?.outputURL.path, "width": self.frame.width, "height": self.frame.height])
            }
        }
    }
    
    
    @objc var onRecorded: RCTDirectEventBlock?
    
    @objc var onEventStackUpdated: RCTDirectEventBlock?
    
    @objc var onSetupDone: RCTDirectEventBlock?
    
    @objc var onImageStored: RCTDirectEventBlock?
    
    
    
    
    
    override func layoutSubviews() {
        print("run when UIView appears on screen ",brushWidth,hexStringToUIColor(hex: colorString))
//        color = hexStringToUIColor(hex: colorString)
        // you can update your label's text or etc.
        
        if(tempImageView != nil){
            tempImageView.removeFromSuperview();
        }
        if(mainImageView != nil){
            mainImageView.removeFromSuperview();
        }
        
        tempImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        mainImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        
        
        let rect = CGRect(origin: .zero, size: frame.size)
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
        UIColor.white.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        
        mainImageView.image = image
        tempImageView.image = image
        
        mainImageView.contentMode = UIView.ContentMode.scaleAspectFit
        
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
                            
                            self.mainImageView.image = image
                        }
                    }
                    
                }
                else{
                    do {
                        mainImageView.image = try UIImage(data: Data(contentsOf: URL(string: imageBackgroundUri)!))
                        
                    }
                    catch {
                        fatalError("Could not create UIImage from data error: \(error).")
                    }
                }
                
            }
            else{
                mainImageView.image =  UIImage(contentsOfFile: imageBackgroundUri)
            }
            
        }
        
        
//        mainImageView.alpha = 0
        
        
        self.backgroundColor = .white

        
        self.addSubview(mainImageView)
        self.addSubview(tempImageView)
        
        setNeedsDisplay()
    }
    
    /// Determines whether a last change can be undone
    @objc public var canUndo: Bool {
        return lines.count > 0
    }
    
    /// Determines whether an undone change can be redone
    @objc public var canRedo: Bool {
        return drawingHistory.count > lines.count
    }
    
    /// Undo the last change
    @objc public func undo() {
        guard lines.count > 0 else { return }
        lines.removeLast()
        setNeedsDisplay()
        onEventOccured()
    }
    
    /// Redo the last change
    @objc public func redo() {
//        if let line = drawingHistory[safe: lines.count] {return}
        guard let line:Line? = drawingHistory[safe: lines.count] else { return }
        lines.append(line!)
        setNeedsDisplay()
        onEventOccured()
    }
    
    func onEventOccured(){
        if onEventStackUpdated != nil {
            DispatchQueue.main.async {
                self.onEventStackUpdated!(["canRedo": self.canRedo, "canUndo": self.canUndo])
            }
        }
    }
    

    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
    
        
//        tempImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
//        mainImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
//        mainImageView.image = UIImage(imageLiteralResourceName: "AppIcon")
//        tempImageView.image = UIImage(imageLiteralResourceName: "AppIcon")
//
//        self.addSubview(mainImageView)
//        self.addSubview(tempImageView)
//    }
    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
    
//        tempImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
//        mainImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
//        mainImageView.image = UIImage(imageLiteralResourceName: "AppIcon")
//        tempImageView.image = UIImage(imageLiteralResourceName: "AppIcon")
//
//        self.addSubview(mainImageView)
//        self.addSubview(tempImageView)
//    }
    
    public func tempFunction(){
        var temp = UIView(frame: self.bounds)
        
        
    }
    
    public func getImage(context:CGContext){
        let start = DispatchTime.now()
        
        
        UIGraphicsPushContext(context);
        
        
        // Fallback on earlier versions
//         self.layer.render(in: context)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
        
        
        
        UIGraphicsPopContext();

        
//        print("Time to get image  \(Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000) seconds")
    }
    
    public func getImage() -> UIImage{
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
                self.layer.render(in: context)
//                self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
                
                resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            }
        }
        
        return resultImage
    }
    
    func resizepath(Fitin frame : CGRect, drewIn: CGRect, path : CGPath) -> CGPath{
        
        
        let boundingBox = drewIn
        let boundingBoxAspectRatio = boundingBox.width / boundingBox.height
        let viewAspectRatio = frame.width  / frame.height
        var scaleFactor : CGFloat = 1.0
        if (boundingBoxAspectRatio > viewAspectRatio) {
            // Width is limiting factor
            
            scaleFactor = frame.width / boundingBox.width
        } else {
            // Height is limiting factor
            scaleFactor = frame.height / boundingBox.height
        }
        
        var scaleTransform = CGAffineTransform.identity
        scaleTransform = scaleTransform.scaledBy(x: scaleFactor, y: scaleFactor)
        scaleTransform.translatedBy(x: -boundingBox.minX, y: -boundingBox.minY)
        
        let scaledSize = boundingBox.size.applying(CGAffineTransform (scaleX: scaleFactor, y: scaleFactor))
        let centerOffset = CGSize(width: (frame.width - scaledSize.width ) / scaleFactor * 2.0, height: (frame.height - scaledSize.height) /  scaleFactor * 2.0 )
        scaleTransform = scaleTransform.translatedBy(x: centerOffset.width, y: centerOffset.height)
        //CGPathCreateCopyByTransformingPath(path, &scaleTransform)
        let  scaledPath = path.copy(using: &scaleTransform)
        
        if(scaledPath != nil){
            return scaledPath!;
        }
        else{
            return path;
        }
        
        return scaledPath!
    }
    
    public func getImage() -> CGImage?{
//        return mainImageView.image?.cgImage
        
        

        let start = DispatchTime.now()
        var resultImage:UIImage = UIImage()
        var method:String?
        
        if #available(iOS 10.0, *), false {
            let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        
            resultImage = renderer.image { ctx in
                self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
            }
            
            method = "new"
            
        } else {
            
            // Fallback on earlier versions
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
            defer { UIGraphicsEndImageContext() }
            if let context = UIGraphicsGetCurrentContext() {
    //            self.layer.render(in: context)
                self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
    
                resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            }
            method = "old"
        }
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
        let timeInterval = Double(nanoTime) / 1_000_000_000
        print("Time to get image \(method): \(timeInterval) seconds")
        
        return resultImage.cgImage;
        
        
        return nil
//        return (UIGraphicsGetImageFromCurrentImageContext()?.cgImage)!;
//        guard let context: CGContext = UIGraphicsGetCurrentContext() else {
//            print("context nil")
//            return UIGraphicsGetImageFromCurrentImageContext()
//        }
//        print("context", context);
//        return context.makeImage()!;
//        return (UIGraphicsGetCurrentContext()?.makeImage())!;
    }
    
    /// Overriding draw(rect:) to stroke paths
    override func draw(_ rect: CGRect) {
        color = hexStringToUIColor(hex: colorString)
        UIGraphicsBeginImageContext(self.frame.size)
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return }
        
        UIColor.clear.setFill()
        UIRectFill(self.frame)
        
        
        
        for line in lines {
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.setLineWidth(line.brush.width)
            // set blend mode so an eraser actually erases stuff
            context.setBlendMode(line.brush.blendMode)
            context.setAlpha(line.brush.opacity)
            context.setStrokeColor(line.brush.color.cgColor)
            context.addPath(self.resizepath(Fitin: self.frame, drewIn: line.drewFrame! , path: line.path))
            context.strokePath()
        }
        
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
//        drawOnImage()
    }
    
    open func drawOnImage() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        UIColor.clear.setFill()
        UIRectFill(self.frame)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
            self.mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            
            
        }
        let backgroundDispatch:DispatchQueue =  DispatchQueue.global(qos: .userInitiated)
        
        backgroundDispatch.async {
            // Download file or perform expensive task
            
            DispatchQueue.main.async {
                // Update the UI
                
            }
            
        }
        
        
    }
    
    
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        color = hexStringToUIColor(hex: colorString)
        UIGraphicsBeginImageContext(self.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        tempImageView.image?.draw(in: self.bounds)
        
        context.move(to: fromPoint)
        context.addLine(to: toPoint)
        
        context.setLineCap(.butt)
        context.setBlendMode(.normal)
        context.setLineWidth(brushWidth)
        context.setStrokeColor(color.cgColor)
        
        context.strokePath()
        
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImageView.alpha = opacity
        
        UIGraphicsEndImageContext()
    }
    
    /// touchesBegan implementation to capture strokes
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled, let touch = touches.first else { return }
//        if #available(iOS 9.1, *) {
//            guard allowedTouchTypes.flatMap({ $0.uiTouchTypes }).contains(touch.type) else { return }
//        }
       
        
        setTouchPoints(touch, view: self)
        let blendMode = self.isErasing ? .clear : brush.blendMode;
        let color = hexStringToUIColor(hex: colorString);
        var newLine = Line(path: CGMutablePath(),
                           brush: Brush(color: color, width: brushWidth, opacity: brush.opacity, blendMode: blendMode), drewFrame: self.frame)
        newLine.isErasing = isErasing
        newLine.path.addPath(createNewPath())
        lines.append(newLine)
        drawingHistory = lines // adding a new line should also update history
        
//        draw(self.bounds)
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first else {
//            return
//        }
//        swiped = false
//        lastPoint = touch.location(in: self)
//
////        print("touch began")
//    }
    
    /// touchesMoves implementation to capture strokes
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled, let touch = touches.first else { return }
//        if #available(iOS 9.1, *) {
//            guard allowedTouchTypes.flatMap({ $0.uiTouchTypes }).contains(touch.type) else { return }
//        }
//        delegate?.swiftyDraw(isDrawingIn: self, using: touch)
        updateTouchPoints(for: touch, in: self)
        let newPath = createNewPath()
        if let currentPath = lines.last {
            currentPath.path.addPath(newPath)
        }
        
        
//        draw(self.bounds)
    }
    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first else {
//            return
//        }
//        swiped = true
//        let currentPoint = touch.location(in: self)
//        drawLine(from: lastPoint, to: currentPoint)
//
//        lastPoint = currentPoint
//    }
    
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled, let touch = touches.first else { return }
        onEventOccured()
//        delegate?.swiftyDraw(didFinishDrawingIn: self, using: touch)
//        draw(self.bounds)
    }
    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if !swiped {
//            // draw a single point
//            drawLine(from: lastPoint, to: lastPoint)
//        }
//
//
//        // Merge tempImageView into mainImageView
//        UIGraphicsBeginImageContext(mainImageView.frame.size)
//        mainImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height), blendMode: .normal, alpha: 1.0)
//        tempImageView?.image?.draw(in: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height), blendMode: .normal, alpha: opacity)
//        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        //            tempImageView.image = nil
//    }
    
    
    /********************************** Private Functions **********************************/
    
    private func setTouchPoints(_ touch: UITouch,view: UIView) {
        previousPoint = touch.previousLocation(in: view)
        previousPreviousPoint = touch.previousLocation(in: view)
        currentPoint = touch.location(in: view)
    }
    
    private func updateTouchPoints(for touch: UITouch,in view: UIView) {
        previousPreviousPoint = previousPoint
        previousPoint = touch.previousLocation(in: view)
        currentPoint = touch.location(in: view)
    }
    
    private func createNewPath() -> CGMutablePath {
        let midPoints = getMidPoints()
        let subPath = createSubPath(midPoints.0, mid2: midPoints.1)
        let newPath = addSubPathToPath(subPath)
        return newPath
    }
    
    private func calculateMidPoint(_ p1 : CGPoint, p2 : CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) * 0.5, y: (p1.y + p2.y) * 0.5);
    }
    
    private func getMidPoints() -> (CGPoint,  CGPoint) {
        let mid1 : CGPoint = calculateMidPoint(previousPoint, p2: previousPreviousPoint)
        let mid2 : CGPoint = calculateMidPoint(currentPoint, p2: previousPoint)
        return (mid1, mid2)
    }
    
    private func createSubPath(_ mid1: CGPoint, mid2: CGPoint) -> CGMutablePath {
        let subpath : CGMutablePath = CGMutablePath()
        subpath.move(to: CGPoint(x: mid1.x, y: mid1.y))
        subpath.addQuadCurve(to: CGPoint(x: mid2.x, y: mid2.y), control: CGPoint(x: previousPoint.x, y: previousPoint.y))
        return subpath
    }
    
    private func addSubPathToPath(_ subpath: CGMutablePath) -> CGMutablePath {
        let bounds : CGRect = subpath.boundingBox
        let drawBox : CGRect = bounds.insetBy(dx: -2.0 * brush.width, dy: -2.0 * brush.width)
        self.setNeedsDisplay(drawBox)
        return subpath
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
