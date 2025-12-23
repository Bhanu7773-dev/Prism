import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeelsLikeCard extends StatelessWidget {
  final double temp;
  final double feelsLike;
  final double humidity;
  final double windSpeed;

  const FeelsLikeCard({
    super.key,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
  });

  @override
  Widget build(BuildContext context) {
    String reason = "Similar to actual temp.";
    if (feelsLike < temp - 2) reason = "Wind makes it feel cooler.";
    if (feelsLike > temp + 2) reason = "Humidity makes it feel warmer.";

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
          Text(
            "FEELS LIKE",
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${feelsLike.round()}°",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            reason,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
