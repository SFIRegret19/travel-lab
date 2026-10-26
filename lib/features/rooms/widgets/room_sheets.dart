import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/hotel_rooms.dart';

const _shape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
);

const _cancelRed = Color(0xFFE8164E);

/// Шторка «Все удобства в номере» на весь экран.
Future<void> showRoomAmenitiesSheet(BuildContext context, Room room) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: _shape,
    builder: (_) => _AmenitiesSheet(room: room),
  );
}

class _AmenitiesSheet extends StatelessWidget {
  const _AmenitiesSheet({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    const heading = TextStyle(fontSize: 22, fontWeight: FontWeight.w500);
    const body = TextStyle(fontSize: 17, color: AppColors.textPrimary);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Все удобства в номере',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Material(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    key: const Key('room_amenities_close'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(Icons.close_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(room.title, style: heading),
                const SizedBox(height: 24),
                Text('Площадь: ${room.area} м²', style: body),
                const SizedBox(height: 28),
                const Text('Спальные места', style: heading),
                const SizedBox(height: 12),
                Text(room.beds, style: body),
                if (room.amenities.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const Text('Все удобства в номере', style: heading),
                  const SizedBox(height: 12),
                  for (final item in room.amenities)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_rounded, size: 22),
                          const SizedBox(width: 14),
                          Text(item, style: body),
                        ],
                      ),
                    ),
                ],
                for (final MapEntry(:key, :value)
                    in room.amenityGroups.entries) ...[
                  const SizedBox(height: 28),
                  Text(key, style: heading),
                  const SizedBox(height: 12),
                  for (final item in value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(item, style: body),
                    ),
                ],
                const SizedBox(height: 28),
                const Text('Удобства', style: heading),
                const SizedBox(height: 12),
                Text('Площадь номера кв.м.: ${room.area}', style: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Шторка «Условия отмены». Для тарифа с возвратом показывает срок
/// бесплатной отмены.
Future<void> showCancellationSheet(
  BuildContext context, {
  required bool refundable,
  required DateTime until,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: _shape,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Условия отмены',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 28),
            if (refundable) ...[
              _Stripe(
                color: AppColors.ratingGreen,
                text: 'Бесплатная отмена до ${formatDayMonth(until)}',
              ),
              const SizedBox(height: 20),
              const _Stripe(
                color: _cancelRed,
                text: 'После этого оплата не возвращается',
              ),
            ] else
              const _Stripe(color: _cancelRed, text: 'Оплата не возвращается'),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('cancel_ok'),
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
    ),
  );
}

class _Stripe extends StatelessWidget {
  const _Stripe({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(text, style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
