import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Зелёная плашка с оценкой, как в списках оригинала.
class RatingBadge extends StatelessWidget {
  const RatingBadge(this.rating, {super.key});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ratingGreen,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rating.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
