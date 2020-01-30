@objc(RNDrawView)
class RNDrawView: RCTViewManager {
    override func view() -> DrawingCanvas! {
        let drawView = DrawingCanvas();
        
        return drawView;
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    
    @objc func resetCanvas(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawingCanvas                                      // 5
            component.clear()                           // 6
        }
    }
    
    @objc func undo(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawingCanvas                                       // 5
            component.undo()                           // 6
        }
    }
    
    @objc func redo(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawingCanvas                                     // 5
            component.redo()                           // 6
        }
    }
    
    //saveAsImage
    @objc func saveAsImage(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawingCanvas                                       // 5
            component.saveAsImage()                           // 6
        }
    }
    
   
    
}
