import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:camerawesome/src/widgets/utils/awesome_circle_icon.dart';
import 'package:camerawesome/src/widgets/utils/awesome_oriented_widget.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

class AwesomeCameraSwitchButton extends StatelessWidget {
  final CameraState state;

  AwesomeCameraSwitchButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.cameraswitch, color: Colors.white),
      onPressed: () => state.switchCameraSensor(),
    );
  }
}
