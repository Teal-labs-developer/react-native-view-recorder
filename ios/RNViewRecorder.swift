@objc(RNViewRecorder)
class RNViewRecorder: RCTViewManager {
    override func view() -> DrawView! {
        let drawView = DrawView();
        
        return drawView;
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    // 1
    @objc func updateFromManager(_ node: NSNumber, count: NSNumber) {
        
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawView                                       // 5
            component.demoStartRecord(value: count)                          // 6
        }
    }
    
    @objc func setupRecorder(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawView                                       // 5
            component.setupRecorder()                          // 6
        }
    }
    
    @objc func startRecording(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawView                                       // 5
            component.startRecording()                          // 6
        }
    }
    
    @objc func stopRecording(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawView                                       // 5
            component.stopRecording()                          // 6
        }
    }
    
    @objc func resetCanvas(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawView                                       // 5
            component.resetCanvas()                           // 6
        }
    }
    
    @objc func undo(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawView                                       // 5
            component.undo()                           // 6
        }
    }
    
    @objc func redo(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawView                                       // 5
            component.redo()                           // 6
        }
    }
    
    //saveAsImage
    @objc func saveAsImage(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! DrawView                                       // 5
            component.saveAsImage()                           // 6
        }
    }
}
