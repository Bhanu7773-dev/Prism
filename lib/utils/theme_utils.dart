import 'package:flutter/material.dart';

enum DayPhase { day, sunset, night, sunrise }

class ThemeUtils {
  /// Determines the time of day based on current time and sunrise/sunset
  static DayPhase getTimeOfDay(
    DateTime now,
    DateTime sunrise,
    DateTime sunset,
  ) {
    final sunriseStart = sunrise.subtract(const Duration(minutes: 30));
    final sunriseEnd = sunrise.add(const Duration(minutes: 30));
    final sunsetStart = sunset.subtract(const Duration(minutes: 30));
    final sunsetEnd = sunset.add(const Duration(minutes: 30));

    if (now.isAfter(sunriseStart) && now.isBefore(sunriseEnd)) {
      return DayPhase.sunrise;
    } else if (now.isAfter(sunsetStart) && now.isBefore(sunsetEnd)) {
      return DayPhase.sunset;
    } else if (now.isAfter(sunriseEnd) && now.isBefore(sunsetStart)) {
      return DayPhase.day;
    } else {
      return DayPhase.night;
    }
  }

  /// Returns gradient colors based on time of day
  static List<Color> getSkyGradient(DayPhase phase) {
    switch (phase) {
      case DayPhase.day:
        return const [
          Color(0xFF4A90E2), // Blue top
          Color(0xFF87CEEB), // Light blue bottom
        ];
      case DayPhase.sunset:
        return const [
          Color(0xFF2C3E50), // Dark blue top
          Color(0xFFE74C3C), // Orange-red
          Color(0xFFF39C12), // Gold bottom
        ];
      case DayPhase.sunrise:
        return const [
          Color(0xFF2C3E50), // Dark blue top
          Color(0xFFE91E63), // Pink
          Color(0xFFFFAB40), // Orange bottom
        ];
      case DayPhase.night:
        return const [
          Color(0xFF0D1B2A), // Deep dark blue
          Color(0xFF1B263B), // Dark slate
          Color(0xFF415A77), // Muted blue
        ];
    }
  }

  /// Returns the sun/moon position progress (0.0 = horizon left, 0.5 = top, 1.0 = horizon right)
  static double getCelestialProgress(
    DateTime now,
    DateTime sunrise,
    DateTime sunset,
  ) {
    // Daytime: sun moves from sunrise to sunset
    if (now.isAfter(sunrise) && now.isBefore(sunset)) {
      final totalDayMinutes = sunset.difference(sunrise).inMinutes;
      if (totalDayMinutes <= 0) return 0.5;
      final elapsedMinutes = now.difference(sunrise).inMinutes;
      return (elapsedMinutes / totalDayMinutes).clamp(0.0, 1.0);
    }

    // Nighttime: moon moves (we'll use a simplified version)
    // Calculate progress through the night
    final nextSunrise = now.isBefore(sunrise)
        ? sunrise
        : sunrise.add(const Duration(days: 1));
    final prevSunset = now.isAfter(sunset)
        ? sunset
        : sunset.subtract(const Duration(days: 1));

    final totalNightMinutes = nextSunrise.difference(prevSunset).inMinutes;
    if (totalNightMinutes <= 0) return 0.5;
    final elapsedMinutes = now.difference(prevSunset).inMinutes;
    return (elapsedMinutes / totalNightMinutes).clamp(0.0, 1.0);
  }

  /// Check if it's currently nighttime
  static bool isNight(DateTime now, DateTime sunrise, DateTime sunset) {
    return now.isBefore(sunrise) || now.isAfter(sunset);
  }

  /// Get cloud color based on time of day
  static Color getCloudColor(DayPhase phase) {
    switch (phase) {
      case DayPhase.day:
        return Colors.white;
      case DayPhase.sunset:
        return const Color(0xFFFFB74D); // Orange tinted
      case DayPhase.sunrise:
        return const Color(0xFFFFAB91); // Pink tinted
      case DayPhase.night:
        return const Color(0xFF546E7A); // Dark grey
    }
  }

  /// Get mountain colors based on time of day
  static List<Color> getMountainColors(DayPhase phase) {
    switch (phase) {
      case DayPhase.day:
        return const [
          Color(0xFF8FA3C0), // Back - light
          Color(0xFF5D7392), // Mid
          Color(0xFF2C3E50), // Front - dark
        ];
      case DayPhase.sunset:
        return const [
          Color(0xFF7B5E57), // Warm brown
          Color(0xFF4A3728), // Darker brown
          Color(0xFF1A1A2E), // Very dark
        ];
      case DayPhase.sunrise:
        return const [
          Color(0xFF8D6E63), // Warm brown
          Color(0xFF5D4037), // Medium brown
          Color(0xFF1A1A2E), // Dark
        ];
      case DayPhase.night:
        return const [
          Color(0xFF2D3748), // Dark blue-grey
          Color(0xFF1A202C), // Darker
          Color(0xFF0D1117), // Almost black
        ];
    }
  }
}
