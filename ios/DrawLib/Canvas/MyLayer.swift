//
//  MyLayer.swift
//  RNViewRecorder
//
//  Created by Toddle on 28/01/2020.
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation

@objc public protocol MyLayerDelegate: NSObjectProtocol  {
    func getCanvas(_ view: MyLayer) -> Canvas
}

public class MyLayer:CALayer{
    
    public var myDelegate: MyLayerDelegate?
    
    override public func render(in ctx: CGContext) {
        if(myDelegate != nil){
            myDelegate?.getCanvas(self).draw(context: ctx)
        }
    }
    
    
}
