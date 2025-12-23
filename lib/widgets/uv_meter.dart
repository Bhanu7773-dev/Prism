import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cutout_icon.dart';

class UvMeter extends StatelessWidget {
  final double uvIndex;

  const UvMeter({super.key, required this.uvIndex});

  @override
  Widget build(BuildContext context) {
    Color uvColor = _getUvColor(uvIndex);
    String description = _getUvDescription(uvIndex);

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
                icon: Icons.sunny,
                color: Colors.orangeAccent.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "UV INDEX",
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                uvIndex.toStringAsFixed(0),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.outfit(
                  color: uvColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gradient Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF299501), // Low (Green)
                    Color(0xFFF7E401), // Moderate (Yellow)
                    Color(0xFFF95901), // High (Orange)
                    Color(0xFFD90115), // Very High (Red)
                    Color(0xFF6C49CB), // Extreme (Violet)
                  ],
                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double pos =
                          (uvIndex / 12).clamp(0.0, 1.0) * constraints.maxWidth;
                      return Transform.translate(
                        offset: Offset(pos, 0),
                        child: Container(width: 4, color: Colors.white),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getUvColor(double uv) {
    if (uv <= 2) return const Color(0xFF299501);
    if (uv <= 5) return const Color(0xFFF7E401);
    if (uv <= 7) return const Color(0xFFF95901);
    if (uv <= 10) return const Color(0xFFD90115);
    return const Color(0xFF6C49CB);
  }

  String _getUvDescription(double uv) {
    if (uv <= 2) return "Low";
    if (uv <= 5) return "Moderate";
    if (uv <= 7) return "High";
    if (uv <= 10) return "Very High";
    return "Extreme";
  }
}
