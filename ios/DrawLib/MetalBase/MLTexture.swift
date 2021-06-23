//
//  MLTexture.swift
//  MaLiang
//
//  Created by Harley-xk on 2019/4/18.
//

import Foundation
import Metal
import UIKit
import AVKit

/// texture with UUID
open class MLTexture: Hashable {
    
    open private(set) var id: String
    
    open private(set) var texture: MTLTexture
    
    init(id: String, texture: MTLTexture) {
        self.id = id
        self.texture = texture
    }

    // size of texture in points
    open lazy var size: CGSize = {
        let scaleFactor = UIScreen.main.nativeScale
        return CGSize(width: CGFloat(texture.width) / scaleFactor, height: CGFloat(texture.height) / scaleFactor)
    }()

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: MLTexture, rhs: MLTexture) -> Bool {
        return lhs.id == rhs.id
    }
}

public extension MTLTexture {
    
    var context: CIContext? {
        var context1 = CIContext() // Prepare for create CGImage
        if(context1.description.contains("opengl")){
            context1 = CIContext(mtlDevice: device)
        }
        return context1
    }
    
    /// get CIImage from this texture
    func toCIImage() -> CIImage? {
        var image = CIImage(mtlTexture: self, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()])
        
//        image = image?.oriented(forExifOrientation: 4)
        return image
    }
    
    /// get CGImage from this texture
    func toCGImage() -> CGImage? {
        guard let ciimage = toCIImage() else {
            return nil
        }
        var context = self.context;
        if(context == nil){
            context = CIContext() // Prepare for create CGImage
            if(context!.description.contains("opengl")){
                context = CIContext(mtlDevice: device)
            }
        }
       
//        let context = CIContext(options: [.priorityRequestLow : true, .useSoftwareRenderer: false])
        // let context = CIContext(mtlDevice: device)
//        print(context.description, CIContext().description)
        let rect = CGRect(origin: .zero, size: ciimage.extent.size)
        return context!.createCGImage(ciimage, from: rect)
    }
    
    /// get UIImage from this texture
    func toUIImage() -> UIImage? {
        guard let cgimage = toCGImage() else {
            return nil
        }
        return UIImage(cgImage: cgimage)
    }
    
    /// get data from this texture
    func toData() -> Data? {
        guard let image = toUIImage() else {
            return nil
        }
        return image.pngData()
    }
}
