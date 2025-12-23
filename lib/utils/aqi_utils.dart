import 'dart:math';
import 'package:flutter/material.dart';

class AqiUtils {
  /// Calculate US EPA AQI from PM2.5 concentration (µg/m³)
  static int calculateAQI(double pm25) {
    if (pm25 < 0) return 0;
    if (pm25 <= 12.0) return _linear(50, 0, 12.0, 0, pm25);
    if (pm25 <= 35.4) return _linear(100, 51, 35.4, 12.1, pm25);
    if (pm25 <= 55.4) return _linear(150, 101, 55.4, 35.5, pm25);
    if (pm25 <= 150.4) return _linear(200, 151, 150.4, 55.5, pm25);
    if (pm25 <= 250.4) return _linear(300, 201, 250.4, 150.5, pm25);
    if (pm25 <= 350.4) return _linear(400, 301, 350.4, 250.5, pm25);
    if (pm25 <= 500.4) return _linear(500, 401, 500.4, 350.5, pm25);
    return 500;
  }

  static int _linear(
    int aqHi,
    int aqLo,
    double concHi,
    double concLo,
    double conc,
  ) {
    return (((aqHi - aqLo) / (concHi - concLo)) * (conc - concLo) + aqLo)
        .round();
  }

  static String getAqiDescription(int aqi) {
    if (aqi <= 50) return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 150) return "Unhealthy for Sensitive Groups";
    if (aqi <= 200) return "Unhealthy";
    if (aqi <= 300) return "Very Unhealthy";
    return "Hazardous";
  }

  static Color getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF00E400); // Green
    if (aqi <= 100) return const Color(0xFFFFFF00); // Yellow
    if (aqi <= 150) return const Color(0xFFFF7E00); // Orange
    if (aqi <= 200) return const Color(0xFFFF0000); // Red
    if (aqi <= 300) return const Color(0xFF8F3F97); // Purple
    return const Color(0xFF7E0023); // Maroon
  }
}
