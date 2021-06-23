//
//  OrthogonalPatternsView.swift
//  RNViewRecorder
//
//  Created by Toddle on 30/01/2020.
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation
import UIKit

class OrthogonalPatternsView:UIView{
    
    
    @objc var type: String = ""
    @objc var color: String = "#dbdbdb"
    
    let space = 48
    
    let utils:DrawUtils = DrawUtils()
        
    let tan30 = tan(30.0*(M_PI / 180))
    
    func getColor()->CGColor{
        return utils.hexStringToUIColor(hex: color).cgColor;
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        print("inside ortho draw")
        
        if(type == "dots"){
            self.drawDots(in: context!)
        }
        else if(type == "math"){
            self.drawVerticalLines(in: context!)
            self.drawHorizontalLines(in: context!)
        }
        else if(type == "lines"){
            self.drawHorizontalLines(in: context!)
        }
        else if(type == "orthogonal"){
            self.drawDiagnalRightLines(in: context!)
            self.drawDiagonalLeftLines(in: context!)
        }
    }
    
    
    func drawHorizontalLines(in context: CGContext){
        var startY = space / 2;
        
        var width = Int(self.bounds.width)
        var height = Int(self.bounds.height)
        
        while(startY < height){
            context.setLineWidth(1)
            context.setStrokeColor(self.getColor())
            context.move(to: CGPoint(x: 0, y: startY))
            context.addLine(to: CGPoint(x: width, y: startY))
            context.strokePath()
            
            startY = startY + space
        }
    }
    
    func drawVerticalLines(in context: CGContext){
        var startX = space / 2;
        
        var width = Int(self.bounds.width)
        var height = Int(self.bounds.height)
        
        while(startX < width){
            context.setLineWidth(1)
            context.setStrokeColor(self.getColor())
            context.move(to: CGPoint(x: startX, y: 0))
            context.addLine(to: CGPoint(x: startX, y: height))
            context.strokePath()
            
            startX = startX + space
        }
    }
    
    func drawDots(in context: CGContext){
        var startX = 0
        var startY = 0
        
        let width = Int(self.bounds.width)
        let height = Int(self.bounds.height)
        
        let size = CGSize(width: 2, height: 2)
        
        while(startY < height){
            startX = space / 2
            while(startX < width){
                context.setStrokeColor(self.getColor())
                let path = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: startX-1, y: startY-1), size: size))
                utils.hexStringToUIColor(hex: color).setFill()
                path.fill()
                context.addPath(path.cgPath)
                context.strokePath()
                startX = startX + space
            }
            startY = startY + space
        }
    }
    
    func drawDiagnalRightLines(in context: CGContext){
        var startX = Double(space) / tan30
        var startY = Double(space)

        let width = Double(self.bounds.width)
        let height = Double(self.bounds.height)
        
        let xSegment = Double(space) / tan30
        let ySegment = Double(space)
        
        let numberOfLines = width / xSegment + height / ySegment
        
        var i = 0.0
        
        while(i < numberOfLines){
            context.setLineWidth(1)
            context.setStrokeColor(self.getColor())
            context.move(to: CGPoint(x: 0, y: startY))
            context.addLine(to: CGPoint(x: startX, y: 0))
            context.strokePath()
            
            startX = startX + Double(space) / tan30
            startY = startY + Double(space)
            i = i + 1
        }
        
        startX = (Double(space) / tan30)/2
        while(startX < width){
            context.setLineWidth(1)
            context.setStrokeColor(self.getColor())
            context.move(to: CGPoint(x: startX, y: 0))
            context.addLine(to: CGPoint(x: startX, y: height))
            context.strokePath()
            
            startX = startX + (Double(space) / tan30)/2
        }
        
    }
    
    func drawDiagonalLeftLines(in context: CGContext){
        let width = Double(self.bounds.width)
        let height = Double(self.bounds.height)
        
        var i = 0.0
        
        let xSegment = Double(space) / tan30
        let ySegment = Double(space)
        
        let numberOfLines = width / xSegment + height / ySegment
        
        let tempStartY = height.remainder(dividingBy: ySegment)
        
        var startX =  (tempStartY / tan30)
        var startY = height - tempStartY
        while(i < numberOfLines){
            context.setLineWidth(1)
            context.setStrokeColor(self.getColor())
            context.move(to: CGPoint(x: 0, y: startY))
            context.addLine(to: CGPoint(x: startX, y: height))
            context.strokePath()
            
            startX = startX + Double(space) / tan30
            startY = startY - Double(space)
            i = i + 1
        }
    }
}
