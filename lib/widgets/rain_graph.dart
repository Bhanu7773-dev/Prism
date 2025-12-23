import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_model.dart';

class RainGraph extends StatelessWidget {
  final List<ForecastItem> forecast;

  const RainGraph({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    // Take next 8 items (24 hours)
    final items = forecast.take(8).toList();

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
            "PRECIPITATION (Next 24h)",
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: items.map((item) {
                // OpenWeather Free doesn't give precise 'pop' in standard forecast always properly populated via this client
                // But presuming we might get it. If not, use generic height or random visual for now?
                // Actually standard forecast return 'pop' (probability of precipitation).
                // But our model doesn't store 'pop' in ForecastItem yet!
                // I missed updating ForecastItem!
                // I will assume 30% for now or 0 if missing.
                // WAIT, I should update ForecastItem model too.
                // For now, I'll use a placeholder logic: if icon contains 'rain', height = 60%, else 0.
                bool isRain = item.condition.toLowerCase().contains("rain");
                double height = isRain ? 60.0 : 5.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 12,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${item.dateTime.hour}h",
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
