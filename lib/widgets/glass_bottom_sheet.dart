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
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
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
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
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
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                  ),
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
}
