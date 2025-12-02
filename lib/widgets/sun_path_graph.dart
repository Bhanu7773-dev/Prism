import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SunPathGraph extends StatelessWidget {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime currentTime;

  const SunPathGraph({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.currentTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sun Path",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          height: 150,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: CustomPaint(
            painter: _SunPathPainter(
              sunrise: sunrise,
              sunset: sunset,
              currentTime: currentTime,
            ),
          ),
        ),
      ],
    );
  }
}

class _SunPathPainter extends CustomPainter {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime currentTime;

  _SunPathPainter({
    required this.sunrise,
    required this.sunset,
    required this.currentTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;

    // We want the arc to take up most of the height, leaving space for text at bottom
    final arcHeight = height * 0.7;
    final bottomY = height * 0.8;

    // 1. Draw the Arc Track (Dashed or Solid transparent)
    final path = Path();
    // Parabola: y = 4 * h * x * (1 - x)
    // We map x from 0 to width
    // We map y from bottomY to (bottomY - arcHeight)

    path.moveTo(0, bottomY);
    for (double x = 0; x <= width; x++) {
      final normalizedX = x / width;
      // Parabola equation: y = -4 * (x - 0.5)^2 + 1  (peaks at 1 when x=0.5)
      // Simplified: y = 4 * x * (1 - x)
      final normalizedY = 4 * normalizedX * (1 - normalizedX);
      final y = bottomY - (normalizedY * arcHeight);
      path.lineTo(x, y);
    }

    paint.color = Colors.white.withOpacity(0.2);
    // Draw dashed effect manually or just solid for now
    canvas.drawPath(path, paint);

    // 2. Calculate Sun Position
    double progress = 0.0;
    if (currentTime.isAfter(sunrise) && currentTime.isBefore(sunset)) {
      final totalDuration = sunset.difference(sunrise).inMinutes;
      if (totalDuration > 0) {
        final elapsed = currentTime.difference(sunrise).inMinutes;
        progress = elapsed / totalDuration;
      }
    } else if (currentTime.isAfter(sunset)) {
      progress = 1.0;
    } else {
      progress = 0.0;
    }

    // Clamp progress
    progress = progress.clamp(0.0, 1.0);

    // 3. Draw Active Path (Sunrise to Current)
    final activePath = Path();
    activePath.moveTo(0, bottomY);
    for (double x = 0; x <= width * progress; x++) {
      final normalizedX = x / width;
      final normalizedY = 4 * normalizedX * (1 - normalizedX);
      final y = bottomY - (normalizedY * arcHeight);
      activePath.lineTo(x, y);
    }

    paint.color = Colors.amber;
    paint.shader = LinearGradient(
      colors: [Colors.orange.shade300, Colors.yellow.shade300],
    ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(activePath, paint..style = PaintingStyle.stroke);

    // 4. Draw Sun Icon
    final sunX = width * progress;
    final sunNormalizedY = 4 * progress * (1 - progress);
    final sunY = bottomY - (sunNormalizedY * arcHeight);

    // Sun Glow
    final glowPaint = Paint()
      ..color = Colors.orange.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(sunX, sunY), 12, glowPaint);

    // Sun Core
    final sunPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(sunX, sunY), 6, sunPaint);

    // 5. Draw Labels
    final textStyle = GoogleFonts.outfit(
      color: Colors.white.withOpacity(0.7),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    _drawText(
      canvas,
      DateFormat('h:mm a').format(sunrise),
      Offset(0, bottomY + 10),
      textStyle,
      TextAlign.left,
    );

    _drawText(
      canvas,
      DateFormat('h:mm a').format(sunset),
      Offset(width, bottomY + 10),
      textStyle,
      TextAlign.right,
    );

    // Current Time Label above Sun
    if (progress > 0 && progress < 1) {
      _drawText(
        canvas,
        DateFormat('h:mm a').format(currentTime),
        Offset(sunX, sunY - 25),
        textStyle.copyWith(color: Colors.white, fontSize: 10),
        ui.TextAlign.center,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
    ui.TextAlign align,
  ) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
      textAlign: align,
    );
    textPainter.layout();

    double dx = offset.dx;
    if (align == ui.TextAlign.center) {
      dx -= textPainter.width / 2;
    } else if (align == TextAlign.right) {
      dx -= textPainter.width;
    }

    textPainter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
