import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass_container.dart';

class ForecastList extends StatelessWidget {
  const ForecastList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            "7-Day Forecast",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 7,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  GlassContainer(
                        height: 70,
                        blur: 10, // Less blur for "clearer" look
                        opacity: 0.15,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Day Name
                            SizedBox(
                              width: 60,
                              child: Text(
                                _getDay(index),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            // Icon
                            const Icon(
                              Icons.wb_sunny_rounded,
                              color: Colors.amber,
                              size: 28,
                            ),

                            // Temp Bar (Visual)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Row(
                                    children: [
                                      const Spacer(flex: 1),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.blueAccent,
                                                Colors.orangeAccent,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(flex: 1),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // High / Low
                            const Text(
                              "72° / 58°",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .slideX(
                        begin: 0.2,
                        end: 0,
                        delay: (100 * index).ms,
                        duration: 600.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(delay: (100 * index).ms),
            );
          },
        ),
      ],
    );
  }

  String _getDay(int index) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // Just a dummy rotation for demo
    return days[(DateTime.now().weekday + index - 1) % 7];
  }
}
