@objc(RNViewRecorder)
class RNViewRecorder: RCTViewManager {
    override func view() -> RecorderView! {
        let drawView = RecorderView();
        
//        let frameworkBundle = Bundle(for: DrawView.self)
//        guard let defaultLibrary = try? sharedDevice?.makeDefaultLibrary(bundle: frameworkBundle) else {
//            fatalError("Could not load default library from specified bundle")
//        }
        
        return drawView;
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc func setupRecorder(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! RecorderView                                       // 5
            component.setupRecorder()                          // 6
        }
    }
    
    @objc func startRecording(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! RecorderView                                       // 5
            component.startRecording()                          // 6
        }
    }
    
    @objc func stopRecording(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! RecorderView                                       // 5
            component.stopRecording()                          // 6
        }
    }

    @objc func pauseRecording(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! RecorderView                                       // 5
            component.pauseRecording()                          // 6
        }
    }
    
   
    
    //saveAsImage
    @objc func saveAsImage(_ node: NSNumber){
        DispatchQueue.main.async {                                // 2
            let component = self.bridge.uiManager.view(             // 3
                forReactTag: node                                     // 4
                ) as! RecorderView                                       // 5
            component.saveAsImage()                           // 6
        }
    }
}
