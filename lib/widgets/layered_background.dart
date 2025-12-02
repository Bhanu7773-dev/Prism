import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'weather_cutout.dart';
import 'parallax_scenery.dart';

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
          top: 80,
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

        // 3. Sun (Static)
        Positioned(
          top: 60,
          right: 40,
          child: Container(
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
          ),
        ),

        // 4. Middle Clouds
        Positioned(
          top: 280,
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

        // 5. Parallax Scenery (Vectorised 3D Layers)
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ParallaxScenery(height: 350),
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
