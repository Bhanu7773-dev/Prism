import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cutout_icon.dart';

class MoonPhaseWidget extends StatelessWidget {
  final String phaseName;

  const MoonPhaseWidget({super.key, required this.phaseName});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              CutoutIcon(
                icon: Icons.nightlight_round,
                color: Colors.blueGrey.shade100,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "MOON PHASE",
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
          Center(
            child: Column(
              children: [
                Icon(
                  _getMoonIcon(phaseName),
                  size: 48,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 12),
                Text(
                  phaseName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMoonIcon(String name) {
    if (name.contains("New")) return Icons.circle_outlined;
    if (name.contains("Full")) return Icons.circle;
    return Icons.wb_twilight; // Fallback generic moon
  }
}
