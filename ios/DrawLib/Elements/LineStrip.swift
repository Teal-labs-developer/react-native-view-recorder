//
//  MLLine.swift
//  MaLiang
//
//  Created by Harley.xk on 2018/4/12.
//

import Foundation
import Metal
import UIKit

/// a line strip with lines and brush info
open class LineStrip: CanvasElement {
    
    public var drewIn: CGRect?
    public var renderIn: CGRect?
    
    /// element index
    public var index: Int = 0
    
    /// identifier of bursh used to render this line strip
    public var brushName: String?
    
    /// default color
    // this color will be used when line's color not set
    public var color: MLColor
    
    /// line units of this line strip, avoid change this value directly when drawing.
    public var lines: [MLLine] = []
    
    /// brush used to render this line strip
    open weak var brush: Brush? {
        didSet {
            brushName = brush?.name
        }
    }
    
    public init(lines: [MLLine], brush: Brush, drewIn: CGRect) {
        self.lines = lines
        self.brush = brush
        self.drewIn = drewIn
        self.renderIn = drewIn
        self.brushName = brush.name
        self.color = brush.renderingColor
        remakBuffer(rotation: brush.rotation)
    }
    
    open func append(lines: [MLLine]) {
        self.lines.append(contentsOf: lines)
        vertex_buffer = nil
    }
    
    public func drawSelf(on target: RenderTarget?) {
        brush?.render(lineStrip: self, on: target)
    }
    
    /// get vertex buffer for this line strip, remake if not exists
    open func retrieveBuffers(rotation: Brush.Rotation) -> MTLBuffer? {
        if vertex_buffer == nil {
            remakBuffer(rotation: rotation)
        }
        return vertex_buffer
    }
    
    /// count of vertexes, set when remake buffers
    open private(set) var vertexCount: Int = 0
    
    private var vertex_buffer: MTLBuffer?
    
    func getPointString(point:CGPoint)->String{
        return "(\(point.x),\(point.y))"
    }
    
    public func transformData(renderIn: CGRect){
        for (index, element) in lines.enumerated() {
            let scaleX = renderIn.width / drewIn!.width;
            let scaleY = renderIn.height / drewIn!.height;
            let begin = CGPoint(x: element.begin.x * scaleX, y: element.begin.y * scaleY)
            let end = CGPoint(x: element.end.x * scaleX, y: element.end.y * scaleY)
//            print("Drew in frame (",drewIn?.width,",",drewIn?.height,")","(",renderIn.width,",",renderIn.height,")" ," transformmed point ",self.getPointString(point: element.begin), self.getPointString(point: element.end), " to ","",self.getPointString(point: begin), self.getPointString(point: end))
//            lines[index] = MLLine(begin: begin, end: end, pointSize: element.pointSize, pointStep: element.pointStep, color: element.color)
        }
//        drewIn = renderIn
        self.renderIn = renderIn
    }
    
    private func remakBuffer(rotation: Brush.Rotation) {
        guard lines.count > 0 else {
            return
        }
        
        var vertexes: [Point] = []
        
        lines.forEach { (line) in
            let scale = brush?.target?.contentScaleFactor ?? UIScreen.main.nativeScale
            var line = line
            line.begin = line.begin * scale
            line.end = line.end * scale
            let count = max(line.length / line.pointStep, 1)
            
            for i in 0 ..< Int(count) {
                let index = CGFloat(i)
                var x = line.begin.x + (line.end.x - line.begin.x) * (index / count)
                var y = line.begin.y + (line.end.y - line.begin.y) * (index / count)
                
                let scaleX = renderIn!.width / drewIn!.width;
                let scaleY = renderIn!.height / drewIn!.height;
                
                x = x * scaleX
                y = y * scaleY
                
                var angle: CGFloat = 0
                switch rotation {
                case let .fixed(a): angle = a
                case .random: angle = CGFloat.random(in: -CGFloat.pi ... CGFloat.pi)
                case .ahead: angle = line.angle
                }
                
                vertexes.append(Point(x: x, y: y, color: line.color ?? color, size: line.pointSize * scale, angle: angle))
            }
        }
        
        vertexCount = vertexes.count
        vertex_buffer = sharedDevice?.makeBuffer(bytes: vertexes, length: MemoryLayout<Point>.stride * vertexCount, options: .cpuCacheModeWriteCombined)
    }
    
    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case index
        case brush
        case lines
        case color
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        brushName = try container.decode(String.self, forKey: .brush)
        lines = try container.decode([MLLine].self, forKey: .lines)
        color = try container.decode(MLColor.self, forKey: .color)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(brushName, forKey: .brush)
        try container.encode(lines, forKey: .lines)
        try container.encode(color, forKey: .color)
    }
}
