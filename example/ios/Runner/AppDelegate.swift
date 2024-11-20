import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let CHANNEL = "com.example.video_processor" // Define your channel name

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register Flutter plugins
        GeneratedPluginRegistrant.register(with: self)

        // Set up the method channel
        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not of type FlutterViewController")
        }
        let videoProcessorChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

        // Handle method calls from Flutter
        videoProcessorChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {
            case "processVideo":
                if let videoPath = call.arguments as? [String: Any],
                   let path = videoPath["videoPath"] as? String {
                    self.processVideo(videoPath: path) { outputPath in
                        if let outputPath = outputPath {
                            result(outputPath) // Send the processed video path back to Flutter
                        } else {
                            result(FlutterError(code: "PROCESSING_ERROR", message: "Video processing failed", details: nil))
                        }
                    }
                } else {
                    result(FlutterError(code: "INVALID_PATH", message: "Video path is null", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Method to process the video
    private func processVideo(videoPath: String, completion: @escaping (String?) -> Void) {
        let outputDirectory = FileManager.default.temporaryDirectory
        let outputPath = outputDirectory.appendingPathComponent(UUID().uuidString + "_processed.mp4").path
        
        // Call helper function to apply circular mask and adjust audio
        let videoProcessor = VideoProcessingHelper()
        videoProcessor.applyCircularMaskToVideo(inputPath: videoPath, outputPath: outputPath) { result in
            completion(result)
        }
    }
}
