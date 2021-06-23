//
//  HelperManager.swift
//  RNViewRecorder
//
//  Created by Toddle on 12/01/2020.
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation
import UIKit

// CalendarManager.swift

@objc(DrawHelperManager)
class DrawHelperManager: NSObject {
  
  @objc func isDeviceCompatible(_ callback: (NSObject) -> ()) {
    let context = CIContext()
    
    
    callback( [[
        "isCompatible": context.description.contains("opengl")
        ]] as NSObject)
  }
  
}
