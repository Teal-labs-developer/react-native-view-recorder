@objc(RNOrthogonalPatternsView)
class RNOrthogonalPatternsView: RCTViewManager {
    override func view() -> OrthogonalPatternsView! {
        let view = OrthogonalPatternsView();
        
//        let frameworkBundle = Bundle(for: DrawView.self)
//        guard let defaultLibrary = try? sharedDevice?.makeDefaultLibrary(bundle: frameworkBundle) else {
//            fatalError("Could not load default library from specified bundle")
//        }
        
        return view;
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
