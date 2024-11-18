// ignore_for_file: library_private_types_in_public_api

import 'package:camerawesome/src/orchestrator/analysis/analysis_controller.dart';
import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AwesomeCaptureButton extends StatefulWidget {
  final CameraState state;

  const AwesomeCaptureButton({
    super.key,
    required this.state,
  });

  @override
  _AwesomeCaptureButtonState createState() => _AwesomeCaptureButtonState();
}

class _AwesomeCaptureButtonState extends State<AwesomeCaptureButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late double _scale;
  final Duration _duration = const Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: _duration,
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    // Dispose of the AnimationController to free up resources
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state is AnalysisController) {
      return Container();
    }
    _scale = 1 - _animationController.value;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: SizedBox(
        key: const ValueKey('cameraButton'),
        height: 80,
        width: 80,
        child: Transform.scale(
          scale: _scale,
          child: CustomPaint(
            painter: widget.state.when(
              onPhotoMode: (_) => CameraButtonPainter(),
              onPreparingCamera: (_) => CameraButtonPainter(),
              onVideoMode: (_) => VideoButtonPainter(),
              onVideoRecordingMode: (_) =>
                  VideoButtonPainter(isRecording: true),
            ),
          ),
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    // Ensure reverse is called only if the controller is still active
    Future.delayed(_duration, () {
      if (mounted && _animationController.isAnimating) {
        _animationController.reverse();
      }
    });

    _handleTap();
  }

  void _onTapCancel() {
    // Ensure reverse is called only if the controller is still active
    if (_animationController.isAnimating) {
      _animationController.reverse();
    }
  }

  void _handleTap() {
    widget.state.when(
      onPhotoMode: (photoState) {
        photoState.takePhoto();
      },
      onVideoMode: (videoState) {
        videoState.startRecording();
      },
      onVideoRecordingMode: (videoState) {
        videoState.stopRecording();
      },
      onPreparingCamera: (_) {},
    );
  }
}

class CameraButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var bgPainter = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    var radius = size.width / 2;
    var center = Offset(size.width / 2, size.height / 2);
    bgPainter.color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(center, radius, bgPainter);

    bgPainter.color = Colors.white;
    canvas.drawCircle(center, radius - 8, bgPainter);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class VideoButtonPainter extends CustomPainter {
  final bool isRecording;

  VideoButtonPainter({this.isRecording = false});

  @override
  void paint(Canvas canvas, Size size) {
    var bgPainter = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    var radius = size.width / 2;
    var center = Offset(size.width / 2, size.height / 2);
    bgPainter.color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(center, radius, bgPainter);

    if (isRecording) {
      bgPainter.color = Colors.red;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            17,
            17,
            size.width - (17 * 2),
            size.height - (17 * 2),
          ),
          const Radius.circular(12.0),
        ),
        bgPainter,
      );
    } else {
      bgPainter.color = Colors.red;
      canvas.drawCircle(center, radius - 8, bgPainter);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
