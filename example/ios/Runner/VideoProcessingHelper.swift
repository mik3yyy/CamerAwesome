
import AVFoundation
import UIKit

class VideoProcessingHelper {

    // Apply circular mask to video frames and adjust audio settings
    func applyCircularMaskToVideo(inputPath: String, outputPath: String, completion: @escaping (String?) -> Void) {
        let asset = AVAsset(url: URL(fileURLWithPath: inputPath))
        let composition = AVMutableComposition()

        // Create the video track
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }

        // Add video track to composition
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil)
            return
        }

        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
        } catch {
            completion(nil)
            return
        }

        // Add audio track (if available)
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
            } catch {
                completion(nil)
                return
            }
        }

        // Create a mutable video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: 512, height: 512)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        // Apply the circular mask
        let maskLayer = createCircularMaskLayer(size: CGSize(width: 512, height: 512))
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: videoTrack.naturalSize.height/8, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
        videoLayer.position = CGPoint(x: 256, y: 256) // Center the video in the 512x512 canvas
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: 512, height: 512)
        parentLayer.addSublayer(videoLayer)

        // Set the mask layer to only reveal a circular portion of the video
        let maskedLayer = CALayer()
        maskedLayer.frame = parentLayer.bounds
        maskedLayer.mask = maskLayer
        maskedLayer.addSublayer(videoLayer)

        parentLayer.addSublayer(maskedLayer)

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

        // Create composition instruction
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [videoLayerInstruction]
        videoComposition.instructions = [instruction]

        // Set up stereo audio output settings
        let audioMix = AVMutableAudioMix()
        if let audioTrack = composition.tracks(withMediaType: .audio).first {
            let audioInputParams = AVMutableAudioMixInputParameters(track: audioTrack)
            audioInputParams.setVolume(1.0, at: .zero)
            audioMix.inputParameters = [audioInputParams]
        }

        // Export the video with the applied mask
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        exporter.videoComposition = videoComposition
        exporter.audioMix = audioMix
        exporter.outputFileType = .mp4
        exporter.outputURL = URL(fileURLWithPath: outputPath)

        exporter.exportAsynchronously {
            if exporter.status == .completed {
                completion(outputPath)
            } else {
                print("Error processing video: \(String(describing: exporter.error))")
                completion(nil)
            }
        }
    }

    // Create circular mask layer
    private func createCircularMaskLayer(size: CGSize) -> CALayer {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.black.cgColor
        return maskLayer
    }
}
