import 'package:camera_app/overlay_screen.dart';
import 'package:camera_app/timer_controller.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/widgets/preview/hole_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';
import 'widgets/mini_video_player.dart';
import 'package:camerawesome/src/camera_controller.dart';

void main() {
  runApp(const CameraAwesomeApp());
}

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'camerAwesome',
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  String? _videoPath;
  final CameraController cameraController = CameraController();
  final RecordingController _recordingController = RecordingController();

  bool isCurrentlyRecording = false;
  bool isLocked = false;
  bool isValidDuration = false;
  double? lastRecord;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _recordingController.onDurationExceed = _handleDurationExceed;
  }

  void _handleDurationExceed() async {
    // Stop the recording and update the UI
    cameraController.stopRecording();
    setState(() {
      sendRecording = false;
      isCurrentlyRecording = false;
      isValidDuration = true;
    });
    lastRecord = _recordingController.stopRecording();

    await Future.delayed(Duration(milliseconds: 500), () {
      setState(() {});
    });
  }

  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  void startRecording() {
    isCurrentlyRecording = true;
    cameraController.startRecording().then((on) {
      _recordingController.startRecording();
    });
    lockObs = 0;

    setState(() {});
  }

  void cancelRecording() {
    isCurrentlyRecording = false;
    isValidDuration = false;
    _recordingController.stopRecording();
    cameraController.stopRecording();
    lockObs = 0;
    setState(() {});
  }

  void lockRecording() {
    print("LOCK");
    setState(() {
      isLocked = true;
      lockObs = 0;
      isValidDuration = true;
    });
  }

  void cancelOnLock() {
    isCurrentlyRecording = false;
    isValidDuration = false;
    _recordingController.stopRecording();
    cameraController.stopRecording();

    setState(() {
      isLocked = false;
      lastRecord = null;
      lockObs = 0;
    });
  }

  void sendOnLock() {
    setState(() {
      sendRecording = true;
      isCurrentlyRecording = false;
      isValidDuration = _recordingController.isRecordingValid;
      lastRecord = _recordingController.stopRecording();
      cameraController.stopRecording();
      isLocked = false;
      lockObs = 0;
    });
  }

  void sendOnDone() {
    sendRecording = true;
    recording.add(_videoPath!);
    _videoPath = null;
    isLocked = false;
    lockObs = 0;

    setState(() {});
  }

  void cancelOnDone() {
    setState(() {
      _videoPath = null;
      isLocked = false;
      lastRecord = null;
      lockObs = 0;
    });
  }

  void stopRecording() {
    isCurrentlyRecording = false;
    isValidDuration = _recordingController.isRecordingValid;
    lastRecord = _recordingController.stopRecording();
    cameraController.stopRecording();
    lockObs = 0;
    setState(() {});
  }

  List<String> recording = [];
  bool sendRecording = false;
  int currentlyTapped = -1;

  double lockObs = 0;
  @override
  Widget build(BuildContext context) {
    if (_videoPath != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular video player
              HoleWidget(
                child: MiniVideoPlayer(
                  filePath: _videoPath!,
                  autoPlay: true,
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        backgroundColor: Colors.white,
        bottomNavigationBar: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () {
                    cancelOnDone();
                  },
                  icon: const Icon(Icons.delete)),
              Text(
                "${lastRecord?.round()}s",
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
              CircleAvatar(
                backgroundColor: const Color(0xFFFDD400),
                child: IconButton(
                  onPressed: () {
                    sendOnDone();
                  },
                  icon: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }

    // Show the camera interface
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recording.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    child: SizedBox(
                      // color: Colors.black,
                      height: currentlyTapped == index ? 470 : 350,
                      // width: MediaQuery.of(context).size.width * .8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          HoleWidget(
                            radius: currentlyTapped == index ? 150 : 100,
                            child: MiniVideoPlayer(filePath: recording[index]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          IgnorePointer(
            ignoring:
                !isCurrentlyRecording, // Disable interaction when not recording
            child: Opacity(
              opacity: isCurrentlyRecording ? 1.0 : 0.0,
              // Fully visible if true, hidden if false
              child: OverlayScreen(
                isRecording: isCurrentlyRecording,
                recordingController: _recordingController,
                isValidDuration: isValidDuration,
                cameraController: cameraController,
                lockObs: lockObs,
                isLocked: isLocked,
                onDone: (String path) {
                  if (!sendRecording) {
                    _videoPath = path;
                    setState(() {});
                  } else {
                    recording.add(path);
                    sendRecording = false;
                    setState(() {});
                  }
                },
              ),
            ),
          ),
        ],
      ),
      bottomSheet: BottomAppBar(
        height: 100,
        color: Colors.white,
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 1.0),
          child: !isLocked
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Attachment Icon
                    Expanded(
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            key: ValueKey(false),
                            duration: const Duration(milliseconds: 500),
                            left: isCurrentlyRecording
                                ? -MediaQuery.of(context).size.width
                                : 0,
                            right: isCurrentlyRecording
                                ? MediaQuery.of(context).size.width
                                : 0,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.attach_file),
                                  onPressed: () {
                                    // Handle attachment action
                                  },
                                ),

                                // Comment Input Field
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Write comment",
                                      hintStyle:
                                          const TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 10.0, horizontal: 12.0),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                            Icons.emoji_emotions_outlined),
                                        onPressed: () {
                                          // Handle emoji picker
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedPositioned(
                            key: ValueKey(true),
                            duration: const Duration(milliseconds: 500),
                            left: isCurrentlyRecording
                                ? 0
                                : MediaQuery.of(context).size.width,
                            right: isCurrentlyRecording
                                ? 0
                                : -MediaQuery.of(context).size.width,
                            child: Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ValueListenableBuilder<double>(
                                    valueListenable:
                                        _recordingController.recordingDuration,
                                    builder: (context, duration, child) {
                                      return Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/recorder.svg',
                                            width: 20,
                                            height: 20,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            formatDuration(duration.round()),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  if (!isLocked)
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Colors.black,
                                        ),
                                        Text(
                                          "Slide to cancel",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Emoji Icon
                    Container(
                      width: 10,
                    ),
                    // Camera Icon

                    GestureDetector(
                      onLongPressStart: (_) async {
//                         bool can =
//                             await Vibration.hasCustomVibrationsSupport() ??
//                                 false;
// =                        Vibration.vibrate(
//                           pattern: [500, 1000, 500, 2000, 500, 3000, 500, 500],
//                           intensities: [0, 128, 0, 255, 0, 64, 0, 255],
//                         );
//                         if (can) {
//                           Vibration.vibrate();
//                         }
                        startRecording();
                      },
                      onLongPressUp: () {
                        if (!isLocked) {
                          stopRecording();
                        }
                        Future.delayed(const Duration(milliseconds: 300), () {
                          setState(() {});
                        });
                      },
                      onLongPressMoveUpdate: (details) {
                        print(details.localPosition.direction);
                        if (details.localPosition.direction > 2) {
                          //HORizontal
                          cancelRecording();
                        }

                        if (details.localPosition.direction < -1.2) {
                          lockRecording();
                          //VERti
                        } else {
                          setState(() {
                            lockObs = details.localPosition.direction;
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                                scale: animation, child: child);
                          },
                          child: Icon(
                            key: ValueKey<bool>(isCurrentlyRecording),
                            isCurrentlyRecording
                                ? Icons.stop
                                : Icons.camera_alt_outlined,
                            size: 30,
                            color: isCurrentlyRecording
                                ? Colors.red
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),

                    // Microphone Icon
                    AnimatedOpacity(
                      opacity: isCurrentlyRecording ? 0 : 1,
                      duration: const Duration(milliseconds: 500),
                      child: IconButton(
                        icon: const Icon(Icons.mic_none_outlined),
                        onPressed: () {
                          // Handle voice recording
                        },
                      ),
                    )
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        cancelOnLock();
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.black,
                      ),
                    ),
                    ValueListenableBuilder<double>(
                      valueListenable: _recordingController.recordingDuration,
                      builder: (context, duration, child) {
                        return Row(
                          children: [
                            SvgPicture.asset(
                              'assets/recorder.svg',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              formatDuration(duration.round()),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        sendOnLock();
                      },
                      child: const CircleAvatar(
                        backgroundColor: Color(0xFFFDD400),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
