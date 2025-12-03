import 'dart:math';
import 'package:flutter/material.dart';

/// Rain particle data
class RainDrop {
  double x;
  double y;
  double speed;
  double length;
  double opacity;
  double windOffset; // For wind effect
  int layer; // For parallax (0=back, 1=mid, 2=front)

  RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.opacity,
    this.windOffset = 0,
    this.layer = 1,
  });
}

/// Snow particle data
class Snowflake {
  double x;
  double y;
  double speed;
  double size;
  double wobble;
  double wobbleSpeed;
  double opacity;
  double windOffset;
  int layer;

  Snowflake({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.wobble,
    required this.wobbleSpeed,
    required this.opacity,
    this.windOffset = 0,
    this.layer = 1,
  });
}

/// Star particle data
class Star {
  double x;
  double y;
  double size;
  double baseOpacity;
  double twinkleSpeed;
  double twinklePhase;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.baseOpacity,
    required this.twinkleSpeed,
    required this.twinklePhase,
  });
}

/// Dust particle data
class DustParticle {
  double x;
  double y;
  double size;
  double opacity;
  double speedX;
  double speedY;
  double rotation;

  DustParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedX,
    required this.speedY,
    required this.rotation,
  });
}

/// Hail particle data
class HailStone {
  double x;
  double y;
  double size;
  double speedY;
  double speedX;
  double opacity;
  double rotation;
  double rotationSpeed;

  HailStone({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.opacity,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// Cloud data
class CloudLayer {
  double x;
  double y;
  double width;
  double height;
  double speed;
  double opacity;

  CloudLayer({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
    required this.opacity,
  });
}

/// Condensation droplet data
class CondensationDrop {
  double x;
  double y;
  double size;
  double opacity;
  double drip; // How much it's dripping down

  CondensationDrop({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.drip,
  });
}

/// Rain effect widget - optimized
class RainEffect extends StatefulWidget {
  final double intensity; // 0.0 to 1.0
  final bool isThunderstorm;
  final bool isPaused;

  const RainEffect({
    super.key,
    this.intensity = 0.5,
    this.isThunderstorm = false,
    this.isPaused = false,
  });

  @override
  State<RainEffect> createState() => _RainEffectState();
}

class _RainEffectState extends State<RainEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<RainDrop> _drops = [];
  final Random _random = Random();
  double _lightningOpacity = 0.0;
  int _framesSinceLightning = 0;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }

    _controller.addListener(_updateDrops);
  }

  @override
  void didUpdateWidget(RainEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  void _initDrops(Size size) {
    if (_drops.isEmpty && size.width > 0) {
      // Reduced count for performance (was 100)
      final count = (50 * widget.intensity).toInt().clamp(20, 60);
      for (var i = 0; i < count; i++) {
        _drops.add(_createDrop(size, randomY: true));
      }
      _lastSize = size;
    }
  }

  RainDrop _createDrop(Size size, {bool randomY = false}) {
    return RainDrop(
      x: _random.nextDouble() * size.width,
      y: randomY ? _random.nextDouble() * size.height : -20,
      speed: 10 + _random.nextDouble() * 10,
      length: 15 + _random.nextDouble() * 20,
      opacity: 0.3 + _random.nextDouble() * 0.4,
    );
  }

  void _updateDrops() {
    if (!mounted || _lastSize == null) return;

    final size = _lastSize!;

    for (var drop in _drops) {
      drop.y += drop.speed;
      drop.x += 1.5; // Slight wind

      if (drop.y > size.height) {
        drop.y = -drop.length;
        drop.x = _random.nextDouble() * size.width;
      }
    }

    // Lightning effect for thunderstorms
    if (widget.isThunderstorm) {
      _framesSinceLightning++;
      if (_lightningOpacity > 0) {
        _lightningOpacity -= 0.15;
      }

      if (_framesSinceLightning > 120 && _random.nextDouble() < 0.02) {
        _lightningOpacity = 0.8 + _random.nextDouble() * 0.2;
        _framesSinceLightning = 0;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (_lastSize != size) {
            _drops.clear();
          }
          _initDrops(size);

          return Stack(
            children: [
              CustomPaint(
                size: size,
                painter: RainPainter(drops: _drops),
                willChange: true,
                isComplex: false,
              ),
              if (widget.isThunderstorm && _lightningOpacity > 0)
                Container(
                  color: Colors.white.withOpacity(_lightningOpacity * 0.3),
                ),
            ],
          );
        },
      ),
    );
  }
}

class RainPainter extends CustomPainter {
  final List<RainDrop> drops;
  
  // Cached paint for performance
  static final Paint _paint = Paint()
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;

  RainPainter({required this.drops});

  @override
  void paint(Canvas canvas, Size size) {
    for (var drop in drops) {
      _paint.color = Colors.white.withOpacity(drop.opacity * 0.6);

      canvas.drawLine(
        Offset(drop.x, drop.y),
        Offset(drop.x + 2, drop.y + drop.length),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(RainPainter oldDelegate) => true;
}

/// Snow effect widget - optimized for performance
class SnowEffect extends StatefulWidget {
  final double intensity; // 0.0 to 1.0
  final bool isPaused;

  const SnowEffect({super.key, this.intensity = 0.5, this.isPaused = false});

  @override
  State<SnowEffect> createState() => _SnowEffectState();
}

class _SnowEffectState extends State<SnowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Snowflake> _flakes = [];
  final Random _random = Random();
  Size? _lastSize;
  int _frameSkip = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }

    _controller.addListener(_updateFlakes);
  }

  @override
  void didUpdateWidget(SnowEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  void _initFlakes(Size size) {
    if (_flakes.isEmpty && size.width > 0) {
      // Increased count for better visual effect
      final count = (70 * widget.intensity).toInt().clamp(30, 80);
      for (var i = 0; i < count; i++) {
        _flakes.add(_createFlake(size, randomY: true));
      }
      _lastSize = size;
    }
  }

  Snowflake _createFlake(Size size, {bool randomY = false}) {
    return Snowflake(
      x: _random.nextDouble() * size.width,
      y: randomY ? _random.nextDouble() * size.height : -10,
      speed: 1.2 + _random.nextDouble() * 1.8,
      size: 3 + _random.nextDouble() * 5, // Slightly larger for detail
      wobble: _random.nextDouble() * pi * 2,
      wobbleSpeed: 0.015 + _random.nextDouble() * 0.02,
      opacity: 0.7 + _random.nextDouble() * 0.3,
    );
  }

  void _updateFlakes() {
    if (!mounted || _lastSize == null) return;

    // Skip every other frame for snow (it's slow anyway)
    _frameSkip++;
    if (_frameSkip < 2) return;
    _frameSkip = 0;

    final size = _lastSize!;

    // Update positions without setState - let CustomPaint handle it
    for (var flake in _flakes) {
      flake.y += flake.speed;
      flake.wobble += flake.wobbleSpeed;
      flake.x += sin(flake.wobble) * 0.4;

      if (flake.y > size.height) {
        flake.y = -flake.size;
        flake.x = _random.nextDouble() * size.width;
      }
    }

    // Trigger repaint
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (_lastSize != size) {
            _flakes.clear();
          }
          _initFlakes(size);

          return CustomPaint(
            size: size,
            painter: SnowPainter(flakes: _flakes),
            willChange: true,
            isComplex: false,
          );
        },
      ),
    );
  }
}

class SnowPainter extends CustomPainter {
  final List<Snowflake> flakes;
  
  // Cached paints for performance
  static final Paint _simplePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _armPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  static final Paint _branchPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..strokeCap = StrokeCap.round;
  static final Paint _detailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5
    ..strokeCap = StrokeCap.round;
  static final Paint _centerPaint = Paint()..style = PaintingStyle.fill;

  SnowPainter({required this.flakes});

  @override
  void paint(Canvas canvas, Size size) {
    // Bottom area where glass sheet starts (roughly bottom 40% of screen)
    final simplifyThreshold = size.height * 0.6;

    for (var flake in flakes) {
      if (flake.y > simplifyThreshold) {
        // Simple circle when near/over the glass sheet (performance)
        _simplePaint.color = Colors.white.withOpacity(flake.opacity);
        canvas.drawCircle(Offset(flake.x, flake.y), flake.size * 0.5, _simplePaint);
      } else {
        // Beautiful realistic snowflake in upper area
        _drawRealisticSnowflake(canvas, flake);
      }
    }
  }

  void _drawRealisticSnowflake(Canvas canvas, Snowflake flake) {
    canvas.save();
    canvas.translate(flake.x, flake.y);
    canvas.rotate(flake.wobble * 0.3); // Gentle rotation

    final s = flake.size; // Base size

    // Update paint colors for this flake
    _armPaint.color = Colors.white.withOpacity(flake.opacity);
    _branchPaint.color = Colors.white.withOpacity(flake.opacity * 0.9);
    _detailPaint.color = Colors.white.withOpacity(flake.opacity * 0.7);
    _centerPaint.color = Colors.white.withOpacity(flake.opacity);

    // Center dot (crystal core)
    canvas.drawCircle(Offset.zero, s * 0.12, _centerPaint);

    // Draw 6 main arms with dendrite branches
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3;

      canvas.save();
      canvas.rotate(angle);

      // Main arm (stem)
      canvas.drawLine(Offset.zero, Offset(s, 0), _armPaint);

      // Primary branches (at 60% and 80% of arm length)
      _drawBranch(canvas, s * 0.5, s * 0.45, _branchPaint, _detailPaint);
      _drawBranch(canvas, s * 0.75, s * 0.35, _branchPaint, _detailPaint);

      // Small tip branches at the end
      _drawTipBranches(canvas, s, s * 0.25, _branchPaint);

      // Tiny detail branches near base
      _drawSmallBranch(canvas, s * 0.3, s * 0.2, _detailPaint);

      canvas.restore();
    }

    canvas.restore();
  }

  // Draw a symmetric branch pair with sub-branches
  void _drawBranch(
    Canvas canvas,
    double position,
    double length,
    Paint branchPaint,
    Paint detailPaint,
  ) {
    final branchAngle = pi / 3; // 60 degrees

    // Upper branch
    canvas.drawLine(
      Offset(position, 0),
      Offset(position + cos(branchAngle) * length, -sin(branchAngle) * length),
      branchPaint,
    );

    // Lower branch (mirror)
    canvas.drawLine(
      Offset(position, 0),
      Offset(position + cos(branchAngle) * length, sin(branchAngle) * length),
      branchPaint,
    );

    // Sub-branches on upper branch
    final subPos = position + cos(branchAngle) * length * 0.6;
    final subPosY = -sin(branchAngle) * length * 0.6;
    final subLen = length * 0.4;

    canvas.drawLine(
      Offset(subPos, subPosY),
      Offset(subPos + subLen * 0.5, subPosY - subLen * 0.7),
      detailPaint,
    );

    // Sub-branches on lower branch (mirror)
    canvas.drawLine(
      Offset(subPos, -subPosY),
      Offset(subPos + subLen * 0.5, -subPosY + subLen * 0.7),
      detailPaint,
    );
  }

  // Draw tip branches at the end of main arm
  void _drawTipBranches(
    Canvas canvas,
    double position,
    double length,
    Paint paint,
  ) {
    final tipAngle = pi / 4; // 45 degrees

    canvas.drawLine(
      Offset(position, 0),
      Offset(position + cos(tipAngle) * length, -sin(tipAngle) * length),
      paint,
    );

    canvas.drawLine(
      Offset(position, 0),
      Offset(position + cos(tipAngle) * length, sin(tipAngle) * length),
      paint,
    );
  }

  // Draw small detail branch
  void _drawSmallBranch(
    Canvas canvas,
    double position,
    double length,
    Paint paint,
  ) {
    final angle = pi / 2.5;

    canvas.drawLine(
      Offset(position, 0),
      Offset(position + cos(angle) * length * 0.5, -sin(angle) * length),
      paint,
    );

    canvas.drawLine(
      Offset(position, 0),
      Offset(position + cos(angle) * length * 0.5, sin(angle) * length),
      paint,
    );
  }

  @override
  bool shouldRepaint(SnowPainter oldDelegate) => true;
}

/// Lightning bolt effect (standalone)
class LightningEffect extends StatefulWidget {
  final bool active;
  final bool isPaused;

  const LightningEffect({
    super.key,
    this.active = false,
    this.isPaused = false,
  });

  @override
  State<LightningEffect> createState() => _LightningEffectState();
}

class _LightningEffectState extends State<LightningEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  double _flashOpacity = 0.0;
  List<Offset>? _boltPoints;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }

    _controller.addListener(_update);
  }

  @override
  void didUpdateWidget(LightningEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  void _update() {
    if (!widget.active || !mounted) return;

    setState(() {
      _frameCount++;

      // Decay flash
      if (_flashOpacity > 0) {
        _flashOpacity -= 0.1;
      }

      // Random lightning strike every ~3-8 seconds
      if (_frameCount > 180 && _random.nextDouble() < 0.01) {
        _triggerLightning();
        _frameCount = 0;
      }
    });
  }

  void _triggerLightning() {
    final size = MediaQuery.of(context).size;
    _flashOpacity = 1.0;

    // Generate bolt path
    _boltPoints = _generateBolt(size);

    // Double strike effect
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _flashOpacity = 0.7);
      }
    });
  }

  List<Offset> _generateBolt(Size size) {
    final points = <Offset>[];
    final startX = size.width * (0.3 + _random.nextDouble() * 0.4);
    var x = startX;
    var y = 0.0;

    points.add(Offset(x, y));

    while (y < size.height * 0.6) {
      y += 20 + _random.nextDouble() * 40;
      x += (_random.nextDouble() - 0.5) * 60;
      points.add(Offset(x, y));
    }

    return points;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    return Stack(
      children: [
        // Screen flash
        if (_flashOpacity > 0)
          Container(color: Colors.white.withOpacity(_flashOpacity * 0.2)),
        // Lightning bolt
        if (_boltPoints != null && _flashOpacity > 0.3)
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: LightningPainter(
              points: _boltPoints!,
              opacity: _flashOpacity,
            ),
          ),
      ],
    );
  }
}

class LightningPainter extends CustomPainter {
  final List<Offset> points;
  final double opacity;

  LightningPainter({required this.points, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Glow effect
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.5)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, glowPaint);

    // Core bolt
    final boltPaint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, boltPaint);
  }

  @override
  bool shouldRepaint(LightningPainter oldDelegate) => true;
}

/// Frost/Ice crystal particle for very cold weather
class FrostParticle {
  double x;
  double y;
  double size;
  double opacity;
  double rotation;
  double rotationSpeed;
  double driftSpeed;

  FrostParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.rotationSpeed,
    required this.driftSpeed,
  });
}

/// Frost/Ice crystal effect for freezing temperatures - optimized
class FrostEffect extends StatefulWidget {
  final double intensity;
  final bool isPaused;

  const FrostEffect({super.key, this.intensity = 0.5, this.isPaused = false});

  @override
  State<FrostEffect> createState() => _FrostEffectState();
}

class _FrostEffectState extends State<FrostEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<FrostParticle> _particles = [];
  final Random _random = Random();
  Size? _lastSize;
  int _frameSkip = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }

    _controller.addListener(_updateParticles);
  }

  @override
  void didUpdateWidget(FrostEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  void _initParticles(Size size) {
    if (_particles.isEmpty && size.width > 0) {
      // Reduced count for performance (was 60)
      final count = (25 * widget.intensity).toInt().clamp(5, 30);
      for (var i = 0; i < count; i++) {
        _particles.add(_createParticle(size, randomY: true));
      }
      _lastSize = size;
    }
  }

  FrostParticle _createParticle(Size size, {bool randomY = false}) {
    return FrostParticle(
      x: _random.nextDouble() * size.width,
      y: randomY ? _random.nextDouble() * size.height : -10,
      size: 4 + _random.nextDouble() * 6, // Smaller
      opacity: 0.4 + _random.nextDouble() * 0.4,
      rotation: _random.nextDouble() * pi * 2,
      rotationSpeed: 0.01 + _random.nextDouble() * 0.015,
      driftSpeed: 0.3 + _random.nextDouble() * 0.5, // Slower
    );
  }

  void _updateParticles() {
    if (!mounted || _lastSize == null) return;

    // Skip frames for frost (very slow drift anyway)
    _frameSkip++;
    if (_frameSkip < 3) return;
    _frameSkip = 0;

    final size = _lastSize!;

    for (var p in _particles) {
      p.y += p.driftSpeed;
      p.x += sin(p.rotation) * 0.2;
      p.rotation += p.rotationSpeed;

      if (p.y > size.height) {
        p.y = -p.size;
        p.x = _random.nextDouble() * size.width;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (_lastSize != size) {
            _particles.clear();
          }
          _initParticles(size);

          return CustomPaint(
            size: size,
            painter: FrostPainter(particles: _particles),
            willChange: true,
            isComplex: false,
          );
        },
      ),
    );
  }
}

class FrostPainter extends CustomPainter {
  final List<FrostParticle> particles;
  
  // Cached paint for performance
  static final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  FrostPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      _paint.color = Colors.white.withOpacity(p.opacity);

      // Simplified 6-pointed star (no branches, no glow for performance)
      for (var i = 0; i < 6; i++) {
        final angle = i * pi / 3;
        final endX = cos(angle) * p.size;
        final endY = sin(angle) * p.size;
        canvas.drawLine(Offset.zero, Offset(endX, endY), _paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(FrostPainter oldDelegate) => true;
}

/// Mist/Fog effect for misty conditions
class MistEffect extends StatefulWidget {
  final double intensity;
  final bool isPaused;

  const MistEffect({super.key, this.intensity = 0.5, this.isPaused = false});

  @override
  State<MistEffect> createState() => _MistEffectState();
}

class _MistEffectState extends State<MistEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    if (!widget.isPaused) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MistEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: MistPainter(
            progress: _controller.value,
            intensity: widget.intensity,
          ),
        );
      },
    );
  }
}

class MistPainter extends CustomPainter {
  final double progress;
  final double intensity;

  MistPainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw multiple layers of fog with better visibility
    for (var i = 0; i < 5; i++) {
      final yOffset = size.height * (0.2 + i * 0.15);
      final xOffset = sin(progress * pi * 2 + i * 0.5) * 50;
      final opacity = (0.15 + i * 0.05) * intensity;

      final rect = Rect.fromLTWH(
        -100 + xOffset,
        yOffset - 80,
        size.width + 200,
        160,
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0),
            Colors.white.withOpacity(opacity),
            Colors.white.withOpacity(opacity),
            Colors.white.withOpacity(0),
          ],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(MistPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================
// NEW EFFECTS - Stars, Clouds, Dust, Hail, Wind, Heat, Frost Glass, Condensation
// ============================================================

/// Twinkling Stars Effect for clear night sky
class StarsEffect extends StatefulWidget {
  final double intensity;
  final bool isPaused;

  const StarsEffect({super.key, this.intensity = 0.5, this.isPaused = false});

  @override
  State<StarsEffect> createState() => _StarsEffectState();
}

class _StarsEffectState extends State<StarsEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Star> _stars = [];
  final Random _random = Random();
  int _frameSkip = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }

    _controller.addListener(_update);
  }

  @override
  void didUpdateWidget(StarsEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      widget.isPaused ? _controller.stop() : _controller.repeat();
    }
  }

  void _initStars(Size size) {
    if (_stars.isEmpty && size.width > 0) {
      final count = (60 * widget.intensity).toInt().clamp(30, 80);
      for (var i = 0; i < count; i++) {
        _stars.add(
          Star(
            x: _random.nextDouble() * size.width,
            y: _random.nextDouble() * size.height * 0.5, // Upper half only
            size: 1 + _random.nextDouble() * 2,
            baseOpacity: 0.3 + _random.nextDouble() * 0.7,
            twinkleSpeed: 0.02 + _random.nextDouble() * 0.05,
            twinklePhase: _random.nextDouble() * pi * 2,
          ),
        );
      }
    }
  }

  void _update() {
    if (!mounted) return;
    
    // Skip frames for stars (twinkle is slow)
    _frameSkip++;
    if (_frameSkip < 2) return;
    _frameSkip = 0;
    
    for (var star in _stars) {
      star.twinklePhase += star.twinkleSpeed;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          _initStars(size);
          return CustomPaint(
            size: size,
            painter: StarsPainter(stars: _stars),
          );
        },
      ),
    );
  }
}

class StarsPainter extends CustomPainter {
  final List<Star> stars;
  
  // Cached paints for performance
  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _corePaint = Paint()..style = PaintingStyle.fill;

  StarsPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      final twinkle = (sin(star.twinklePhase) + 1) / 2; // 0 to 1
      final opacity = star.baseOpacity * (0.3 + twinkle * 0.7);

      // Glow
      _glowPaint.color = Colors.white.withOpacity(opacity * 0.3);
      canvas.drawCircle(Offset(star.x, star.y), star.size * 2, _glowPaint);

      // Core
      _corePaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(star.x, star.y), star.size, _corePaint);
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) => true;
}

/// Moving Clouds Effect
class CloudsEffect extends StatefulWidget {
  final double intensity;
  final bool isPaused;
  final bool isDark; // For night clouds

  const CloudsEffect({
    super.key,
    this.intensity = 0.5,
    this.isPaused = false,
    this.isDark = false,
  });

  @override
  State<CloudsEffect> createState() => _CloudsEffectState();
}

class _CloudsEffectState extends State<CloudsEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<CloudLayer> _clouds = [];
  final Random _random = Random();
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }

    _controller.addListener(_update);
  }

  @override
  void didUpdateWidget(CloudsEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      widget.isPaused ? _controller.stop() : _controller.repeat();
    }
  }

  void _initClouds(Size size) {
    if (_clouds.isEmpty && size.width > 0) {
      final count = (5 * widget.intensity).toInt().clamp(3, 8);
      for (var i = 0; i < count; i++) {
        _clouds.add(
          CloudLayer(
            x: _random.nextDouble() * size.width * 1.5 - size.width * 0.25,
            y: _random.nextDouble() * size.height * 0.3,
            width: 100 + _random.nextDouble() * 150,
            height: 40 + _random.nextDouble() * 40,
            speed: 0.2 + _random.nextDouble() * 0.3,
            opacity: 0.1 + _random.nextDouble() * 0.2,
          ),
        );
      }
      _lastSize = size;
    }
  }

  void _update() {
    if (!mounted || _lastSize == null) return;
    final size = _lastSize!;

    for (var cloud in _clouds) {
      cloud.x += cloud.speed;
      if (cloud.x > size.width + cloud.width) {
        cloud.x = -cloud.width;
        cloud.y = _random.nextDouble() * size.height * 0.3;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (_lastSize != size) _clouds.clear();
          _initClouds(size);
          return CustomPaint(
            size: size,
            painter: CloudsPainter(clouds: _clouds, isDark: widget.isDark),
          );
        },
      ),
    );
  }
}

class CloudsPainter extends CustomPainter {
  final List<CloudLayer> clouds;
  final bool isDark;

  CloudsPainter({required this.clouds, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    for (var cloud in clouds) {
      final color = isDark ? Colors.grey.shade800 : Colors.white;
      final paint = Paint()
        ..color = color.withOpacity(cloud.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      // Draw cloud as overlapping ellipses
      final cx = cloud.x + cloud.width / 2;
      final cy = cloud.y + cloud.height / 2;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: cloud.width,
          height: cloud.height,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - cloud.width * 0.3, cy + 5),
          width: cloud.width * 0.6,
          height: cloud.height * 0.8,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + cloud.width * 0.3, cy + 5),
          width: cloud.width * 0.5,
          height: cloud.height * 0.7,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CloudsPainter oldDelegate) => true;
}

/// Dust/Sand Storm Effect
class DustStormEffect extends StatefulWidget {
  final double intensity;
  final bool isPaused;

  const DustStormEffect({
    super.key,
    this.intensity = 0.5,
    this.isPaused = false,
  });

  @override
  State<DustStormEffect> createState() => _DustStormEffectState();
}

class _DustStormEffectState extends State<DustStormEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<DustParticle> _particles = [];
  final Random _random = Random();
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }

    _controller.addListener(_update);
  }

  @override
  void didUpdateWidget(DustStormEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      widget.isPaused ? _controller.stop() : _controller.repeat();
    }
  }

  void _initParticles(Size size) {
    if (_particles.isEmpty && size.width > 0) {
      final count = (80 * widget.intensity).toInt().clamp(40, 100);
      for (var i = 0; i < count; i++) {
        _particles.add(_createParticle(size, randomX: true));
      }
      _lastSize = size;
    }
  }

  DustParticle _createParticle(Size size, {bool randomX = false}) {
    return DustParticle(
      x: randomX ? _random.nextDouble() * size.width : -10,
      y: _random.nextDouble() * size.height,
      size: 1 + _random.nextDouble() * 3,
      opacity: 0.2 + _random.nextDouble() * 0.4,
      speedX: 3 + _random.nextDouble() * 5,
      speedY: (_random.nextDouble() - 0.5) * 2,
      rotation: _random.nextDouble() * pi * 2,
    );
  }

  void _update() {
    if (!mounted || _lastSize == null) return;
    final size = _lastSize!;

    for (var p in _particles) {
      p.x += p.speedX;
      p.y += p.speedY;
      p.rotation += 0.1;

      if (p.x > size.width + 10) {
        p.x = -10;
        p.y = _random.nextDouble() * size.height;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Dust overlay tint
          Container(color: Colors.orange.withOpacity(0.1 * widget.intensity)),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              if (_lastSize != size) _particles.clear();
              _initParticles(size);
              return CustomPaint(
                size: size,
                painter: DustPainter(particles: _particles),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DustPainter extends CustomPainter {
  final List<DustParticle> particles;
  
  // Cached paint for performance
  static final Paint _paint = Paint()..style = PaintingStyle.fill;

  DustPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      _paint.color = Colors.orange.shade200.withOpacity(p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, _paint);
    }
  }

  @override
  bool shouldRepaint(DustPainter oldDelegate) => true;
}

/// Hail Effect - bouncing ice pellets
class HailEffect extends StatefulWidget {
  final double intensity;
  final bool isPaused;

  const HailEffect({super.key, this.intensity = 0.5, this.isPaused = false});

  @override
  State<HailEffect> createState() => _HailEffectState();
}

class _HailEffectState extends State<HailEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<HailStone> _stones = [];
  final Random _random = Random();
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }

    _controller.addListener(_update);
  }

  @override
  void didUpdateWidget(HailEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      widget.isPaused ? _controller.stop() : _controller.repeat();
    }
  }

  void _initStones(Size size) {
    if (_stones.isEmpty && size.width > 0) {
      final count = (30 * widget.intensity).toInt().clamp(15, 40);
      for (var i = 0; i < count; i++) {
        _stones.add(_createStone(size, randomY: true));
      }
      _lastSize = size;
    }
  }

  HailStone _createStone(Size size, {bool randomY = false}) {
    return HailStone(
      x: _random.nextDouble() * size.width,
      y: randomY ? _random.nextDouble() * size.height : -20,
      size: 3 + _random.nextDouble() * 5,
      speedY: 12 + _random.nextDouble() * 8,
      speedX: 2 + _random.nextDouble() * 3,
      opacity: 0.6 + _random.nextDouble() * 0.4,
      rotation: _random.nextDouble() * pi * 2,
      rotationSpeed: 0.1 + _random.nextDouble() * 0.2,
    );
  }

  void _update() {
    if (!mounted || _lastSize == null) return;
    final size = _lastSize!;

    for (var stone in _stones) {
      stone.y += stone.speedY;
      stone.x += stone.speedX;
      stone.rotation += stone.rotationSpeed;

      if (stone.y > size.height) {
        stone.y = -stone.size;
        stone.x = _random.nextDouble() * size.width;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (_lastSize != size) _stones.clear();
          _initStones(size);
          return CustomPaint(
            size: size,
            painter: HailPainter(stones: _stones),
          );
        },
      ),
    );
  }
}

class HailPainter extends CustomPainter {
  final List<HailStone> stones;
  
  // Cached paints for performance
  static final Paint _paint = Paint()..style = PaintingStyle.fill;
  static final Paint _highlightPaint = Paint()..style = PaintingStyle.fill;

  HailPainter({required this.stones});

  @override
  void paint(Canvas canvas, Size size) {
    for (var stone in stones) {
      canvas.save();
      canvas.translate(stone.x, stone.y);
      canvas.rotate(stone.rotation);

      // Ice pellet
      _paint.color = Colors.white.withOpacity(stone.opacity);

      // Draw irregular ice shape
      final path = Path();
      path.moveTo(0, -stone.size);
      path.lineTo(stone.size * 0.7, -stone.size * 0.3);
      path.lineTo(stone.size * 0.5, stone.size * 0.5);
      path.lineTo(-stone.size * 0.3, stone.size * 0.7);
      path.lineTo(-stone.size * 0.8, 0);
      path.close();

      canvas.drawPath(path, _paint);

      // Highlight
      _highlightPaint.color = Colors.white.withOpacity(stone.opacity * 0.5);
      canvas.drawCircle(
        Offset(-stone.size * 0.2, -stone.size * 0.2),
        stone.size * 0.2,
        _highlightPaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(HailPainter oldDelegate) => true;
}

/// Wind Streaks Effect
class WindStreaksEffect extends StatefulWidget {
  final double windSpeed; // m/s
  final bool isPaused;

  const WindStreaksEffect({
    super.key,
    required this.windSpeed,
    this.isPaused = false,
  });

  @override
  State<WindStreaksEffect> createState() => _WindStreaksEffectState();
}

class _WindStreaksEffectState extends State<WindStreaksEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _streaks = [];
  final Random _random = Random();
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }

    _controller.addListener(_update);
  }

  @override
  void didUpdateWidget(WindStreaksEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      widget.isPaused ? _controller.stop() : _controller.repeat();
    }
  }

  void _initStreaks(Size size) {
    if (_streaks.isEmpty && size.width > 0) {
      final count = (widget.windSpeed * 2).toInt().clamp(10, 30);
      for (var i = 0; i < count; i++) {
        _streaks.add(
          Offset(
            _random.nextDouble() * size.width,
            _random.nextDouble() * size.height,
          ),
        );
      }
      _lastSize = size;
    }
  }

  void _update() {
    if (!mounted || _lastSize == null) return;
    final size = _lastSize!;
    final speed = widget.windSpeed * 0.5;

    for (var i = 0; i < _streaks.length; i++) {
      var streak = _streaks[i];
      streak = Offset(streak.dx + speed, streak.dy + 0.5);

      if (streak.dx > size.width + 50) {
        streak = Offset(-50, _random.nextDouble() * size.height);
      }
      _streaks[i] = streak;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (_lastSize != size) _streaks.clear();
          _initStreaks(size);
          return CustomPaint(
            size: size,
            painter: WindStreaksPainter(
              streaks: _streaks,
              windSpeed: widget.windSpeed,
            ),
          );
        },
      ),
    );
  }
}

class WindStreaksPainter extends CustomPainter {
  final List<Offset> streaks;
  final double windSpeed;
  
  // Cached paint for performance
  static final Paint _paint = Paint()
    ..color = Colors.white.withOpacity(0.15)
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;

  WindStreaksPainter({required this.streaks, required this.windSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    final length = windSpeed * 3;

    for (var streak in streaks) {
      canvas.drawLine(
        streak,
        Offset(streak.dx + length, streak.dy + length * 0.1),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(WindStreaksPainter oldDelegate) => true;
}

/// Heat Shimmer Effect for hot weather
class HeatShimmerEffect extends StatefulWidget {
  final double intensity;
  final bool isPaused;

  const HeatShimmerEffect({
    super.key,
    this.intensity = 0.5,
    this.isPaused = false,
  });

  @override
  State<HeatShimmerEffect> createState() => _HeatShimmerEffectState();
}

class _HeatShimmerEffectState extends State<HeatShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(HeatShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      widget.isPaused ? _controller.stop() : _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: HeatShimmerPainter(
            progress: _controller.value,
            intensity: widget.intensity,
          ),
        );
      },
    );
  }
}

class HeatShimmerPainter extends CustomPainter {
  final double progress;
  final double intensity;

  HeatShimmerPainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw wavy heat distortion lines
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 5; i++) {
      final path = Path();
      final yBase = size.height * (0.6 + i * 0.08);

      path.moveTo(0, yBase);
      for (var x = 0.0; x < size.width; x += 10) {
        final wave = sin((x / 30) + progress * pi * 2 + i) * 3 * intensity;
        path.lineTo(x, yBase + wave);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(HeatShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Frost on Glass Edges Effect
class FrostGlassEffect extends StatefulWidget {
  final double intensity;
  final bool isPaused;

  const FrostGlassEffect({
    super.key,
    this.intensity = 0.5,
    this.isPaused = false,
  });

  @override
  State<FrostGlassEffect> createState() => _FrostGlassEffectState();
}

class _FrostGlassEffectState extends State<FrostGlassEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    if (!widget.isPaused) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FrostGlassEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      widget.isPaused ? _controller.stop() : _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: FrostGlassPainter(
            progress: _controller.value,
            intensity: widget.intensity,
          ),
        );
      },
    );
  }
}

class FrostGlassPainter extends CustomPainter {
  final double progress;
  final double intensity;
  final Random _random = Random(42); // Fixed seed for consistent pattern

  FrostGlassPainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final baseSpread = 40 + progress * 30 * intensity;
    // Frost covers from top to just above glass sheet (60% of screen height)
    final maxHeight = size.height * 0.6;

    // Left side frost gradient
    final leftGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.25 * intensity),
          Colors.white.withOpacity(0.1 * intensity),
          Colors.white.withOpacity(0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, baseSpread * 2, maxHeight));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, baseSpread * 2, maxHeight),
      leftGradient,
    );

    // Right side frost gradient
    final rightGradient = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Colors.white.withOpacity(0.25 * intensity),
              Colors.white.withOpacity(0.1 * intensity),
              Colors.white.withOpacity(0),
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(
            Rect.fromLTWH(
              size.width - baseSpread * 2,
              0,
              baseSpread * 2,
              maxHeight,
            ),
          );

    canvas.drawRect(
      Rect.fromLTWH(size.width - baseSpread * 2, 0, baseSpread * 2, maxHeight),
      rightGradient,
    );

    // Top corners extra frost
    final cornerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.35 * intensity),
          Colors.white.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, baseSpread * 3, baseSpread * 3));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, baseSpread * 3, baseSpread * 3),
      cornerPaint,
    );

    // Top-right corner
    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, baseSpread * 3, baseSpread * 3),
      cornerPaint,
    );
    canvas.restore();

    // Draw ice crystals along both edges
    final crystalPaint = Paint()
      ..color = Colors.white.withOpacity(0.5 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Left edge crystals - distributed along the full height
    for (var i = 0; i < 35; i++) {
      final x = _random.nextDouble() * baseSpread;
      final y = _random.nextDouble() * maxHeight;
      final crystalSize = 4 + _random.nextDouble() * 10;
      _drawSmallCrystal(canvas, Offset(x, y), crystalSize, crystalPaint);
    }

    // Right edge crystals
    for (var i = 0; i < 35; i++) {
      final x = size.width - _random.nextDouble() * baseSpread;
      final y = _random.nextDouble() * maxHeight;
      final crystalSize = 4 + _random.nextDouble() * 10;
      _drawSmallCrystal(canvas, Offset(x, y), crystalSize, crystalPaint);
    }

    // Top edge crystals
    for (var i = 0; i < 20; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * baseSpread * 0.5;
      final crystalSize = 3 + _random.nextDouble() * 7;
      _drawSmallCrystal(canvas, Offset(x, y), crystalSize, crystalPaint);
    }
  }

  void _drawSmallCrystal(Canvas canvas, Offset pos, double size, Paint paint) {
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      canvas.drawLine(
        pos,
        Offset(pos.dx + cos(angle) * size, pos.dy + sin(angle) * size),
        paint,
      );
      // Small branches
      if (size > 6) {
        final midX = pos.dx + cos(angle) * size * 0.6;
        final midY = pos.dy + sin(angle) * size * 0.6;
        final branchSize = size * 0.3;
        canvas.drawLine(
          Offset(midX, midY),
          Offset(
            midX + cos(angle + pi / 4) * branchSize,
            midY + sin(angle + pi / 4) * branchSize,
          ),
          paint,
        );
        canvas.drawLine(
          Offset(midX, midY),
          Offset(
            midX + cos(angle - pi / 4) * branchSize,
            midY + sin(angle - pi / 4) * branchSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(FrostGlassPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Condensation/Humidity Effect - water droplets on glass
class CondensationEffect extends StatefulWidget {
  final double humidity; // 0-100
  final bool isPaused;

  const CondensationEffect({
    super.key,
    required this.humidity,
    this.isPaused = false,
  });

  @override
  State<CondensationEffect> createState() => _CondensationEffectState();
}

class _CondensationEffectState extends State<CondensationEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<CondensationDrop> _drops = [];
  final Random _random = Random();
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    if (!widget.isPaused) {
      _controller.repeat();
    }

    _controller.addListener(_update);
  }

  @override
  void didUpdateWidget(CondensationEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      widget.isPaused ? _controller.stop() : _controller.repeat();
    }
  }

  void _initDrops(Size size) {
    if (_drops.isEmpty && size.width > 0) {
      final count = ((widget.humidity - 60) * 0.8).toInt().clamp(10, 40);
      for (var i = 0; i < count; i++) {
        _drops.add(
          CondensationDrop(
            x: _random.nextDouble() * size.width,
            y: _random.nextDouble() * size.height * 0.4,
            size: 2 + _random.nextDouble() * 4,
            opacity: 0.2 + _random.nextDouble() * 0.3,
            drip: 0,
          ),
        );
      }
      _lastSize = size;
    }
  }

  void _update() {
    if (!mounted || _lastSize == null) return;

    for (var drop in _drops) {
      // Occasionally drip
      if (_random.nextDouble() < 0.002 && drop.drip == 0) {
        drop.drip = 0.1;
      }
      if (drop.drip > 0) {
        drop.drip += 0.5;
        if (drop.drip > 50) {
          drop.drip = 0;
          drop.y = _random.nextDouble() * _lastSize!.height * 0.3;
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (_lastSize != size) _drops.clear();
          _initDrops(size);
          return CustomPaint(
            size: size,
            painter: CondensationPainter(drops: _drops),
          );
        },
      ),
    );
  }
}

class CondensationPainter extends CustomPainter {
  final List<CondensationDrop> drops;

  CondensationPainter({required this.drops});

  @override
  void paint(Canvas canvas, Size size) {
    for (var drop in drops) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(drop.opacity)
        ..style = PaintingStyle.fill;

      // Main droplet
      canvas.drawCircle(Offset(drop.x, drop.y), drop.size, paint);

      // Drip trail
      if (drop.drip > 0) {
        final trailPaint = Paint()
          ..color = Colors.white.withOpacity(drop.opacity * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = drop.size * 0.5;

        canvas.drawLine(
          Offset(drop.x, drop.y),
          Offset(drop.x, drop.y + drop.drip),
          trailPaint,
        );

        // Drip end
        canvas.drawCircle(
          Offset(drop.x, drop.y + drop.drip),
          drop.size * 0.7,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CondensationPainter oldDelegate) => true;
}

/// Sun Rays/God Rays Effect
class SunRaysEffect extends StatefulWidget {
  final double intensity;
  final bool isPaused;

  const SunRaysEffect({super.key, this.intensity = 0.5, this.isPaused = false});

  @override
  State<SunRaysEffect> createState() => _SunRaysEffectState();
}

class _SunRaysEffectState extends State<SunRaysEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (!widget.isPaused) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SunRaysEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      widget.isPaused ? _controller.stop() : _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: SunRaysPainter(
            progress: _controller.value,
            intensity: widget.intensity,
          ),
        );
      },
    );
  }
}

class SunRaysPainter extends CustomPainter {
  final double progress;
  final double intensity;

  SunRaysPainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.7, size.height * 0.1);
    final rayCount = 8;

    for (var i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * pi * 0.5 + pi * 0.75;
      final rayOpacity = (0.05 + sin(progress * pi * 2 + i) * 0.03) * intensity;

      final path = Path();
      path.moveTo(center.dx, center.dy);

      final length = size.height * 0.8;
      final spread = 0.1;

      path.lineTo(
        center.dx + cos(angle - spread) * length,
        center.dy + sin(angle - spread) * length,
      );
      path.lineTo(
        center.dx + cos(angle + spread) * length,
        center.dy + sin(angle + spread) * length,
      );
      path.close();

      final paint = Paint()
        ..shader = RadialGradient(
          center: Alignment.topRight,
          radius: 1,
          colors: [
            Colors.yellow.withOpacity(rayOpacity),
            Colors.orange.withOpacity(rayOpacity * 0.5),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SunRaysPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Combined weather particles widget that shows appropriate effect
class WeatherParticles extends StatelessWidget {
  final String condition;
  final int conditionCode; // OpenWeatherMap condition code
  final double intensity;
  final double? temperature; // Temperature in Celsius
  final double? humidity; // Humidity percentage
  final double? windSpeed; // Wind speed in m/s
  final bool isNight;
  final bool isPaused;

  const WeatherParticles({
    super.key,
    required this.condition,
    this.conditionCode = 800,
    this.intensity = 0.5,
    this.temperature,
    this.humidity,
    this.windSpeed,
    this.isNight = false,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    final conditionLower = condition.toLowerCase();
    final temp = temperature ?? 20.0;
    final wind = windSpeed ?? 0.0;

    final List<Widget> effects = [];

    // ========== CONDITION-BASED EFFECTS ==========

    // Thunderstorm (codes 200-232)
    if (conditionLower.contains('thunder') ||
        (conditionCode >= 200 && conditionCode < 300)) {
      if (temp < 0) {
        effects.add(SnowEffect(intensity: intensity * 1.2, isPaused: isPaused));
      } else {
        effects.add(
          RainEffect(
            intensity: intensity,
            isThunderstorm: true,
            isPaused: isPaused,
          ),
        );
      }
      effects.add(LightningEffect(active: true, isPaused: isPaused));
    }
    // Drizzle (codes 300-321)
    else if (conditionLower.contains('drizzle') ||
        (conditionCode >= 300 && conditionCode < 400)) {
      if (temp < 2) {
        effects.add(SnowEffect(intensity: intensity * 0.5, isPaused: isPaused));
      } else {
        effects.add(RainEffect(intensity: intensity * 0.6, isPaused: isPaused));
      }
    }
    // Rain (codes 500-531)
    else if (conditionLower.contains('rain') ||
        conditionLower.contains('shower') ||
        (conditionCode >= 500 && conditionCode < 600)) {
      // Freezing rain (511)
      if (conditionCode == 511 || temp < 0) {
        effects.add(HailEffect(intensity: intensity * 0.7, isPaused: isPaused));
        effects.add(SnowEffect(intensity: intensity * 0.4, isPaused: isPaused));
      } else if (temp < 2) {
        // Sleet
        effects.add(SnowEffect(intensity: intensity * 0.6, isPaused: isPaused));
        effects.add(RainEffect(intensity: intensity * 0.4, isPaused: isPaused));
      } else {
        effects.add(RainEffect(intensity: intensity, isPaused: isPaused));
      }
    }
    // Snow (codes 600-622)
    else if (conditionLower.contains('snow') ||
        conditionLower.contains('sleet') ||
        (conditionCode >= 600 && conditionCode < 700)) {
      // Sleet (611-616)
      if (conditionCode >= 611 && conditionCode <= 616) {
        effects.add(SnowEffect(intensity: intensity * 0.7, isPaused: isPaused));
        effects.add(RainEffect(intensity: intensity * 0.3, isPaused: isPaused));
      } else {
        effects.add(SnowEffect(intensity: intensity, isPaused: isPaused));
      }
      if (temp < -5) {
        effects.add(
          FrostEffect(intensity: intensity * 0.5, isPaused: isPaused),
        );
      }
    }
    // Atmosphere (codes 700-781) - Mist, Fog, Dust, Sand, etc.
    else if (conditionCode >= 700 && conditionCode < 800) {
      // Dust/Sand (731, 751, 761)
      if (conditionCode == 731 ||
          conditionCode == 751 ||
          conditionCode == 761 ||
          conditionLower.contains('dust') ||
          conditionLower.contains('sand')) {
        effects.add(DustStormEffect(intensity: intensity, isPaused: isPaused));
      }
      // Mist, Fog, Haze, Smoke (701, 711, 721, 741)
      else if (conditionLower.contains('mist') ||
          conditionLower.contains('fog') ||
          conditionLower.contains('haze') ||
          conditionLower.contains('smoke')) {
        effects.add(MistEffect(intensity: intensity, isPaused: isPaused));
        if (temp < 0) {
          effects.add(
            FrostEffect(intensity: intensity * 0.6, isPaused: isPaused),
          );
        }
      }
    }
    // Clear (800)
    else if (conditionCode == 800 || conditionLower.contains('clear')) {
      if (isNight) {
        effects.add(StarsEffect(intensity: intensity, isPaused: isPaused));
      } else {
        // Hot sunny day
        if (temp > 35) {
          effects.add(
            HeatShimmerEffect(intensity: intensity * 0.8, isPaused: isPaused),
          );
        }
      }
    }
    // Clouds (801-804)
    else if (conditionCode >= 801 && conditionCode <= 804) {
      effects.add(
        CloudsEffect(
          intensity: intensity * 0.5,
          isDark: isNight,
          isPaused: isPaused,
        ),
      );

      // Few clouds with sun rays during day
      if (!isNight && conditionCode <= 802) {
        effects.add(
          SunRaysEffect(intensity: intensity * 0.6, isPaused: isPaused),
        );
      }

      // Stars visible through partly cloudy night
      if (isNight && conditionCode <= 802) {
        effects.add(
          StarsEffect(intensity: intensity * 0.4, isPaused: isPaused),
        );
      }
    }

    // ========== TEMPERATURE-BASED EFFECTS ==========

    // Extreme cold effects (frost on glass)
    if (temp < -5) {
      effects.add(
        FrostGlassEffect(intensity: intensity * 0.7, isPaused: isPaused),
      );
    } else if (temp < 0) {
      effects.add(
        FrostGlassEffect(intensity: intensity * 0.4, isPaused: isPaused),
      );
    }

    // Heat shimmer for very hot weather (if not already added)
    if (temp > 38 && !effects.any((e) => e is HeatShimmerEffect)) {
      effects.add(HeatShimmerEffect(intensity: intensity, isPaused: isPaused));
    }

    // ========== WIND-BASED EFFECTS ==========

    // Wind streaks for strong wind
    if (wind > 8) {
      effects.add(WindStreaksEffect(windSpeed: wind, isPaused: isPaused));
    }

    // ========== NIGHT-SPECIFIC EFFECTS ==========

    // Stars for clear-ish night (if not already added)
    if (isNight &&
        conditionCode < 700 &&
        !effects.any((e) => e is StarsEffect)) {
      // Light stars visible even through light precipitation
      if (conditionCode < 500 || conditionCode == 800) {
        effects.add(
          StarsEffect(intensity: intensity * 0.3, isPaused: isPaused),
        );
      }
    }

    // Return empty if no effects
    if (effects.isEmpty) {
      return const SizedBox.shrink();
    }

    // Return single effect or stack of effects
    if (effects.length == 1) {
      return effects.first;
    }

    return Stack(children: effects);
  }
}
