import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CelestialPathGraph extends StatefulWidget {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime currentTime;
  final int timezoneOffset; // in seconds

  const CelestialPathGraph({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.currentTime,
    this.timezoneOffset = 0,
  });

  @override
  State<CelestialPathGraph> createState() => _CelestialPathGraphState();
}

class _CelestialPathGraphState extends State<CelestialPathGraph> {
  Timer? _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.currentTime;
    // Update every second for smooth animation
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          // Calculate current time for the city's timezone
          // Add offset to UTC then create non-UTC DateTime so .hour/.minute are local values
          final shifted = DateTime.now().toUtc().add(
            Duration(seconds: widget.timezoneOffset),
          );
          _currentTime = DateTime(
            shifted.year,
            shifted.month,
            shifted.day,
            shifted.hour,
            shifted.minute,
            shifted.second,
          );
        });
      }
    });
  }

  @override
  void didUpdateWidget(CelestialPathGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update time when widget rebuilds with new data
    if (oldWidget.timezoneOffset != widget.timezoneOffset) {
      _currentTime = widget.currentTime;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isNightTime {
    // It's night if current time is BEFORE sunrise OR AFTER sunset
    // Compare using minutes since midnight for clarity
    final nowMin = _currentTime.hour * 60 + _currentTime.minute;
    final sunriseMin = widget.sunrise.hour * 60 + widget.sunrise.minute;
    final sunsetMin = widget.sunset.hour * 60 + widget.sunset.minute;

    return nowMin < sunriseMin || nowMin > sunsetMin;
  }

  @override
  Widget build(BuildContext context) {
    final isNight = _isNightTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isNight ? "Moon Path" : "Sun Path",
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
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _CelestialPathPainter(
                sunrise: widget.sunrise,
                sunset: widget.sunset,
                currentTime: _currentTime,
                isNight: isNight,
              ),
              willChange: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _CelestialPathPainter extends CustomPainter {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime currentTime;
  final bool isNight;

  // Cached paints for performance
  static final Paint _trackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  
  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  
  static final Paint _moonPaint = Paint();
  static final Paint _shadowPaint = Paint();
  static final Paint _sunGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _sunCorePaint = Paint();

  _CelestialPathPainter({
    required this.sunrise,
    required this.sunset,
    required this.currentTime,
    required this.isNight,
  });

  // Convert DateTime to minutes since midnight for easier comparison
  int _toMinutes(DateTime dt) => dt.hour * 60 + dt.minute;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final arcHeight = height * 0.7;
    final bottomY = height * 0.8;

    // 1. Draw the Arc Track
    final path = Path();
    path.moveTo(0, bottomY);
    for (double x = 0; x <= width; x++) {
      final normalizedX = x / width;
      final normalizedY = 4 * normalizedX * (1 - normalizedX);
      final y = bottomY - (normalizedY * arcHeight);
      path.lineTo(x, y);
    }

    _trackPaint.color = Colors.white.withOpacity(0.2);
    _trackPaint.shader = null;
    canvas.drawPath(path, _trackPaint);

    // 2. Calculate Position using minutes since midnight
    double progress = 0.0;

    final sunriseMin = _toMinutes(sunrise);
    final sunsetMin = _toMinutes(sunset);
    final currentMin = _toMinutes(currentTime);

    if (isNight) {
      final nightDuration = (24 * 60 - sunsetMin) + sunriseMin;

      int elapsedNight;
      if (currentMin >= sunsetMin) {
        elapsedNight = currentMin - sunsetMin;
      } else {
        elapsedNight = (24 * 60 - sunsetMin) + currentMin;
      }

      progress = nightDuration > 0 ? elapsedNight / nightDuration : 0.0;
    } else {
      final dayDuration = sunsetMin - sunriseMin;
      if (dayDuration > 0) {
        final elapsedDay = currentMin - sunriseMin;
        progress = elapsedDay / dayDuration;
      }
    }

    progress = progress.clamp(0.0, 1.0);

    // 3. Draw Active Path
    final activePath = Path();
    activePath.moveTo(0, bottomY);
    for (double x = 0; x <= width * progress; x++) {
      final normalizedX = x / width;
      final normalizedY = 4 * normalizedX * (1 - normalizedX);
      final y = bottomY - (normalizedY * arcHeight);
      activePath.lineTo(x, y);
    }

    // Different colors for day/night
    if (isNight) {
      _trackPaint.shader = LinearGradient(
        colors: [Colors.indigo.shade300, Colors.blue.shade200],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    } else {
      _trackPaint.shader = LinearGradient(
        colors: [Colors.orange.shade300, Colors.yellow.shade300],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    }

    canvas.drawPath(activePath, _trackPaint..style = PaintingStyle.stroke);

    // 4. Draw Celestial Body (Sun or Moon)
    final celestialX = width * progress;
    final celestialNormalizedY = 4 * progress * (1 - progress);
    final celestialY = bottomY - (celestialNormalizedY * arcHeight);

    if (isNight) {
      // Moon Glow - subtle silver glow
      _glowPaint.color = Colors.white.withOpacity(0.3);
      canvas.drawCircle(Offset(celestialX, celestialY), 10, _glowPaint);

      // Draw crescent moon using clipping
      canvas.save();

      // Clip to the moon circle area
      final moonPath = Path()
        ..addOval(
          Rect.fromCircle(center: Offset(celestialX, celestialY), radius: 7),
        );
      canvas.clipPath(moonPath);

      // Moon base (white circle)
      _moonPaint.color = Colors.white;
      canvas.drawCircle(Offset(celestialX, celestialY), 7, _moonPaint);

      // Shadow circle (offset to create crescent) - clipped to moon bounds
      _shadowPaint.color = const Color(0xFF1a1a2e);
      canvas.drawCircle(Offset(celestialX + 4, celestialY - 1), 6, _shadowPaint);

      canvas.restore();
    } else {
      // Sun Glow
      _sunGlowPaint.color = Colors.orange.withOpacity(0.5);
      canvas.drawCircle(Offset(celestialX, celestialY), 12, _sunGlowPaint);

      // Sun Core
      _sunCorePaint.color = Colors.white;
      canvas.drawCircle(Offset(celestialX, celestialY), 6, _sunCorePaint);
    }

    // 5. Draw Labels
    final textStyle = GoogleFonts.outfit(
      color: Colors.white.withOpacity(0.7),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    // Start and end labels
    String startLabel;
    String endLabel;

    // Format time manually to avoid DateFormat applying device timezone
    String formatTime(DateTime dt) {
      final hour = dt.hour;
      final minute = dt.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    if (isNight) {
      startLabel = "Sunset ${formatTime(sunset)}";
      endLabel = "Sunrise ${formatTime(sunrise)}";
    } else {
      startLabel = formatTime(sunrise);
      endLabel = formatTime(sunset);
    }

    _drawText(
      canvas,
      startLabel,
      Offset(0, bottomY + 10),
      textStyle.copyWith(fontSize: 10),
      TextAlign.left,
    );

    _drawText(
      canvas,
      endLabel,
      Offset(width, bottomY + 10),
      textStyle.copyWith(fontSize: 10),
      TextAlign.right,
    );

    // Current Time Label above celestial body
    if (progress > 0.05 && progress < 0.95) {
      _drawText(
        canvas,
        formatTime(currentTime),
        Offset(celestialX, celestialY - 25),
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
