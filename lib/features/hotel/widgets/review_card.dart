import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/hotel_reviews.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Карточка отзыва. В карусели имеет фиксированную высоту ([compact]),
/// в списке растёт по содержимому.
class ReviewCard extends StatefulWidget {
  const ReviewCard({super.key, required this.review, this.compact = false});

  final Review review;
  final bool compact;

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  // true — нравится, false — не нравится, null — без оценки.
  bool? _vote;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surface,
                child: Text(
                  r.author.characters.first,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.author,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDate(r.date),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (r.regular)
                const Text(
                  'Наш гость ✓',
                  style: TextStyle(fontSize: 12, color: AppColors.ratingGreen),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: i < r.rating
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: .4),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Что понравилось:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            r.liked,
            maxLines: widget.compact ? 4 : null,
            overflow: widget.compact ? TextOverflow.ellipsis : null,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            r.stay,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _VoteButton(
                icon: Icons.thumb_up_outlined,
                activeIcon: Icons.thumb_up_rounded,
                active: _vote == true,
                onTap: () =>
                    setState(() => _vote = _vote == true ? null : true),
              ),
              const SizedBox(width: 8),
              _VoteButton(
                icon: Icons.thumb_down_outlined,
                activeIcon: Icons.thumb_down_rounded,
                active: _vote == false,
                onTap: () =>
                    setState(() => _vote = _vote == false ? null : false),
              ),
            ],
          ),
          if (r.reply != null && !widget.compact) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ответ отеля',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(r.reply!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 40,
          child: Icon(active ? activeIcon : icon, size: 20),
        ),
      ),
    );
  }
}
