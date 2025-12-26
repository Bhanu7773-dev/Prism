import 'dart:math';
import 'package:flutter/material.dart';
import '../services/wind_data_service.dart';

class WindParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final WindGrid? windGrid; // Now uses structured grid
  final Rect mapBounds;
  final Color color;

  WindParticlePainter({
    required this.particles,
    required this.windGrid,
    required this.mapBounds,
    this.color = const Color(0xFFFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (windGrid == null || windGrid!.isEmpty) return;

    // Cache grid props for speed
    final grid = windGrid!;
    final List<WindPoint> points = grid.points;
    final int w = grid.width;
    final int h = grid.height;
    final double latMin = grid.latMin;
    final double lonMin = grid.lonMin;
    final double latStep = grid.latStep;
    final double lonStep = grid.lonStep;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final speedScale = 0.25;

    for (var p in particles) {
      // Map Screen (x,y) -> Geo (lat,lon)
      double pLon = mapBounds.left + (p.x / size.width) * mapBounds.width;
      double pLat = mapBounds.top - (p.y / size.height) * mapBounds.height;

      // Fast Lookup (Bilinear Interpolation)
      // Normalized Grid Coordinates [0..5]
      // Note: grid lat starts at latMin (South) and goes UP (Step > 0)?
      // Our loop was: latOffset = start + i*step. Start is neg, Step is pos.
      // So i=0 is latMin. i increases North.

      double gx = (pLon - lonMin) / lonStep;
      double gy = (pLat - latMin) / latStep; // Lat increases upwards?

      // Safety Clamp
      if (gx < 0) gx = 0;
      if (gx > w - 1.001) gx = w - 1.001;
      if (gy < 0) gy = 0;
      if (gy > h - 1.001) gy = h - 1.001;

      // Indices
      int i = gy.floor(); // Row (Lat)
      int j = gx.floor(); // Col (Lon)

      // Fractions
      double fy = gy - i;
      double fx = gx - j;

      // Get 4 Neighbors
      // Points list is row-major: index = i * width + j
      int idx00 = i * w + j;
      int idx01 = i * w + (j + 1);
      int idx10 = (i + 1) * w + j;
      int idx11 = (i + 1) * w + (j + 1);

      WindPoint p00 = points[idx00];
      WindPoint p01 = points[idx01];
      WindPoint p10 = points[idx10];
      WindPoint p11 = points[idx11];

      // Interpolate U
      double uBot = p00.u * (1 - fx) + p01.u * fx;
      double uTop = p10.u * (1 - fx) + p11.u * fx;
      double u = uBot * (1 - fy) + uTop * fy;

      // Interpolate V
      double vBot = p00.v * (1 - fx) + p01.v * fx;
      double vTop = p10.v * (1 - fx) + p11.v * fx;
      double v = vBot * (1 - fy) + vTop * fy;

      // Move
      double dx = u * speedScale * p.speedVar;
      double dy = -v * speedScale * p.speedVar;

      p.x += dx;
      p.y += dy;
      p.age++;

      p.history.add(Offset(p.x, p.y));
      if (p.history.length > 15) p.history.removeAt(0);

      // Wrap
      bool outOfBounds = false;
      if (p.x < 0) {
        p.x += size.width;
        outOfBounds = true;
      }
      if (p.x > size.width) {
        p.x -= size.width;
        outOfBounds = true;
      }
      if (p.y < 0) {
        p.y += size.height;
        outOfBounds = true;
      }
      if (p.y > size.height) {
        p.y -= size.height;
        outOfBounds = true;
      }

      if (outOfBounds || p.age > p.life) {
        _resetParticle(p, size);
        continue;
      }

      // Draw
      if (p.history.length > 1) {
        double opacity = 0.5;
        if (p.age < 10) opacity *= (p.age / 10);
        if (p.age > p.life - 10) opacity *= ((p.life - p.age) / 10);

        paint.color = color.withOpacity(opacity.clamp(0.0, 0.5));

        final path = Path();
        path.moveTo(p.history.first.dx, p.history.first.dy);
        for (int k = 1; k < p.history.length; k++) {
          path.lineTo(p.history[k].dx, p.history[k].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  void _resetParticle(Particle p, Size size) {
    p.x = Random().nextDouble() * size.width;
    p.y = Random().nextDouble() * size.height;
    p.age = 0;
    p.life = 50 + Random().nextInt(100);
    p.speedVar = 0.8 + (Random().nextDouble() * 0.4);
    p.history.clear();
    p.history.add(Offset(p.x, p.y));
  }

  @override
  bool shouldRepaint(covariant WindParticlePainter oldDelegate) => true;
}

class Particle {
  double x = 0;
  double y = 0;
  double speedVar = 1.0;
  int age = 0;
  int life = 100;
  final List<Offset> history = [];
}
