import 'package:flutter/material.dart';

import '../../core/format/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../core/widgets/rating_badge.dart';
import '../../data/models/hotel.dart';

const _pinBlue = Color(0xFF2F6BFF);

class PricePin extends StatelessWidget {
  const PricePin({
    super.key,
    required this.hotel,
    required this.nights,
    required this.selected,
    required this.onTap,
  });

  final Hotel hotel;
  final int nights;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.black : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.white : _pinBlue,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hotel.recommended) ...[
              const Icon(Icons.thumb_up_alt_rounded, size: 16, color: _pinBlue),
              const SizedBox(width: 6),
            ],
            Text(
              formatPrice(hotel.price * nights),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (hotel.discountPercent != null) ...[
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.discountPurple,
                ),
                child: const Center(
                  child: Text(
                    '%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SelectedHotelCard extends StatelessWidget {
  const SelectedHotelCard({
    super.key,
    required this.hotel,
    required this.city,
    required this.nights,
    required this.onTap,
  });

  final Hotel hotel;
  final String city;
  final int nights;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: PhotoPlaceholder(
                  hue: hotel.imageHue,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$city · ${formatDistance(hotel.distanceKm)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingBadge(hotel.rating),
                        const SizedBox(width: 8),
                        Text(
                          formatReviews(hotel.reviews),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatPrice(hotel.price * nights)} · '
                      '${formatNights(nights)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
