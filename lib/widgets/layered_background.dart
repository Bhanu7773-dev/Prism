import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'weather_cutout.dart';

class LayeredBackground extends StatelessWidget {
  const LayeredBackground({super.key});

  @override
  Widget build(BuildContext context) {
    // Base gradient for the sky
    return Stack(
      children: [
        // 1. Deep Sky Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4A90E2), // Day Sky Top
                Color(0xFF87CEEB), // Day Sky Bottom
              ],
            ),
          ),
        ),

        // 2. Far Clouds (Slower animation, smaller)
        Positioned(
          top: 100,
          left: -50,
          child: _buildCloud(100, 0.6)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveX(
                begin: 0,
                end: 20,
                duration: 4.seconds,
                curve: Curves.easeInOutSine,
              ),
        ),

        // 3. Sun (Rotating)
        Positioned(
          top: 60,
          right: 40,
          child:
              Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 20.seconds),
        ),

        // 4. Middle Clouds
        Positioned(
          top: 180,
          right: -30,
          child: _buildCloud(140, 0.8)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveX(
                begin: 0,
                end: -30,
                duration: 5.seconds,
                curve: Curves.easeInOutSine,
              ),
        ),

        // 5. Foreground Hills (The "Stage")
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 350,
          child:
              WeatherCutout(
                color: const Color(0xFFE0E5EC), // Clay color
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(60),
                  topRight: Radius.circular(60),
                ),
                depth: 40, // Deep shadow for the main stage
                child: Container(), // Content will go here
              ).animate().slideY(
                begin: 1.0,
                end: 0,
                duration: 800.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      ],
    );
  }

  Widget _buildCloud(double width, double opacity) {
    return Container(
      width: width,
      height: width * 0.6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(width / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}
