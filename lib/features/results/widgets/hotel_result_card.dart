import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/photo_placeholder.dart';
import '../../../core/widgets/rating_badge.dart';
import '../../../data/models/hotel.dart';

class HotelResultCard extends StatelessWidget {
  const HotelResultCard({
    super.key,
    required this.hotel,
    required this.city,
    required this.nights,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
    required this.onPriceInfo,
  });

  final Hotel hotel;
  final String city;
  final int nights;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onPriceInfo;

  @override
  Widget build(BuildContext context) {
    final badge = hotel.badge.label;
    final discount = hotel.discountPercent;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              _BadgeStrip(hotel.badge),
              const SizedBox(height: 4),
            ],
            SizedBox(
              height: 230,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoPlaceholder(
                    hue: hotel.imageHue,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(badge == null ? 22 : 8),
                      bottom: const Radius.circular(22),
                    ),
                  ),
                  if (hotel.recommended)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: _RecommendedTag(),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      key: Key('fav_${hotel.id}'),
                      onPressed: onFavorite,
                      icon: Icon(
                        favorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: favorite ? Colors.redAccent : Colors.white,
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: _PageDots(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hotel.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              '$city · ${formatDistance(hotel.distanceKm)} · ${hotel.type}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                RatingBadge(hotel.rating),
                const SizedBox(width: 8),
                Text(
                  formatReviews(hotel.reviews),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  formatPrice(hotel.price * nights),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (discount != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.discountPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '−$discount%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    formatPrice(hotel.oldPrice! * nights),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.discountPurple,
                    ),
                  ),
                  GestureDetector(
                    key: Key('price_info_${hotel.id}'),
                    onTap: onPriceInfo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              formatNights(nights),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip(this.badge);

  final HotelBadge badge;

  @override
  Widget build(BuildContext context) {
    final appOnly = badge == HotelBadge.appOnly;
    return Container(
      height: 36,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
          bottom: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            appOnly ? Icons.phone_iphone_rounded : Icons.bolt_rounded,
            size: 18,
            color: appOnly ? AppColors.discountPurple : AppColors.boltYellow,
          ),
          const SizedBox(width: 6),
          Text(
            badge.label!,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _RecommendedTag extends StatelessWidget {
  const _RecommendedTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: Colors.white,
            child: Icon(Icons.thumb_up_rounded, size: 15, color: Colors.blue),
          ),
          SizedBox(width: 6),
          Text('Рекомендуем', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: i == 0 ? 14 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: i == 0 ? 1 : .45),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
