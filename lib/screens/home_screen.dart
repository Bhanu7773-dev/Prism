import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/layered_background.dart';
import '../widgets/glass_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. The 3D Layered World (Background)
          const LayeredBackground(),

          // 2. The Liquid Glass UI (Foreground)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Location Pill (Glass)
                  GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'San Francisco, CA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.5, end: 0),

                  const SizedBox(height: 60),

                  // Big Temperature (Floating directly on 3D layer)
                  Text(
                    '72°',
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(5, 5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ).animate().scale(
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  ),

                  Text(
                    'Mostly Sunny',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const Spacer(),

                  // The "Liquid Glass" Forecast Panel
                  GlassContainer(
                    width: double.infinity,
                    height: 220,
                    opacity: 0.15, // More transparent for "liquid" feel
                    blur: 20,
                    borderRadius: BorderRadius.circular(35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10, bottom: 15),
                          child: Text(
                            "Today's Details",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildGlassItem(
                              Icons.water_drop_outlined,
                              '12%',
                              'Humidity',
                            ),
                            _buildGlassItem(Icons.air, '8 km/h', 'Wind'),
                            _buildGlassItem(
                              Icons.wb_sunny_outlined,
                              '6:42',
                              'Sunset',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().slideY(
                    begin: 0.5,
                    end: 0,
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassItem(IconData icon, String value, String label) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
