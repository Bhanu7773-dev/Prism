import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeatherAlertBanner extends StatelessWidget {
  final List<String> alerts;

  const WeatherAlertBanner({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alerts.first.toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }
}
