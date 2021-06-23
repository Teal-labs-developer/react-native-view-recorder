//
//  CanvasShadow.swift
//  RNViewRecorder
//
//  Created by Toddle on 26/12/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation
import UIKit

class CanvasShadow:UIImageView{
    
    var canvas:Canvas?
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(canvas != nil){
            canvas?.touchesBegan(touches, with: event)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesMoved")
        if(canvas != nil){
            print("touchesMoved")
            canvas?.touchesMoved(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(canvas != nil){
            canvas?.touchesEnded(touches, with: event)
        }
    }
}
