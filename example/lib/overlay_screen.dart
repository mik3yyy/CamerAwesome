// File: lib/overlay_screen.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:camera_app/hole_widget.dart';
import 'package:camera_app/timer_controller.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
                      child: CameraAwesomeBuilder.awesome(
                        onMediaCaptureEvent: _handleMediaCaptureEvent,
                        saveConfig: SaveConfig.photoAndVideo(
                          mirrorFrontCamera: true,
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
                              fallbackStrategy: QualityFallbackStrategy.lower,
                            ),
                          ),
                          exifPreferences:
                              ExifPreferences(saveGPSLocation: false),
                        ),
                        sensorConfig: SensorConfig.single(
                          sensor: Sensor.position(SensorPosition.front),
                          flashMode: FlashMode.auto,
                          aspectRatio: CameraAspectRatios.ratio_16_9,
                          zoom: 0.0,
                        ),
                        enablePhysicalButton: true,
                        previewAlignment: Alignment.center,
                        previewFit: CameraPreviewFit.contain,
                        controller:
                            widget.cameraController, // Pass the controller
                      ),
                    ),
                    Center(
                      child: ValueListenableBuilder<double>(
                        valueListenable:
                            widget.recordingController.recordingDuration,
                        builder: (context, duration, child) {
                          return CustomPaint(
                            size: const Size(375, 375),
                            painter: CircularProgressPainter(
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

  CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Normalize progress to a value between 0 and 1
    final double normalizedProgress = (progress.clamp(0.0, 30.0)) / 30.0;

    // Convert normalized progress to radians (0 to 2π)
    final double sweepAngle = normalizedProgress * 2 * pi;

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (min(size.width, size.height) / 2) -
          4, // Ensures the circle fits within the widget
    );

    // Start at the top (-π/2 radians)
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
