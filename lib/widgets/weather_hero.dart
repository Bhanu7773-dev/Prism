import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class WeatherHero extends StatelessWidget {
  final String temperature;
  final String condition;

  const WeatherHero({
    super.key,
    required this.temperature,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 2. Temperature & Condition Group
        Column(
          children: [
            // Balanced Row for perfect centering
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ghost Degree (for balance)
                Text(
                  '°',
                  style: GoogleFonts.outfit(
                    fontSize: 140,
                    fontWeight: FontWeight.bold,
                    color: Colors.transparent,
                    height: 0.9,
                  ),
                ),
                // Actual Temperature
                Text(
                  temperature,
                  style: GoogleFonts.outfit(
                    fontSize: 140,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 0.9,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(4, 4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Visible Degree
                Text(
                  '°',
                  style: GoogleFonts.outfit(
                    fontSize: 140,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 0.9,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(4, 4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),

            Text(
              condition,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(1, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5, end: 0),
          ],
        ),
      ],
    );
  }
}
