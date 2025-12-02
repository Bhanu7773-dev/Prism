import 'package:flutter/material.dart';

class ParallaxScenery extends StatelessWidget {
  final double height;
  const ParallaxScenery({super.key, this.height = 300});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: MountainPainter(), size: Size.infinite),
    );
  }
}

class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Background Mountains (Tallest, Lightest)
    final paintBack = Paint()
      ..color =
          const Color(0xFF8FA3C0) // Muted Blue-Grey
      ..style = PaintingStyle.fill;

    final pathBack = Path();
    pathBack.moveTo(0, height);
    pathBack.lineTo(0, height * 0.4);
    pathBack.quadraticBezierTo(
      width * 0.2,
      height * 0.2,
      width * 0.4,
      height * 0.45,
    );
    pathBack.quadraticBezierTo(
      width * 0.6,
      height * 0.6,
      width * 0.8,
      height * 0.3,
    );
    pathBack.lineTo(width, height * 0.5);
    pathBack.lineTo(width, height);
    pathBack.close();
    canvas.drawPath(pathBack, paintBack);

    // 2. Midground Mountains (Medium Height, Medium Color)
    final paintMid = Paint()
      ..color =
          const Color(0xFF5D7392) // Darker Blue-Grey
      ..style = PaintingStyle.fill;

    final pathMid = Path();
    pathMid.moveTo(0, height);
    pathMid.lineTo(0, height * 0.6);
    pathMid.quadraticBezierTo(
      width * 0.15,
      height * 0.5,
      width * 0.35,
      height * 0.65,
    );
    pathMid.quadraticBezierTo(
      width * 0.6,
      height * 0.8,
      width * 0.85,
      height * 0.55,
    );
    pathMid.lineTo(width, height * 0.7);
    pathMid.lineTo(width, height);
    pathMid.close();
    canvas.drawPath(pathMid, paintMid);

    // 3. Foreground Hills (Lowest, Darkest)
    final paintFront = Paint()
      ..color =
          const Color(0xFF2C3E50) // Dark Slate
      ..style = PaintingStyle.fill;

    final pathFront = Path();
    pathFront.moveTo(0, height);
    pathFront.lineTo(0, height * 0.8);
    pathFront.quadraticBezierTo(
      width * 0.25,
      height * 0.7,
      width * 0.5,
      height * 0.85,
    );
    pathFront.quadraticBezierTo(
      width * 0.75,
      height * 0.95,
      width,
      height * 0.8,
    );
    pathFront.lineTo(width, height);
    pathFront.close();
    canvas.drawPath(pathFront, paintFront);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
