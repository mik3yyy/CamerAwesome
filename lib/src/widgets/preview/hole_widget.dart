import 'dart:math';

import 'dart:ui';

import 'package:flutter/material.dart';

class HoleWidget extends StatelessWidget {
  final Widget? child;
  final double? radius;

  const HoleWidget({required this.child, this.radius, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipPath(
        clipper: HoleClipper(radius: this.radius),
        child: Container(
          // width: 300,

          // height: 300,

          color: Colors.grey.withOpacity(0.5),

          child: child, // Foreground color
        ),
      ),
    );
  }
}

class HoleClipper extends CustomClipper<Path> {
  final double? radius;

  HoleClipper({super.reclip, this.radius});
  @override
  @override
  Path getClip(Size size) {
    final path = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2), // Center of the widget

        radius: radius ?? 175, // Radius of the circle
      )); // Makes the circle a "hole"

    return path;
  }

  @override
  bool shouldReclip(HoleClipper oldClipper) => false;
}

@override
void paint(Canvas canvas, Size size) {
  // Paint the background

  Paint backgroundPaint = Paint()..color = Colors.blue;

  // Draw a rectangle as the background

  canvas.drawRect(Offset.zero & size, backgroundPaint);

  // Create a circular hole in the middle

  Paint holePaint = Paint()
    ..blendMode = BlendMode.clear; // This makes the circle transparent

  double radius = 150; // Radius of the hole

  Offset center = Offset(size.width / 2, size.height / 2); // Center of the hole

  // Draw the hole

  canvas.drawCircle(center, radius, holePaint);
}
