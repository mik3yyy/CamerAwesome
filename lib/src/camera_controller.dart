// File: lib/src/camera_controller.dart

import 'dart:async';
import 'package:camerawesome/src/orchestrator/camera_context.dart';
import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:camerawesome/src/orchestrator/states/video_camera_state.dart';
import 'package:camerawesome/src/orchestrator/states/video_camera_recording_state.dart';
import 'package:camerawesome/src/orchestrator/models/camera_flashes.dart';
import 'package:camerawesome/src/orchestrator/models/sensors.dart';

class CameraController {
  late CameraContext _cameraContext;
  late StreamSubscription<CameraState> _stateSubscription;
  CameraState? _currentState;

  // Completer to ensure the controller is initialized before use
  final Completer<void> _initCompleter = Completer<void>();

  /// Initialize the controller with the CameraContext
  void init(CameraContext cameraContext) {
    _cameraContext = cameraContext;
    print("CameraController: Initializing with CameraContext.");
    _stateSubscription = _cameraContext.state$.listen((state) {
      print("CameraController: Received CameraState: $state");
      _currentState = state;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
        print("CameraController: Initialization complete.");
      }
    }, onError: (error) {
      print("CameraController: Error in state stream: $error");
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(error);
      }
    });
  }

  /// Dispose the controller and its subscriptions
  void dispose() {
    print("CameraController: Disposing controller.");
    _stateSubscription.cancel();
  }

  /// Ensure the controller is initialized before performing actions
  Future<void> _ensureInitialized() async {
    print("CameraController: Ensuring initialization.");
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
    print("CameraController: Initialization ensured.");
  }

  /// Start video recording
  Future<void> startRecording() async {
    await _ensureInitialized();
    if (_currentState is VideoCameraState) {
      print("CameraController: Starting video recording.");
      await (_currentState as VideoCameraState).startRecording();
    } else {
      throw Exception('Camera is not in Video mode.');
    }
  }

  /// Stop video recording
  Future<void> stopRecording() async {
    await _ensureInitialized();
    if (_currentState is VideoRecordingCameraState) {
      print("CameraController: Stopping video recording.");
      await (_currentState as VideoRecordingCameraState).stopRecording();
    } else {
      throw Exception('Camera is not recording.');
    }
  }

  /// Switch between front and back cameras
  Future<void> switchCamera() async {
    await _ensureInitialized();
    print("CameraController: Switching camera.");
    await _currentState?.switchCameraSensor();
  }

  /// Toggle flash mode between on and off
  Future<void> toggleFlash() async {
    await _ensureInitialized();

    _currentState!.sensorConfig.switchCameraFlash();
  }

  /// Accessor for current flash mode
  FlashMode get currentFlashMode {
    if (!_initCompleter.isCompleted) {
      print(
          "CameraController: currentFlashMode accessed before initialization. Returning default FlashMode.off.");
      return FlashMode.none;
    }
    return _currentState?.sensorConfig.flashMode ?? FlashMode.none;
  }

  /// Accessor for current CameraState
  CameraState? get currentCameraState => _currentState;
}
