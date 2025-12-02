import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool isFrosted; // If false, it looks more like clear water

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15, // Higher blur = Frosted, Lower = Clear Liquid
    this.opacity = 0.1, // Lower opacity = More transparent/Glassy
    this.color = Colors.white,
    this.borderRadius,
    this.padding,
    this.width,
    this.height,
    this.isFrosted = true,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: br,
            // The "Refraction" / Border Highlight
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                // Specular Highlight (Top Left - Light hitting glass)
                Colors.white.withOpacity(0.4),
                // Middle - Clear
                Colors.white.withOpacity(0.05),
                // Shadow (Bottom Right)
                Colors.white.withOpacity(0.1),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
            boxShadow: [
              // Subtle drop shadow for depth
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
