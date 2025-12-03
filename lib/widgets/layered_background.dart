import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../utils/theme_utils.dart';
import 'parallax_scenery.dart';
import 'weather_particles.dart';

class LayeredBackground extends StatefulWidget {
  final DateTime? sunrise;
  final DateTime? sunset;
  final String? weatherCondition;
  final int? conditionCode; // OpenWeatherMap condition code
  final DateTime? currentTime; // City's local time
  final double? temperature; // Temperature in Celsius
  final double? humidity; // Humidity percentage
  final double? windSpeed; // Wind speed in m/s
  final bool pauseAnimation;

  const LayeredBackground({
    super.key,
    this.sunrise,
    this.sunset,
    this.weatherCondition,
    this.conditionCode,
    this.currentTime,
    this.temperature,
    this.humidity,
    this.windSpeed,
    this.pauseAnimation = false,
  });

  @override
  State<LayeredBackground> createState() => _LayeredBackgroundState();
}

class _LayeredBackgroundState extends State<LayeredBackground>
    with TickerProviderStateMixin {
  late AnimationController _parallaxController;
  late AnimationController _transitionController;

  // Current state values (for smooth lerping)
  DayPhase _currentTimeOfDay = DayPhase.day;
  DayPhase _targetTimeOfDay = DayPhase.day;
  double _targetCelestialProgress = 0.5;
  bool _targetIsNight = false;

  // Previous values for animation
  List<Color> _currentSkyColors = ThemeUtils.getSkyGradient(DayPhase.day);
  List<Color> _targetSkyColors = ThemeUtils.getSkyGradient(DayPhase.day);
  Color _currentCloudColor = Colors.white;
  Color _targetCloudColor = Colors.white;
  List<Color> _currentMountainColors = ThemeUtils.getMountainColors(
    DayPhase.day,
  );
  List<Color> _targetMountainColors = ThemeUtils.getMountainColors(
    DayPhase.day,
  );

  @override
  void initState() {
    super.initState();
    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    if (!widget.pauseAnimation) {
      _parallaxController.repeat(reverse: true);
    }

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _updateTheme(animate: false);
  }

  @override
  void didUpdateWidget(LayeredBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle pause/resume
    if (widget.pauseAnimation != oldWidget.pauseAnimation) {
      if (widget.pauseAnimation) {
        _parallaxController.stop();
      } else {
        _parallaxController.repeat(reverse: true);
      }
    }

    // When sunrise/sunset or currentTime changes (city change), animate smoothly
    if (oldWidget.sunrise != widget.sunrise ||
        oldWidget.sunset != widget.sunset ||
        oldWidget.currentTime != widget.currentTime) {
      _updateTheme(animate: true);
    }
  }

  void _updateTheme({bool animate = true}) {
    final now = widget.currentTime ?? DateTime.now();
    final sunrise =
        widget.sunrise ?? DateTime(now.year, now.month, now.day, 6, 0);
    final sunset =
        widget.sunset ?? DateTime(now.year, now.month, now.day, 18, 0);

    final newTimeOfDay = ThemeUtils.getTimeOfDay(now, sunrise, sunset);
    final newIsNight = ThemeUtils.isNight(now, sunrise, sunset);
    final newProgress = ThemeUtils.getCelestialProgress(now, sunrise, sunset);

    if (animate) {
      // Store current interpolated values as start point
      _currentSkyColors = _lerpColorList(
        _currentSkyColors,
        _targetSkyColors,
        _transitionController.value,
      );
      _currentCloudColor =
          Color.lerp(
            _currentCloudColor,
            _targetCloudColor,
            _transitionController.value,
          ) ??
          _currentCloudColor;
      _currentMountainColors = _lerpColorList(
        _currentMountainColors,
        _targetMountainColors,
        _transitionController.value,
      );
    }

    // Update current time of day before setting target
    _currentTimeOfDay = _targetTimeOfDay;

    // Set new targets
    _targetTimeOfDay = newTimeOfDay;
    _targetIsNight = newIsNight;
    _targetCelestialProgress = newProgress;
    _targetSkyColors = ThemeUtils.getSkyGradient(newTimeOfDay);
    _targetCloudColor = ThemeUtils.getCloudColor(newTimeOfDay);
    _targetMountainColors = ThemeUtils.getMountainColors(newTimeOfDay);

    if (animate) {
      // Reset and play transition
      _transitionController.forward(from: 0.0);
    } else {
      // Instant update
      _currentSkyColors = _targetSkyColors;
      _currentCloudColor = _targetCloudColor;
      _currentMountainColors = _targetMountainColors;
      _currentTimeOfDay = newTimeOfDay;
    }

    setState(() {});
  }

  List<Color> _lerpColorList(List<Color> from, List<Color> to, double t) {
    final maxLen = math.max(from.length, to.length);
    final result = <Color>[];

    for (var i = 0; i < maxLen; i++) {
      final fromColor = i < from.length ? from[i] : from.last;
      final toColor = i < to.length ? to[i] : to.last;
      result.add(Color.lerp(fromColor, toColor, t) ?? toColor);
    }

    return result;
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_parallaxController, _transitionController]),
      builder: (context, child) {
        final parallaxOffset = _parallaxController.value * 20 - 10;
        final t = _transitionController.value;

        // Interpolate all colors
        final skyColors = _lerpColorList(
          _currentSkyColors,
          _targetSkyColors,
          t,
        );
        final cloudColor =
            Color.lerp(_currentCloudColor, _targetCloudColor, t) ??
            _targetCloudColor;
        final mountainColors = _lerpColorList(
          _currentMountainColors,
          _targetMountainColors,
          t,
        );

        // Determine if we should show stars
        final showStars =
            _currentTimeOfDay == DayPhase.night ||
            _targetTimeOfDay == DayPhase.night ||
            _currentTimeOfDay == DayPhase.sunrise ||
            _targetTimeOfDay == DayPhase.sunrise;

        // Calculate star opacity based on transition
        double starsOpacity = 0.0;
        if (_targetTimeOfDay == DayPhase.night) {
          starsOpacity = t;
        } else if (_currentTimeOfDay == DayPhase.night) {
          starsOpacity = 1 - t;
        } else if (_targetTimeOfDay == DayPhase.sunrise ||
            _currentTimeOfDay == DayPhase.sunrise) {
          starsOpacity = 0.3; // Faint stars during sunrise
        }

        return Stack(
          children: [
            // 1. Animated Sky Gradient with smooth color transitions
            RepaintBoundary(child: _buildAnimatedSky(skyColors)),

            // 2. Stars (visible during night and fading during sunrise)
            if (showStars && starsOpacity > 0)
              Positioned.fill(
                child: Opacity(
                  opacity: starsOpacity.clamp(0.0, 1.0),
                  child: CustomPaint(
                    painter: StarsPainter(
                      twinkleValue: _parallaxController.value,
                    ),
                  ),
                ),
              ),

            // 3. Horizon glow for sunrise/sunset
            _buildHorizonGlow(size, t),

            // 4. Far Clouds (Slowest parallax)
            Positioned(
              top: 80,
              left:
                  -50 +
                  (parallaxOffset * 0.3) +
                  (_parallaxController.value * 20),
              child: _buildCloud(100, 0.6, cloudColor),
            ),

            // 5. Sun (animated position and opacity)
            _buildAnimatedSun(size, parallaxOffset),

            // 6. Moon (animated position and opacity)
            _buildAnimatedMoon(size, parallaxOffset),

            // 7. Middle Clouds (Medium parallax)
            Positioned(
              top: 200,
              right:
                  -30 +
                  (parallaxOffset * 0.5) +
                  (_parallaxController.value * 25),
              child: _buildCloud(160, 0.5, cloudColor),
            ),

            // 8. Weather Particles (Rain/Snow/Cold effects)
            if (widget.weatherCondition != null ||
                (widget.temperature != null && widget.temperature! < 2) ||
                (widget.humidity != null && widget.humidity! > 80) ||
                (widget.windSpeed != null && widget.windSpeed! > 8))
              Positioned.fill(
                child: RepaintBoundary(
                  child: WeatherParticles(
                    condition: widget.weatherCondition ?? 'clear',
                    conditionCode: widget.conditionCode ?? 800,
                    intensity: 0.6,
                    temperature: widget.temperature,
                    humidity: widget.humidity,
                    windSpeed: widget.windSpeed,
                    isNight: _targetIsNight,
                    isPaused: widget.pauseAnimation,
                  ),
                ),
              ),

            // 9. Near Clouds (Fastest parallax)
            Positioned(
              top: 320,
              left:
                  -80 +
                  (parallaxOffset * 0.8) +
                  (_parallaxController.value * 35),
              child: _buildCloud(180, 0.3, cloudColor),
            ),

            // 10. Parallax Scenery (Mountains with animated colors)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RepaintBoundary(
                child: ParallaxScenery(
                  height: 350,
                  colors: mountainColors,
                  parallaxOffset: 0, // Disabled movement for performance
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedSky(List<Color> colors) {
    List<double>? stops;
    if (colors.length == 3) {
      stops = [0.0, 0.5, 1.0];
    } else if (colors.length > 3) {
      stops = List.generate(colors.length, (i) => i / (colors.length - 1));
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ),
      ),
    );
  }

  Widget _buildHorizonGlow(Size size, double t) {
    final isSunrise =
        _currentTimeOfDay == DayPhase.sunrise ||
        _targetTimeOfDay == DayPhase.sunrise;
    final isSunset =
        _currentTimeOfDay == DayPhase.sunset ||
        _targetTimeOfDay == DayPhase.sunset;

    if (!isSunrise && !isSunset) return const SizedBox.shrink();

    final glowColor = isSunrise
        ? const Color(0xFFFFAB40) // Orange for sunrise
        : const Color(0xFFE74C3C); // Red-orange for sunset

    // Calculate glow intensity
    double glowIntensity = 0.0;
    if (_targetTimeOfDay == DayPhase.sunrise ||
        _targetTimeOfDay == DayPhase.sunset) {
      glowIntensity = t;
    } else if (_currentTimeOfDay == DayPhase.sunrise ||
        _currentTimeOfDay == DayPhase.sunset) {
      glowIntensity = 1 - t;
    }

    return Positioned(
      bottom: size.height * 0.25,
      left: 0,
      right: 0,
      child: Container(
        height: size.height * 0.45,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomCenter,
            radius: 1.2,
            colors: [
              glowColor.withOpacity(0.5 * glowIntensity),
              glowColor.withOpacity(0.25 * glowIntensity),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSun(Size size, double parallaxOffset) {
    final maxHeight = size.height * 0.25;
    final progress = _targetCelestialProgress;
    final arcY = -4 * maxHeight * math.pow(progress - 0.5, 2) + maxHeight;
    final x = size.width * 0.1 + (size.width * 0.8) * progress;
    final y = size.height * 0.35 - arcY;

    // Sun position: rises from/sets to below horizon
    final horizonY = size.height * 0.6;
    final sunY = _targetIsNight ? horizonY : y;

    // Determine sun color based on time
    final isLowSun =
        _targetTimeOfDay == DayPhase.sunrise ||
        _targetTimeOfDay == DayPhase.sunset;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOutCubic,
      left: x - 60 + parallaxOffset * 0.1,
      top: sunY - 60,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        opacity: _targetIsNight ? 0.0 : 1.0,
        child: _buildSun(isLowSun: isLowSun),
      ),
    );
  }

  Widget _buildAnimatedMoon(Size size, double parallaxOffset) {
    final maxHeight = size.height * 0.2;
    final progress = _targetCelestialProgress;
    final arcY = -4 * maxHeight * math.pow(progress - 0.5, 2) + maxHeight;
    final x = size.width * 0.1 + (size.width * 0.8) * progress;
    final y = size.height * 0.3 - arcY;

    // Moon position: rises from/sets to below horizon
    final horizonY = size.height * 0.6;
    final moonY = _targetIsNight ? y : horizonY;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOutCubic,
      left: x - 50 + parallaxOffset * 0.1,
      top: moonY - 50,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        opacity: _targetIsNight ? 1.0 : 0.0,
        child: _buildMoon(),
      ),
    );
  }

  Widget _buildSun({bool isLowSun = false}) {
    final sunColors = isLowSun
        ? const [Color(0xFFFF6B35), Color(0xFFFF8E53)] // Orange-red for low sun
        : const [Color(0xFFFFD700), Color(0xFFFFA500)]; // Yellow-orange

    final glowColor = isLowSun
        ? const Color(0xFFFF6B35)
        : const Color(0xFFFFD700);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: sunColors,
              ),
              boxShadow: [
                // Outer glow
                BoxShadow(
                  color: glowColor.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 20,
                ),
                // Inner glow
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            // Sun rays
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(8, (i) {
                return Transform.rotate(
                  angle:
                      (i * math.pi / 4) +
                      (_parallaxController.value * math.pi * 0.1),
                  child: Container(
                    width: 2,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.transparent,
                          glowColor.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(seconds: 4),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
              ),
              boxShadow: [
                // Moon glow
                BoxShadow(
                  color: const Color(0xFFE1F5FE).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 15,
                ),
                // Subtle outer ring
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Moon craters
                Positioned(top: 15, left: 20, child: _buildCrater(18, 0.15)),
                Positioned(top: 45, left: 50, child: _buildCrater(22, 0.12)),
                Positioned(top: 60, left: 15, child: _buildCrater(14, 0.1)),
                Positioned(top: 25, left: 55, child: _buildCrater(10, 0.08)),
                Positioned(top: 70, left: 45, child: _buildCrater(8, 0.1)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCrater(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(opacity * 0.5),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCloud(double width, double opacity, Color color) {
    return Container(
      width: width,
      height: width * 0.5,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(width / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(5, 5),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for twinkling stars
class StarsPainter extends CustomPainter {
  final double twinkleValue;
  static bool _initialized = false;
  static final List<Star> _staticStars = [];

  StarsPainter({required this.twinkleValue}) {
    if (!_initialized) {
      final random = math.Random(42);
      for (var i = 0; i < 150; i++) {
        _staticStars.add(
          Star(
            x: random.nextDouble(),
            y: random.nextDouble() * 0.6,
            size: 0.5 + random.nextDouble() * 2.5,
            twinkleOffset: random.nextDouble() * math.pi * 2,
            brightness: 0.5 + random.nextDouble() * 0.5,
          ),
        );
      }
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var star in _staticStars) {
      final twinkle =
          (math.sin(twinkleValue * math.pi * 4 + star.twinkleOffset) + 1) / 2;
      final opacity = star.brightness * (0.4 + twinkle * 0.6);

      paint.color = Colors.white.withOpacity(opacity);

      // Add subtle glow to brighter stars
      if (star.size > 1.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.size * 2,
          glowPaint,
        );
      }

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size * (0.7 + twinkle * 0.3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) => true;
}

class Star {
  final double x;
  final double y;
  final double size;
  final double twinkleOffset;
  final double brightness;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleOffset,
    this.brightness = 1.0,
  });
}
