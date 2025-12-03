import 'package:flutter/material.dart';

class ParallaxScenery extends StatelessWidget {
  final double height;
  final List<Color>? colors;
  final double parallaxOffset;

  const ParallaxScenery({
    super.key,
    this.height = 300,
    this.colors,
    this.parallaxOffset = 0,
  });

  static const _defaultColors = [
    Color(0xFF8FA3C0), // Back
    Color(0xFF5D7392), // Mid
    Color(0xFF2C3E50), // Front
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: MountainPainter(
            colors: colors ?? _defaultColors,
            parallaxOffset: parallaxOffset,
          ),
          size: Size.infinite,
          willChange: true,
          isComplex: false,
        ),
      ),
    );
  }
}

class MountainPainter extends CustomPainter {
  final List<Color> colors;
  final double parallaxOffset;

  MountainPainter({required this.colors, required this.parallaxOffset});

  // Static cached paint objects for better performance
  static final Paint _paintBack = Paint()..style = PaintingStyle.fill;
  static final Paint _paintMid = Paint()..style = PaintingStyle.fill;
  static final Paint _paintFront = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Get colors with fallbacks
    final backColor = colors.isNotEmpty ? colors[0] : const Color(0xFF8FA3C0);
    final midColor = colors.length > 1 ? colors[1] : const Color(0xFF5D7392);
    final frontColor = colors.length > 2 ? colors[2] : const Color(0xFF2C3E50);

    // Parallax offsets (slower for back, faster for front)
    final backOffset = parallaxOffset * 0.3;
    final midOffset = parallaxOffset * 0.6;
    final frontOffset = parallaxOffset * 1.0;

    // 1. Background Mountains (Tallest, Lightest, Slowest parallax)
    _paintBack.color = backColor;

    final pathBack = Path();
    pathBack.moveTo(0, height);
    pathBack.lineTo(0, height * 0.4);
    pathBack.quadraticBezierTo(
      width * 0.2 + backOffset,
      height * 0.2,
      width * 0.4 + backOffset,
      height * 0.45,
    );
    pathBack.quadraticBezierTo(
      width * 0.6 + backOffset,
      height * 0.6,
      width * 0.8 + backOffset,
      height * 0.3,
    );
    pathBack.lineTo(width, height * 0.5);
    pathBack.lineTo(width, height);
    pathBack.close();
    canvas.drawPath(pathBack, _paintBack);

    // 2. Midground Mountains (Medium Height, Medium parallax)
    _paintMid.color = midColor;

    final pathMid = Path();
    pathMid.moveTo(0, height);
    pathMid.lineTo(0, height * 0.6);
    pathMid.quadraticBezierTo(
      width * 0.15 + midOffset,
      height * 0.5,
      width * 0.35 + midOffset,
      height * 0.65,
    );
    pathMid.quadraticBezierTo(
      width * 0.6 + midOffset,
      height * 0.8,
      width * 0.85 + midOffset,
      height * 0.55,
    );
    pathMid.lineTo(width, height * 0.7);
    pathMid.lineTo(width, height);
    pathMid.close();
    canvas.drawPath(pathMid, _paintMid);

    // 3. Foreground Hills (Lowest, Darkest, Fastest parallax)
    _paintFront.color = frontColor;

    final pathFront = Path();
    pathFront.moveTo(0, height);
    pathFront.lineTo(0, height * 0.8);
    pathFront.quadraticBezierTo(
      width * 0.25 + frontOffset,
      height * 0.7,
      width * 0.5 + frontOffset,
      height * 0.85,
    );
    pathFront.quadraticBezierTo(
      width * 0.75 + frontOffset,
      height * 0.95,
      width + frontOffset,
      height * 0.8,
    );
    pathFront.lineTo(width, height);
    pathFront.close();
    canvas.drawPath(pathFront, _paintFront);
  }

  @override
  bool shouldRepaint(covariant MountainPainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.parallaxOffset != parallaxOffset;
  }
}
