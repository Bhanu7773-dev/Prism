import 'package:flutter/material.dart';

enum DayPhase { day, sunset, night, sunrise }

class ThemeUtils {
  /// Determines the time of day based on fixed time ranges
  static DayPhase getTimeOfDay(
    DateTime now,
    DateTime sunrise, // Kept for signature compatibility but unused for phase
    DateTime sunset, // Kept for signature compatibility but unused for phase
  ) {
    final hour = now.hour;

    if (hour >= 6 && hour < 9) {
      return DayPhase.sunrise; // Morning: 6 AM - 9 AM
    } else if (hour >= 9 && hour < 16) {
      return DayPhase.day; // Day: 9 AM - 4 PM
    } else if (hour >= 16 && hour < 19) {
      return DayPhase.sunset; // Sunset: 4 PM - 7 PM
    } else {
      return DayPhase.night; // Night: 7 PM - 6 AM
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
    // Fixed cycle: Day is 06:00 to 19:00, Night is 19:00 to 06:00
    final hour = now.hour;
    final minute = now.minute;
    final totalMinutes = hour * 60 + minute;

    // Day Cycle: 06:00 (360 min) to 19:00 (1140 min)
    if (hour >= 6 && hour < 19) {
      final start = 6 * 60;
      final end = 19 * 60;
      final progress = (totalMinutes - start) / (end - start);
      return progress.clamp(0.0, 1.0);
    }

    // Night Cycle: 19:00 (1140 min) to 06:00 (360 min next day)
    // We treat 19:00 as 0.0 and 06:00 as 1.0
    int adjustedMinutes = totalMinutes;
    if (hour < 6) {
      adjustedMinutes += 24 * 60; // Add 24 hours if it's past midnight
    }

    final start = 19 * 60;
    final end = (6 + 24) * 60; // 30 hours (6 AM next day)

    final progress = (adjustedMinutes - start) / (end - start);
    return progress.clamp(0.0, 1.0);
  }

  /// Check if it's currently nighttime
  static bool isNight(DateTime now, DateTime sunrise, DateTime sunset) {
    final hour = now.hour;
    return hour >= 19 || hour < 6;
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

  /// Returns gradient colors for the Glass Bottom Sheet based on time of day
  /// Matches the user's request for Pink/Purple during orange scenery (Sunset)
  static List<Color> getGlassGradient(DayPhase phase) {
    switch (phase) {
      case DayPhase.day:
        // Day - Vibrant Clear Blue
        return const [
          Color(0xFF4A90E2), // Bright Blue
          Color(0xFF6DD5FA), // Sky Blue
        ];
      case DayPhase.sunset:
        // Sunset - Pink & Purple (Requested: "pink and purple type of gradient")
        return const [
          Color(0xFF8E2DE2), // Purple
          Color(0xFFFF0080), // Pinkish Magenta
          Color(0xFFFF512F), // Deep Orange (bottom hint)
        ];
      case DayPhase.sunrise:
        // Sunrise - Softer Pink & Orange
        return const [
          Color(0xFFDA4453), // Reddish
          Color(0xFFFF6B6B), // Soft Red
          Color(0xFFFFD93D), // Yellow-Orange
        ];
      case DayPhase.night:
        // Night - Deep Purple/Dark Blue
        return const [
          Color(0xFF0F2027), // Black-Blue
          Color(0xFF203A43), // Dark Teal-Blue
          Color(0xFF2C5364), // Blue-Grey
        ];
    }
  }
}
