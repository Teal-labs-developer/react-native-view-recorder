//
//  AVMutableComposition+Extension.swift
//  RNViewRecorder
//
//  Created by Srijeet on 20/08/24.
//

import Foundation
import AVKit

extension AVMutableComposition {
    
    public func mergeVideo(_ urls: [URL], completion: @escaping (_ url: URL?, _ error: Error?) -> Void) {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            completion(nil, nil)
            return
        }
        
        let outputURL = documentDirectory.appendingPathComponent("mergedVideo_\(AVMutableComposition.randomString(length: 5)).mp4")
        
        // If there is only one video, we dont to touch it to save export time.
        if let url = urls.first, urls.count == 1 {
            do {
                try FileManager().copyItem(at: url, to: outputURL)
                completion(outputURL, nil)
            } catch let error {
                completion(nil, error)
            }
            return
        }
        
        /** Video frame's width looks a little cropped from the right, so adding a 20 pixel offset */
        let maxRenderSize = CGSize(width: UIScreen.main.bounds.width + 20, height: UIScreen.main.bounds.height)
        var currentTime = CMTime.zero
        var renderSize = CGSize.zero
        // Create empty Layer Instructions, that we will be passing to Video Composition and finally to Exporter.
        var instructions = [AVMutableVideoCompositionInstruction]()

        urls.enumerated().forEach { index, url in
            let asset = AVAsset(url: url)
            let assetTrack = asset.tracks.first!
            
            // Create instruction for a video and append it to array.
            let instruction = AVMutableComposition.instruction(assetTrack, asset: asset, time: currentTime, duration: assetTrack.timeRange.duration, maxRenderSize: maxRenderSize)
            instructions.append(instruction.videoCompositionInstruction)
            
            // Set render size (orientation) according first video.
            if index == 0 {
                renderSize = CGSize(width: maxRenderSize.width, height: maxRenderSize.height)
            }
            
            do {
                let timeRange = CMTimeRangeMake(start: .zero, duration: assetTrack.timeRange.duration)
                // Insert video to Mutable Composition at right time.
                try insertTimeRange(timeRange, of: asset, at: currentTime)
                currentTime = CMTimeAdd(currentTime, assetTrack.timeRange.duration)
            } catch let error {
                completion(nil, error)
            }
        }
        
        // Create Video Composition and pass Layer Instructions to it.
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = instructions
        // Do not forget to set frame duration and render size. It will crash if you dont.
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = renderSize
        
        guard let exporter = AVAssetExportSession(asset: self, presetName: AVAssetExportPreset1280x720) else {
            completion(nil, nil)
            return
        }
        exporter.outputURL = outputURL
        exporter.outputFileType = .mp4
        // Pass Video Composition to the Exporter.
        exporter.videoComposition = videoComposition
        
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                completion(exporter.outputURL, nil)
            }
        }
    }
    
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    static func instruction(_ assetTrack: AVAssetTrack, asset: AVAsset, time: CMTime, duration: CMTime, maxRenderSize: CGSize)
        -> (videoCompositionInstruction: AVMutableVideoCompositionInstruction, isPortrait: Bool) {
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)

            // Find out orientation from preffered transform.
            let assetInfo = orientationFromTransform(assetTrack.preferredTransform)
            
            // Calculate scale ratio according orientation.
            var scaleRatio = maxRenderSize.width / assetTrack.naturalSize.width
            if assetInfo.isPortrait {
                scaleRatio = maxRenderSize.height / assetTrack.naturalSize.height
            }
            
            // Set correct transform.
            var transform = CGAffineTransform(scaleX: scaleRatio, y: scaleRatio)
            transform = assetTrack.preferredTransform.concatenating(transform)
            layerInstruction.setTransform(transform, at: .zero)
            
            // Create Composition Instruction and pass Layer Instruction to it.
            let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
            videoCompositionInstruction.timeRange = CMTimeRangeMake(start: time, duration: duration)
            videoCompositionInstruction.layerInstructions = [layerInstruction]
            
            return (videoCompositionInstruction, assetInfo.isPortrait)
    }
    
    static func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = true
        
        switch [transform.a, transform.b, transform.c, transform.d] {
        case [0.0, 1.0, -1.0, 0.0]:
            assetOrientation = .right
            isPortrait = true
            
        case [0.0, -1.0, 1.0, 0.0]:
            assetOrientation = .left
            isPortrait = true
            
        case [1.0, 0.0, 0.0, 1.0]:
            assetOrientation = .up
            
        case [-1.0, 0.0, 0.0, -1.0]:
            assetOrientation = .down

        default:
            break
        }
    
        return (assetOrientation, isPortrait)
    }
    
}
