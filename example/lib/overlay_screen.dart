// File: lib/overlay_screen.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:camera_app/hole_widget.dart';
import 'package:camera_app/timer_controller.dart';
import 'package:camera_app/utils/file_utils.dart';
import 'package:camera_app/widgets/video_processor.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/v5.dart';
import 'package:flutter/services.dart' show rootBundle;

class OverlayScreen extends StatefulWidget {
  const OverlayScreen(
      {super.key,
      required this.cameraController,
      required this.onDone,
      required this.isLocked,
      required this.isRecording,
      required this.lockObs,
      required this.isValidDuration,
      required this.recordingController});
  final CameraController cameraController;
  final RecordingController recordingController;
  final Function(String path) onDone;
  final bool isValidDuration;
  final bool isLocked;
  final double lockObs;
  final bool isRecording;
  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  String? _videoPath; // To store the path of the recorded video
  Future<void> _shareVideoFile(String videoPath) async {
    try {
      // Ensure the file exists before attempting to share
      String? n = await exportCVideo(videoPath);
      // String? n = await exportCircularVideo(videoPath);
      final videoFile = File(n ?? "");

      if (await videoFile.exists()) {
        // Share the video file
        await Share.shareXFiles(
          [XFile(videoFile.path)],
        );
      } else {
        print('Error: Video file does not exist at the provided path.');
      }
    } catch (e) {
      print('Error sharing video file: $e');
    }
  }

  Future<void> copyAssetToFile(String assetPath, String targetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer;

    await File(targetPath).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }

//   Future<String?> exportCircularVideo(String inputPath) async {
//     print(inputPath);
//     // Get the directory to save the output video
//     final directory = await getApplicationDocumentsDirectory();
//     var uuid = Uuid();
//     final outputPath = '${directory.path}/output_circular_${uuid.v4()}.mp4';
// //THIS WORKS
  // String ffmpegCommand =
  //     """-i $inputPath -vf "crop='min(iw,ih)':'min(iw,ih)',scale=512:512,geq=r='if(gt(sqrt((X-W/2)^2+(Y-H/2)^2),W/2),0,p(X,Y))':g='if(gt(sqrt((X-W/2)^2+(Y-H/2)^2),W/2),0,g(X,Y))':b='if(gt(sqrt((X-W/2)^2+(Y-H/2)^2),W/2),0,b(X,Y))'" -c:v libx264 -crf 23 -preset veryfast -pix_fmt yuv420p $outputPath""";
//     if (await File(inputPath).exists()) {
//       print(true);
//     }
//     // Execute the FFmpeg command
//     await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
//       final returnCode = await session.getReturnCode();
//       if (ReturnCode.isSuccess(returnCode)) {
//         print('Video exported successfully to $outputPath');
//         session.cancel();
//       } else if (ReturnCode.isCancel(returnCode)) {
//         print('FFmpeg process was cancelled');
//       } else {
//         print('FFmpeg process failed with return code $returnCode');
//       }
//     }, (log) {
//       print(log.getMessage());
//     });
//     // Check if the output file exists
//     final outputFile = File(outputPath);
//     print(outputFile);
//     print(await outputFile.exists());
//     if (await outputFile.exists()) {
//       return outputPath;
//     } else {
//       return null;
//     }
//   }

  Future<String?> exportCircularVideo(String inputPath) async {
    print('Input Path: $inputPath');

    // Get the directory to save the output video
    final directory = await getApplicationDocumentsDirectory();
    var uuid = Uuid();

    final outputPath = '${directory.path}/output_circular_${uuid.v4()}.mp4';

    // Optimized single-line FFmpeg command
    // Replace 'libx264' with 'h264_mediacodec' (Android) or 'h264_videotoolbox' (iOS) if hardware acceleration is enabled
    // String ffmpegCommand =
    //     '-i "$inputPath" -vf "crop=\'min(iw,ih)\':\'min(iw,ih)\',scale=480:480,geq=r=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,p(X,Y))\':g=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,g(X,Y))\':b=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,b(X,Y))\'" -c:v libx264 -b:v 758k -preset veryfast -pix_fmt yuv420p -ac 1 "$outputPath"';

    // Uncomment the following line for Android hardware acceleration
    // String ffmpegCommand = '-i "$inputPath" -vf "crop=\'min(iw,ih)\':\'min(iw,ih)\',scale=480:480,geq=r=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,p(X,Y))\':g=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,g(X,Y))\':b=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,b(X,Y))\'" -c:v h264_mediacodec -b:v 758k -preset veryfast -pix_fmt yuv420p -ac 1 "$outputPath"';
    String ffmpegCommand = "";
    if (Platform.isIOS) {
      ffmpegCommand =
          // '-i "$inputPath" -vf "crop=\'min(iw,ih)\':\'min(iw,ih)\',scale=480:480,geq=r=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,p(X,Y))\':g=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,g(X,Y))\':b=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,b(X,Y))\'" -c:v h264_videotoolbox -b:v 750k -preset ultrafast -pix_fmt yuv420p -ac 2 "$outputPath"';
          """-i $inputPath -vf "crop='min(iw,ih)':'min(iw,ih)',scale=480:480,geq=r='if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,p(X,Y))':g='if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,g(X,Y))':b='if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,b(X,Y))'" -c:v h264_videotoolbox -b:v 750k -preset ultrafast -pix_fmt yuv420p -ac 2 -threads 4 $outputPath""";

      // '-i "$inputPath" -vf "crop=\'min(iw,ih)\':\'min(iw,ih)\',scale=480:480,geq=r=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,p(X,Y))\':g=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,g(X,Y))\':b=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,b(X,Y))\'" -c:v libx264 -b:v 750k -preset veryfast -pix_fmt yuv420p -ac 2 "$outputPath"';
    } else {
      ffmpegCommand =
          '-i "$inputPath" -vf "crop=\'min(iw,ih)\':\'min(iw,ih)\',scale=480:480,geq=r=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,p(X,Y))\':g=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,g(X,Y))\':b=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,b(X,Y))\'" -c:v h264_mediacodec -b:v 758k -preset veryfast -pix_fmt yuv420p -ac 2 "$outputPath"';
    }
    // Uncomment the following line for iOS hardware acceleration

    // Print the FFmpeg command for debugging
    print('FFmpeg Command: $ffmpegCommand');

    // Check if the input file exists
    if (await File(inputPath).exists()) {
      print('Input file exists.');
    } else {
      print('Input file does not exist.');
      return null;
    }

    // Execute the FFmpeg command
    await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print('Video exported successfully to $outputPath');

        // Set the creation and modification dates to current time
        final now = DateTime.now();
        final outputFile = File(outputPath);

        // Update the file's modification time
        await outputFile.setLastModified(now);
        await outputFile.setLastAccessed(DateTime.now());
        var st = await outputFile.stat();

        // Note: Setting the creation time is not directly supported in Dart.
        // Consider embedding metadata or using platform-specific code if necessary.
      } else if (ReturnCode.isCancel(returnCode)) {
        print('FFmpeg process was cancelled');
      } else {
        print('FFmpeg process failed with return code $returnCode');
      }
    }, (log) {
      print('FFmpeg Log: ${log.getMessage()}');
    });

    // Check if the output file exists
    final outputFile = File(outputPath);
    print('Output File Path: $outputFile');
    print('Does output file exist? ${await outputFile.exists()}');

    if (await outputFile.exists()) {
      return outputPath;
    } else {
      return null;
    }
  }

  // Future<String?> exportCircularVideo(String inputPath) async {
  //   print('Input Path: $inputPath');
  //   // Get the directory to save the output video
  //   final directory = await getApplicationDocumentsDirectory();
  //   var uuid = Uuid();
  //   final outputPath = '${directory.path}/output_circular_${uuid.v4()}.mp4';
  //   // Updated FFmpeg command
  //   String ffmpegCommand =
  //       '-i "$inputPath" -vf "crop=\'min(iw,ih)\':\'min(iw,ih)\',scale=480:480,geq=r=\'if(gt(sqrt((X-W/2)^2+(Y-H/2)^2),W/2),0,p(X,Y))\':g=\'if(gt(sqrt((X-W/2)^2+(Y-H/2)^2),W/2),0,g(X,Y))\':b=\'if(gt(sqrt((X-W/2)^2+(Y-H/2)^2),W/2),0,b(X,Y))\'" -c:v libx264 -b:v 758k -preset veryfast -pix_fmt yuv420p -ac 1 "$outputPath"';
  //   // Print the FFmpeg command for debugging
  //   print('FFmpeg Command: $ffmpegCommand');
  //   // Check if the input file exists
  //   if (await File(inputPath).exists()) {
  //     print('Input file exists.');
  //   } else {
  //     print('Input file does not exist.');
  //     return null;
  //   }
  //   // Execute the FFmpeg command
  //   await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
  //     final returnCode = await session.getReturnCode();
  //     if (ReturnCode.isSuccess(returnCode)) {
  //       print('Video exported successfully to $outputPath');
  //       // Set the creation and modification dates to current time
  //       final now = DateTime.now();
  //       final outputFile = File(outputPath);
  //       // Update the file's modification time
  //       await outputFile.setLastModified(now);
  //       // Note: Dart does not provide a direct way to set the creation time.
  //       // This may require platform-specific code or third-party packages.
  //       // Alternatively, you can embed metadata into the video file itself.
  //     } else if (ReturnCode.isCancel(returnCode)) {
  //       print('FFmpeg process was cancelled');
  //     } else {
  //       print('FFmpeg process failed with return code $returnCode');
  //     }
  //   }, (log) {
  //     print('FFmpeg Log: ${log.getMessage()}');
  //   });
  //   // Check if the output file exists
  //   final outputFile = File(outputPath);
  //   print('Output File Path: $outputFile');
  //   print('Does output file exist? ${await outputFile.exists()}');
  //   if (await outputFile.exists()) {
  //     return outputPath;
  //   } else {
  //     return null;
  //   }
  // }

  Future<String?> exportCVideo(String iP) async {
    VideoProcessor videoProcessor = VideoProcessor();
    return await videoProcessor.processVideo(iP);
  }

  void _handleMediaCaptureEvent(MediaCapture event) {
    switch ((event.status, event.isPicture, event.isVideo)) {
      case (MediaCaptureStatus.capturing, false, true):
        debugPrint('Capturing video...');
        break;

      case (MediaCaptureStatus.success, false, true):
        event.captureRequest.when(
          single: (single) async {
            debugPrint('Video saved: ${single.file?.path}');
            final Map<String, dynamic> videoDetails = {};
            _shareVideoFile(single.file?.path ?? "");
            // Step 1: Get basic details using video_player
            final file = File(single.file?.path ?? "");
            final size = file.lengthSync(); // Get file size in bytes
            videoDetails['size'] =
                '${(size / (1024 * 1024)).toStringAsFixed(2)} MB'; // Convert to MB
            print(videoDetails);
            if (widget.isValidDuration) {
              setState(() {
                _videoPath = single.file?.path;
              });
              widget.onDone(_videoPath!);
            }
          },
          multiple: (multiple) {
            multiple.fileBySensor.forEach((key, value) {
              debugPrint('Multiple videos taken: $key ${value?.path}');
              setState(() {
                _videoPath = value?.path;
              });
            });
          },
        );
        break;

      case (MediaCaptureStatus.failure, false, true):
        debugPrint('Failed to capture video: ${event.exception}');
        break;

      default:
        debugPrint('Unknown event: $event');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(.7),
        body: Container(
          color: Colors.transparent,
          width: MediaQuery.sizeOf(context).width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        child: HoleWidget(
                          radius: 185,
                          child: Transform.scale(
                            scaleX: 0.935,
                            scaleY: 0.935,
                            child: CameraAwesomeBuilder.awesome(
                              onMediaCaptureEvent: _handleMediaCaptureEvent,
                              saveConfig: SaveConfig.photoAndVideo(
                                // mirrorFrontCamera: true,
                                initialCaptureMode: CaptureMode.video,
                                photoPathBuilder: (sensors) async {
                                  final Directory extDir =
                                      await getTemporaryDirectory();
                                  final testDir = await Directory(
                                    '${extDir.path}/camerawesome',
                                  ).create(recursive: true);
                                  if (sensors.length == 1) {
                                    final String filePath =
                                        '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                                    return SingleCaptureRequest(
                                        filePath, sensors.first);
                                  }
                                  // Separate pictures taken with front and back camera
                                  return MultipleCaptureRequest(
                                    {
                                      for (final sensor in sensors)
                                        sensor:
                                            '${testDir.path}/${sensor.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.jpg',
                                    },
                                  );
                                },
                                videoOptions: VideoOptions(
                                  enableAudio: true,
                                  quality: VideoRecordingQuality.lowest,
                                  ios: CupertinoVideoOptions(
                                    fps: 30,
                                    codec: CupertinoCodecType.hevc,
                                  ),
                                  android: AndroidVideoOptions(
                                    bitrate: 800000,
                                    fallbackStrategy:
                                        QualityFallbackStrategy.lower,
                                  ),
                                ),
                                exifPreferences:
                                    ExifPreferences(saveGPSLocation: false),
                              ),
                              sensorConfig: SensorConfig.single(
                                sensor: Sensor.position(SensorPosition.front),
                                flashMode: FlashMode.auto,
                                aspectRatio: CameraAspectRatios.ratio_1_1,
                                zoom: 0.0,
                              ),
                              enablePhysicalButton: true,
                              previewAlignment: Alignment.center,
                              previewFit: CameraPreviewFit.contain,
                              controller: widget
                                  .cameraController, // Pass the controller
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ValueListenableBuilder<double>(
                        valueListenable:
                            widget.recordingController.recordingDuration,
                        builder: (context, duration, child) {
                          return CustomPaint(
                            size: const Size(380, 380),
                            painter: CircularProgressPainter(
                              radius: 190,
                              progress: duration.toDouble(),
                              color: Colors.yellow,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 90,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            await widget.cameraController.toggleFlash();

                            setState(
                                () {}); // Update the UI to reflect the flash mode change
                          },
                          child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Center(
                                child: Icon(
                                  widget.cameraController.currentFlashMode ==
                                          FlashMode.on
                                      ? Icons.flash_on
                                      : widget.cameraController
                                                  .currentFlashMode ==
                                              FlashMode.auto
                                          ? Icons.flash_auto
                                          : widget.cameraController
                                                      .currentFlashMode ==
                                                  FlashMode.always
                                              ? Icons.flashlight_on
                                              : Icons.flash_off,
                                ),
                              )),
                        ),

                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            try {
                              await widget.cameraController.switchCamera();
                            } catch (e) {}
                          },
                          child: const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Center(
                                child: Icon(Icons.cameraswitch),
                              )),
                        ),

                        // Switch Camera Button
                      ],
                    ),
                    Row(
                      children: [
                        widget.isLocked
                            ? const CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(Icons.lock_outlined))
                            : AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  color: Colors.white,
                                ),
                                transform: Matrix4.translationValues(
                                  0, // No horizontal movement
                                  widget.isRecording
                                      ? 0
                                      : 200, // Move vertically (200 units down when collapsed)
                                  0,
                                ),
                                height: 94 + (widget.lockObs * 20),
                                width: 45,
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Icon(
                                      widget.isLocked
                                          ? Icons.lock_outlined
                                          : Icons.lock_open_outlined,
                                    ),
                                    SizedBox(
                                      height: 5 +
                                          (widget.lockObs > -0.1
                                              ? widget.lockObs
                                              : 0),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_up_sharp,
                                    ),
                                    if (widget.lockObs > -0.15) ...[
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_up_sharp,
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                        const SizedBox(
                          width: 65,
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 100,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress; // Expected to be between 0 and 10
  final Color color;
  final double max;
  final double radius;
  CircularProgressPainter(
      {required this.progress,
      required this.color,
      this.max = 30,
      this.radius = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Normalize progress to a value between 0 and 1
    final double normalizedProgress = (progress.clamp(0.0, max)) / max;

    // Convert normalized progress to radians (0 to 2π)
    final double sweepAngle = normalizedProgress * 2 * pi;

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius == 0 ? (min(size.width, size.height) / 2) - 4 : radius,
      // (min(size.width, size.height) / 2) -
      //     4, // Ensures the circle fits within the widget
    );

    // Start at the top (-π/2 radians)
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
