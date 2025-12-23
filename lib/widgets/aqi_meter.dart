import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/aqi_utils.dart';
import 'cutout_icon.dart';

class AqiMeter extends StatelessWidget {
  final Map<String, double>? airComponents;

  const AqiMeter({super.key, this.airComponents});

  @override
  Widget build(BuildContext context) {
    // Default to 0 if no data
    final pm25 = airComponents?['pm2_5'] ?? 0.0;
    final aqi = AqiUtils.calculateAQI(pm25);
    final description = AqiUtils.getAqiDescription(aqi);
    final color = AqiUtils.getAqiColor(aqi);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CutoutIcon(
                icon: Icons.air,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "AIR QUALITY INDEX",
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Value & Description
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$aqi",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    description.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "PM2.5: ${pm25.round()} µg/m³",
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress Bar / Scale
          LayoutBuilder(
            builder: (context, constraints) {
              const maxAqi = 300.0; // Cap visual scale at 300 for normal range
              final double percent = (aqi / maxAqi).clamp(0.0, 1.0);
              final double markerPos = percent * constraints.maxWidth;

              return Column(
                children: [
                  // The Gradient Bar
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00E400), // Good
                          Color(0xFFFFFF00), // Moderate
                          Color(0xFFFF7E00), // Sensitive
                          Color(0xFFFF0000), // Unhealthy
                          Color(0xFF8F3F97), // Very Unhealthy
                          Color(0xFF7E0023), // Hazardous
                        ],
                        stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // The Marker
                  SizedBox(
                    height: 16,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: (markerPos - 6).clamp(
                            0.0,
                            constraints.maxWidth - 12,
                          ),
                          child: Icon(
                            Icons.arrow_drop_up,
                            color: Colors.white,
                            size: 24,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
