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

    // Optimized Glass Effect:
    // Instead of BackdropFilter (which is expensive), we use multiple
    // gradient layers and semi-transparency to mimic the "Glass" look.
    // If 'blur' is 0, we skip the expensive filter entirely.

    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: br,
        // Premium Border Highlight (Simulated light refraction)
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            // Specular Highlight (Top Left)
            Colors.white.withOpacity(0.2),
            // Middle - Transparent
            color.withOpacity(0.02),
            // Bottom Right Glow
            Colors.white.withOpacity(0.05),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          // Subtle drop shadow for depth
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    // Only apply blur if explicitly requested (non-zero blur)
    if (blur > 0) {
      return ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    // Default: High-performance Faux Glass
    return ClipRRect(borderRadius: br, child: content);
  }
}
