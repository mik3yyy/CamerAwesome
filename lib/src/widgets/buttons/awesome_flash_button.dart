import 'package:camerawesome/src/widgets/utils/awesome_circle_icon.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:flutter/material.dart';

import 'package:camerawesome/src/orchestrator/models/camera_flashes.dart';
import 'package:camerawesome/src/orchestrator/models/sensor_config.dart';
import 'package:camerawesome/src/orchestrator/states/camera_state.dart';
import 'package:camerawesome/src/widgets/utils/awesome_oriented_widget.dart';

class AwesomeFlashButton extends StatelessWidget {
  final CameraState state;

  AwesomeFlashButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorConfig>(
      stream: state.sensorConfig$,
      builder: (_, sensorConfigSnapshot) {
        if (!sensorConfigSnapshot.hasData) return const SizedBox.shrink();

        final sensorConfig = sensorConfigSnapshot.requireData;
        return StreamBuilder<FlashMode>(
          stream: sensorConfig.flashMode$,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            final flashMode = snapshot.requireData;
            IconData icon;
            switch (flashMode) {
              case FlashMode.none:
                icon = Icons.flash_off;
                break;
              case FlashMode.on:
                icon = Icons.flash_on;
                break;
              case FlashMode.auto:
                icon = Icons.flash_auto;
                break;
              case FlashMode.always:
                icon = Icons.flashlight_on;
                break;
            }
            return IconButton(
              icon: Icon(icon, color: Colors.white),
              onPressed: () => sensorConfig.switchCameraFlash(),
            );
          },
        );
      },
    );
  }
}
