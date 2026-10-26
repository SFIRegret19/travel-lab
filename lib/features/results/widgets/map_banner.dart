import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Баннер «На карте». Карты в v1 нет: рисуем тёмную сетку улиц,
/// кнопка пока ни к чему не ведёт.
class MapBanner extends StatelessWidget {
  const MapBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 184,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E2A3E), Color(0xFF1F3A33)],
                  ),
                ),
              ),
              CustomPaint(painter: _StreetsPainter()),
              Align(
                alignment: const Alignment(0, .62),
                child: Material(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(22),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'На карте',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7);
    final paint = Paint()
      ..color = const Color(0xFF4A5C8F).withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 14; i++) {
      final path = Path()
        ..moveTo(random.nextDouble() * size.width, 0)
        ..quadraticBezierTo(
          random.nextDouble() * size.width,
          size.height * random.nextDouble(),
          random.nextDouble() * size.width,
          size.height,
        );
      canvas.drawPath(path, paint);
    }
    for (var i = 0; i < 7; i++) {
      final y = random.nextDouble() * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (random.nextDouble() - .5) * 60),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
