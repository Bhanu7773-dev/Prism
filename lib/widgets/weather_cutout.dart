import 'package:flutter/material.dart';

class WeatherCutout extends StatelessWidget {
  final Widget child;
  final Color color;
  final double depth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double width;
  final double? height;

  const WeatherCutout({
    super.key,
    required this.child,
    this.color = const Color(0xFFE0E5EC),
    this.depth = 20,
    this.borderRadius,
    this.padding,
    this.width = double.infinity,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final double shadowOffset = depth / 2;
    final double blurRadius = depth;

    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(30),
        boxShadow: [
          // Dark Shadow (Bottom Right)
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: blurRadius,
            spreadRadius: 1,
          ),
          // Light Shadow (Top Left) - Highlight
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            offset: Offset(-shadowOffset, -shadowOffset),
            blurRadius: blurRadius,
            spreadRadius: 1,
          ),
          // Inner glow for extra "pop"
          BoxShadow(
            color: color.withOpacity(0.8),
            offset: const Offset(0, 0),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
