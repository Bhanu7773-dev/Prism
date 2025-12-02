import 'package:flutter/material.dart';

class CutoutIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const CutoutIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Soft Shadow (Depth)
        Positioned(
          top: 2,
          left: 2,
          child: Icon(icon, size: size, color: Colors.black.withOpacity(0.2)),
        ),

        // 2. Main Icon (White with subtle gradient hint via opacity if needed, but user asked for complete white)
        Icon(icon, size: size, color: Colors.white),
      ],
    );
  }
}
