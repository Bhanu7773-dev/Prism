import 'package:flutter/material.dart';

/// Represents the current time-of-day state for theming
enum TimeOfDay {
  dawn,    // 1 hour before sunrise to 30 min after
  day,     // 30 min after sunrise to 1 hour before sunset
  dusk,    // 1 hour before sunset to 30 min after
  night,   // 30 min after sunset to 1 hour before sunrise
}

/// Dynamic theme data based on time of day and weather conditions
class WeatherTheme {
  final TimeOfDay timeOfDay;
  final String weatherCondition;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime currentTime;

  WeatherTheme({
    required this.sunrise,
    required this.sunset,
    required this.currentTime,
    this.weatherCondition = 'Clear',
  }) : timeOfDay = _calculateTimeOfDay(sunrise, sunset, currentTime);

  static TimeOfDay _calculateTimeOfDay(
    DateTime sunrise,
    DateTime sunset,
    DateTime current,
  ) {
    final dawnStart = sunrise.subtract(const Duration(hours: 1));
    final dawnEnd = sunrise.add(const Duration(minutes: 30));
    final duskStart = sunset.subtract(const Duration(hours: 1));
    final duskEnd = sunset.add(const Duration(minutes: 30));

    if (current.isAfter(dawnStart) && current.isBefore(dawnEnd)) {
      return TimeOfDay.dawn;
    } else if (current.isAfter(dawnEnd) && current.isBefore(duskStart)) {
      return TimeOfDay.day;
    } else if (current.isAfter(duskStart) && current.isBefore(duskEnd)) {
      return TimeOfDay.dusk;
    } else {
      return TimeOfDay.night;
    }
  }

  /// Progress through current time period (0.0 to 1.0)
  double get periodProgress {
    switch (timeOfDay) {
      case TimeOfDay.dawn:
        final dawnStart = sunrise.subtract(const Duration(hours: 1));
        final dawnEnd = sunrise.add(const Duration(minutes: 30));
        final total = dawnEnd.difference(dawnStart).inMinutes;
        final elapsed = currentTime.difference(dawnStart).inMinutes;
        return (elapsed / total).clamp(0.0, 1.0);
      case TimeOfDay.day:
        final dayStart = sunrise.add(const Duration(minutes: 30));
        final dayEnd = sunset.subtract(const Duration(hours: 1));
        final total = dayEnd.difference(dayStart).inMinutes;
        final elapsed = currentTime.difference(dayStart).inMinutes;
        return (elapsed / total).clamp(0.0, 1.0);
      case TimeOfDay.dusk:
        final duskStart = sunset.subtract(const Duration(hours: 1));
        final duskEnd = sunset.add(const Duration(minutes: 30));
        final total = duskEnd.difference(duskStart).inMinutes;
        final elapsed = currentTime.difference(duskStart).inMinutes;
        return (elapsed / total).clamp(0.0, 1.0);
      case TimeOfDay.night:
        // Night spans from dusk end to dawn start (next day)
        return 0.5; // Simplified for night
    }
  }

  /// Sky gradient colors based on time of day
  List<Color> get skyGradient {
    switch (timeOfDay) {
      case TimeOfDay.dawn:
        // Transition from night purple to warm sunrise
        return Color.lerp(
          const Color(0xFF1a1a2e),
          const Color(0xFF4A90E2),
          periodProgress,
        ) != null
            ? [
                Color.lerp(const Color(0xFF1a1a2e), const Color(0xFF4A90E2), periodProgress)!,
                Color.lerp(const Color(0xFF16213e), const Color(0xFFFFB347), periodProgress)!,
                Color.lerp(const Color(0xFF0f3460), const Color(0xFFFF6B6B), periodProgress)!,
              ]
            : _dayGradient;
      case TimeOfDay.day:
        return _dayGradient;
      case TimeOfDay.dusk:
        // Transition from day blue to sunset colors to night
        if (periodProgress < 0.5) {
          // First half: Day to sunset
          final t = periodProgress * 2;
          return [
            Color.lerp(const Color(0xFF4A90E2), const Color(0xFFFF6B6B), t)!,
            Color.lerp(const Color(0xFF87CEEB), const Color(0xFFFFB347), t)!,
            Color.lerp(const Color(0xFF87CEEB), const Color(0xFF9B59B6), t)!,
          ];
        } else {
          // Second half: Sunset to night
          final t = (periodProgress - 0.5) * 2;
          return [
            Color.lerp(const Color(0xFFFF6B6B), const Color(0xFF1a1a2e), t)!,
            Color.lerp(const Color(0xFFFFB347), const Color(0xFF16213e), t)!,
            Color.lerp(const Color(0xFF9B59B6), const Color(0xFF0f3460), t)!,
          ];
        }
      case TimeOfDay.night:
        return _nightGradient;
    }
  }

  List<Color> get _dayGradient => const [
    Color(0xFF4A90E2), // Day Sky Top
    Color(0xFF87CEEB), // Day Sky Middle
    Color(0xFFA7D3F3), // Day Sky Bottom
  ];

  List<Color> get _nightGradient => const [
    Color(0xFF0f0c29), // Deep night top
    Color(0xFF1a1a2e), // Night middle
    Color(0xFF16213e), // Night bottom
  ];

  /// Sun visibility (1.0 = fully visible, 0.0 = hidden)
  double get sunOpacity {
    switch (timeOfDay) {
      case TimeOfDay.dawn:
        return periodProgress; // Fade in
      case TimeOfDay.day:
        return 1.0;
      case TimeOfDay.dusk:
        return 1.0 - periodProgress; // Fade out
      case TimeOfDay.night:
        return 0.0;
    }
  }

  /// Moon visibility (1.0 = fully visible, 0.0 = hidden)
  double get moonOpacity {
    switch (timeOfDay) {
      case TimeOfDay.dawn:
        return 1.0 - periodProgress; // Fade out
      case TimeOfDay.day:
        return 0.0;
      case TimeOfDay.dusk:
        return periodProgress; // Fade in
      case TimeOfDay.night:
        return 1.0;
    }
  }

  /// Sun vertical position (0.0 = horizon, 1.0 = highest point)
  double get sunPosition {
    switch (timeOfDay) {
      case TimeOfDay.dawn:
        return periodProgress * 0.3; // Rising from horizon
      case TimeOfDay.day:
        // Arc through the sky
        final arcProgress = periodProgress;
        return 0.3 + (0.7 * (1 - (2 * arcProgress - 1).abs()));
      case TimeOfDay.dusk:
        return 0.3 * (1 - periodProgress); // Setting to horizon
      case TimeOfDay.night:
        return 0.0;
    }
  }

  /// Moon vertical position
  double get moonPosition {
    switch (timeOfDay) {
      case TimeOfDay.dawn:
        return 0.5 * (1 - periodProgress); // Setting
      case TimeOfDay.day:
        return 0.0;
      case TimeOfDay.dusk:
        return 0.2 * periodProgress; // Rising
      case TimeOfDay.night:
        return 0.5; // High in sky
    }
  }

  /// Cloud color tint based on time
  Color get cloudColor {
    switch (timeOfDay) {
      case TimeOfDay.dawn:
        return Color.lerp(
          const Color(0xFF6B7B8C),
          Colors.white,
          periodProgress,
        )!;
      case TimeOfDay.day:
        return Colors.white;
      case TimeOfDay.dusk:
        return Color.lerp(
          Colors.white,
          const Color(0xFFFFB6C1),
          periodProgress * 0.5,
        )!;
      case TimeOfDay.night:
        return const Color(0xFF4A5568);
    }
  }

  /// Mountain/hill colors based on time
  List<Color> get mountainColors {
    switch (timeOfDay) {
      case TimeOfDay.dawn:
      case TimeOfDay.dusk:
        return const [
          Color(0xFF6B5B7A), // Back - purplish
          Color(0xFF4A4158), // Mid
          Color(0xFF2D2438), // Front - dark purple
        ];
      case TimeOfDay.day:
        return const [
          Color(0xFF8FA3C0), // Back - Muted Blue-Grey
          Color(0xFF5D7392), // Mid - Darker Blue-Grey
          Color(0xFF2C3E50), // Front - Dark Slate
        ];
      case TimeOfDay.night:
        return const [
          Color(0xFF2D3748), // Back - dark blue grey
          Color(0xFF1A202C), // Mid - darker
          Color(0xFF0D1117), // Front - almost black
        ];
    }
  }

  /// Stars visibility
  double get starsOpacity {
    switch (timeOfDay) {
      case TimeOfDay.dawn:
        return (1 - periodProgress * 2).clamp(0.0, 1.0);
      case TimeOfDay.day:
        return 0.0;
      case TimeOfDay.dusk:
        return ((periodProgress - 0.5) * 2).clamp(0.0, 1.0);
      case TimeOfDay.night:
        return 1.0;
    }
  }

  /// Whether it's considered "dark" for UI contrast
  bool get isDark => timeOfDay == TimeOfDay.night || 
      (timeOfDay == TimeOfDay.dusk && periodProgress > 0.7) ||
      (timeOfDay == TimeOfDay.dawn && periodProgress < 0.3);
}
