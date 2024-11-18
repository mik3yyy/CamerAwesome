import 'dart:async';
import 'package:flutter/foundation.dart';

class RecordingController {
  Timer? _timer;
  final ValueNotifier<double> recordingDuration = ValueNotifier(0.00);
  bool _isRecordingValid = false;

  Function()? onDurationExceed; // Callback for duration limit
  double maxTime = 30;
  void startRecording() {
    recordingDuration.value = 0; // Reset duration
    _isRecordingValid = false; // Reset validity
    _timer?.cancel(); // Cancel existing timer

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      recordingDuration.value += 00.01;
      if (recordingDuration.value > 1) {
        _isRecordingValid = true;
      }

      // Trigger the callback if duration exceeds a limit
      if (recordingDuration.value > maxTime.toDouble() &&
          onDurationExceed != null) {
        onDurationExceed!();
      }
    });
  }

  double stopRecording() {
    _timer?.cancel();
    final duration = recordingDuration.value;
    _reset();
    return duration;
  }

  bool get isRecordingValid => _isRecordingValid;

  void _reset() {
    recordingDuration.value = 0;
    _isRecordingValid = false;
    _timer = null;
  }
}
