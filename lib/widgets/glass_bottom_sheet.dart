import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import 'cutout_icon.dart';
import 'sun_path_graph.dart';

class GlassBottomSheet extends StatelessWidget {
  final ForecastData? forecastData;
  final Weather? currentWeather;
  final DraggableScrollableController? controller;

  const GlassBottomSheet({
    super.key,
    this.forecastData,
    this.currentWeather,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Get hourly data (first 12 items)
    final hourlyForecast = forecastData?.list.take(12).toList() ?? [];

    // Get daily data (filter by noon to get one per day, or simple logic)
    // For simplicity, we'll take every 8th item (24h / 3h = 8 items per day)
    final dailyForecast = <ForecastItem>[];
    if (forecastData != null) {
      for (var i = 0; i < forecastData!.list.length; i += 8) {
        dailyForecast.add(forecastData!.list[i]);
      }
    }

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.45,
      minChildSize: 0.45,
      maxChildSize: 0.88,
      snap: true,
      snapAnimationDuration: const Duration(milliseconds: 300),
      builder: (context, scrollController) {
        return RepaintBoundary(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.0,
                  ),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getWeatherGradient(),
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Hourly Forecast Title
                      Text(
                        "Hourly Forecast",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Hourly Forecast List
                      SizedBox(
                        height: 100,
                        child: hourlyForecast.isEmpty
                            ? Center(
                                child: Text(
                                  "Loading...",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: hourlyForecast.length,
                                itemBuilder: (context, index) {
                                  final item = hourlyForecast[index];
                                  final time = DateFormat(
                                    'h a',
                                  ).format(item.dateTime);
                                  return Container(
                                    width: 70,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: index == 0
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          time,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        CutoutIcon(
                                          icon: _getIcon(item.condition),
                                          color: Colors.white.withOpacity(0.8),
                                          size: 24,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "${item.temperature.round()}°",
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 32),

                      // Weather Details Grid
                      if (currentWeather != null) ...[
                        Text(
                          "Details",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth = (constraints.maxWidth - 24) / 3;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildDetailItem(
                                  "Feels Like",
                                  "${currentWeather!.feelsLike.round()}°",
                                  Icons.thermostat,
                                  itemWidth,
                                ),
                                _buildDetailItem(
                                  "Humidity",
                                  "${currentWeather!.humidity}%",
                                  Icons.water_drop,
                                  itemWidth,
                                ),
                                _buildDetailItem(
                                  "Wind",
                                  "${currentWeather!.windSpeed} m/s",
                                  Icons.air,
                                  itemWidth,
                                ),
                                _buildDetailItem(
                                  "Pressure",
                                  "${currentWeather!.pressure} hPa",
                                  Icons.speed,
                                  itemWidth,
                                ),
                                _buildDetailItem(
                                  "Visibility",
                                  "${(currentWeather!.visibility / 1000).toStringAsFixed(1)} km",
                                  Icons.visibility,
                                  itemWidth,
                                ),
                                _buildDetailItem(
                                  "Sunset",
                                  DateFormat(
                                    'h:mm a',
                                  ).format(currentWeather!.sunset),
                                  Icons.wb_twilight,
                                  itemWidth,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Sun/Moon Path Graph
                        CelestialPathGraph(
                          sunrise: currentWeather!.sunrise,
                          sunset: currentWeather!.sunset,
                          currentTime: currentWeather!.localTime,
                          timezoneOffset: currentWeather!.timezoneOffset,
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Daily Forecast Title
                      Text(
                        "5-Day Forecast",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daily Forecast List
                      dailyForecast.isEmpty
                          ? Center(
                              child: Text(
                                "Loading...",
                                style: GoogleFonts.outfit(color: Colors.white),
                              ),
                            )
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: dailyForecast.length,
                              itemBuilder: (context, index) {
                                final item = dailyForecast[index];
                                final day = DateFormat(
                                  'EEEE',
                                ).format(item.dateTime);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          day,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          CutoutIcon(
                                            icon: Icons.water_drop,
                                            size: 12,
                                            color: Colors.blue[200]!,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${item.humidity}%",
                                            style: GoogleFonts.outfit(
                                              color: Colors.blue[200],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      CutoutIcon(
                                        icon: _getIcon(item.condition),
                                        color: Colors.white.withOpacity(0.8),
                                        size: 24,
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          "${item.temperature.round()}°",
                                          textAlign: TextAlign.end,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).animate().slideY(
      begin: 1.0,
      end: 0,
      duration: 800.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CutoutIcon(
            icon: icon,
            size: 20,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return Icons.water_drop;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'clear':
        return Icons.wb_sunny;
      default:
        return Icons.wb_sunny;
    }
  }

  /// Returns gradient colors based on current weather condition and time of day
  List<Color> _getWeatherGradient() {
    final condition = currentWeather?.condition.toLowerCase() ?? '';
    final now = currentWeather?.localTime;
    final sunrise = currentWeather?.sunrise;
    final sunset = currentWeather?.sunset;

    if (now != null && sunrise != null && sunset != null) {
      final nowMinutes = now.hour * 60 + now.minute;
      final sunriseMinutes = sunrise.hour * 60 + sunrise.minute;
      final sunsetMinutes = sunset.hour * 60 + sunset.minute;

      // Sunrise window: 30 min before to 45 min after sunrise
      final sunriseStart = sunriseMinutes - 30;
      final sunriseEnd = sunriseMinutes + 45;

      // Sunset window: 45 min before to 30 min after sunset
      final sunsetStart = sunsetMinutes - 45;
      final sunsetEnd = sunsetMinutes + 30;

      // Golden hour morning: 45 min to 90 min after sunrise
      final goldenMorningStart = sunriseMinutes + 45;
      final goldenMorningEnd = sunriseMinutes + 90;

      // Golden hour evening: 90 min to 45 min before sunset
      final goldenEveningStart = sunsetMinutes - 90;
      final goldenEveningEnd = sunsetMinutes - 45;

      // Check time periods
      if (nowMinutes >= sunriseStart && nowMinutes <= sunriseEnd) {
        // Sunrise - warm pink/orange/coral tones
        return const [
          Color(0xFFe89b7a), // Coral pink
          Color(0xFFd4785c), // Warm coral
          Color(0xFFb85a40), // Deep coral
        ];
      }

      if (nowMinutes >= sunsetStart && nowMinutes <= sunsetEnd) {
        // Sunset - deep orange/purple/magenta tones
        return const [
          Color(0xFFc76b5c), // Sunset orange-red
          Color(0xFFa84d6b), // Magenta pink
          Color(0xFF7a3878), // Deep purple
        ];
      }

      if (nowMinutes >= goldenMorningStart && nowMinutes <= goldenMorningEnd) {
        // Golden hour morning - soft warm gold
        return const [
          Color(0xFFe8c078), // Soft gold
          Color(0xFFd4a05c), // Warm gold
          Color(0xFFb88040), // Deeper gold
        ];
      }

      if (nowMinutes >= goldenEveningStart && nowMinutes <= goldenEveningEnd) {
        // Golden hour evening - rich warm amber
        return const [
          Color(0xFFd4a060), // Rich amber
          Color(0xFFb88048), // Deep amber
          Color(0xFF985830), // Brown amber
        ];
      }

      // Night time check
      if (nowMinutes < sunriseMinutes || nowMinutes > sunsetMinutes) {
        return const [
          Color(0xFF2d2d4a), // Purple navy
          Color(0xFF1a1a35), // Dark purple
          Color(0xFF0f0f1a), // Almost black
        ];
      }
    }

    // Day time - BRIGHT colors based on weather condition
    switch (condition) {
      case 'clear':
        // Bright warm sunny orange/golden
        return const [
          Color(0xFFe8a849), // Golden orange
          Color(0xFFd4883b), // Warm amber
          Color(0xFFb86b25), // Deep orange
        ];
      case 'clouds':
      case 'mist':
      case 'haze':
        // Soft blue-grey
        return const [
          Color(0xFF8fa4b8), // Light steel blue
          Color(0xFF6b8399), // Medium blue-grey
          Color(0xFF4a6278), // Deeper blue-grey
        ];
      case 'smoke':
      case 'dust':
      case 'fog':
        // Misty grey
        return const [
          Color(0xFFa8a8a8), // Light grey
          Color(0xFF888888), // Medium grey
          Color(0xFF5a5a5a), // Deeper grey
        ];
      case 'rain':
      case 'drizzle':
        // Cool blue rain tones
        return const [
          Color(0xFF5c8db8), // Sky blue
          Color(0xFF4578a0), // Medium blue
          Color(0xFF2d5a7a), // Deep blue
        ];
      case 'thunderstorm':
        // Dramatic purple storm
        return const [
          Color(0xFF8a6bb8), // Light purple
          Color(0xFF6b4d99), // Medium purple
          Color(0xFF4a3378), // Deep purple
        ];
      case 'snow':
        // Bright icy white-blue
        return const [
          Color(0xFFc8d8e8), // Icy white-blue
          Color(0xFFa8c0d8), // Light ice
          Color(0xFF88a8c0), // Cool ice blue
        ];
      default:
        // Default - soft blue for unknown
        return const [
          Color(0xFF7a9bb8), // Soft blue
          Color(0xFF5c8099), // Medium blue
          Color(0xFF3d6078), // Deeper blue
        ];
    }
  }
}
