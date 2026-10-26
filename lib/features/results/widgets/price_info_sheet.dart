import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/hotel.dart';

/// Шторка «Информация о цене» для отеля со скидкой.
Future<void> showPriceInfoSheet(BuildContext context, Hotel hotel, int nights) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _PriceInfo(hotel: hotel, nights: nights),
  );
}

class _PriceInfo extends StatelessWidget {
  const _PriceInfo({required this.hotel, required this.nights});

  final Hotel hotel;
  final int nights;

  @override
  Widget build(BuildContext context) {
    final total = hotel.price * nights;
    final before = (hotel.oldPrice ?? hotel.price) * nights;
    final discount = before - total;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о цене',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            _Line(
              title: 'Цена до применения скидок',
              subtitle: formatNights(nights),
              value: formatPrice(before),
            ),
            const SizedBox(height: 16),
            _Line(
              title: 'Приветственная скидка',
              subtitle: 'Скидка от объекта',
              value: '−${formatPrice(discount)}',
              badge: '−${hotel.discountPercent}%',
            ),
            const Divider(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Итого',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                ),
                Text(
                  formatPrice(total),
                  key: const Key('price_total'),
                  style: const TextStyle(fontSize: 22),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceHigh,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Понятно'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.title,
    required this.subtitle,
    required this.value,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16)),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(fontSize: 16)),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.discountPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
