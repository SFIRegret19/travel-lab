import 'package:flutter/material.dart';

/// Заглушка вместо фотографии: градиент заданного оттенка со значком.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({
    super.key,
    this.hue = 30,
    this.icon = Icons.apartment_rounded,
    this.borderRadius = BorderRadius.zero,
  });

  final double hue;
  final IconData icon;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HSLColor.fromAHSL(1, hue, 0.45, 0.42).toColor(),
              HSLColor.fromAHSL(1, (hue + 40) % 360, 0.5, 0.22).toColor(),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 48,
            color: Colors.white.withValues(alpha: .35),
          ),
        ),
      ),
    );
  }
}
