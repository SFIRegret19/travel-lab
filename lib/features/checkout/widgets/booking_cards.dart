import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/photo_placeholder.dart';
import '../../../data/hotel_rooms.dart';
import '../../../data/models/hotel.dart';
import '../../hotel/widgets/section_card.dart';

class StayCard extends StatelessWidget {
  const StayCard({
    super.key,
    required this.hotel,
    required this.address,
    required this.checkIn,
    required this.checkOut,
    required this.daysUntil,
    required this.checkInTime,
    required this.checkOutTime,
  });

  final Hotel hotel;
  final String address;
  final DateTime checkIn;
  final DateTime checkOut;
  final int daysUntil;
  final String checkInTime;
  final String checkOutTime;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      titleWidget: Text(
        hotel.name,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 22,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _DateColumn(
                      caption: daysUntil == 0
                          ? const Text(
                              'Заезд сегодня',
                              style: _captionStyle,
                              key: Key('stay_days_until'),
                            )
                          : Text.rich(
                              key: const Key('stay_days_until'),
                              TextSpan(
                                style: _captionStyle,
                                children: [
                                  const TextSpan(text: 'До заезда '),
                                  TextSpan(
                                    text: formatDays(daysUntil),
                                    style: const TextStyle(
                                      color: AppColors.boltYellow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      date: formatDayWeekday(checkIn),
                      time: checkInTime,
                    ),
                  ),
                  const VerticalDivider(color: AppColors.divider, width: 24),
                  Expanded(
                    child: _DateColumn(
                      caption: const Text('Выезд', style: _captionStyle),
                      date: formatDayWeekday(checkOut),
                      time: checkOutTime,
                      end: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _captionStyle = TextStyle(fontSize: 14, color: AppColors.textSecondary);

class _DateColumn extends StatelessWidget {
  const _DateColumn({
    required this.caption,
    required this.date,
    required this.time,
    this.end = false,
  });

  final Widget caption;
  final String date;
  final String time;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        caption,
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            date,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class RoomSummaryCard extends StatelessWidget {
  const RoomSummaryCard({
    super.key,
    required this.room,
    required this.offer,
    required this.cancelText,
  });

  final Room room;
  final RoomOffer offer;
  final String cancelText;

  @override
  Widget build(BuildContext context) {
    final left = room.left;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (left != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: AppColors.boltYellow,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                formatRoomsLeft(left),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.boltYellow,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 78,
                height: 78,
                child: PhotoPlaceholder(
                  hue: room.imageHue,
                  icon: Icons.bed_outlined,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            room.beds,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          if (room.amenities.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in room.amenities.take(3))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(item, style: const TextStyle(fontSize: 15)),
                  ),
              ],
            ),
          ],
          const Divider(height: 36),
          _IconLine(icon: Icons.credit_card_outlined, text: cancelText),
          const SizedBox(height: 14),
          _IconLine(
            icon: offer.meal == MealPlan.none
                ? Icons.no_meals_outlined
                : Icons.restaurant_outlined,
            text: offer.meal.label,
          ),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 26),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 17))),
      ],
    );
  }
}

class ServicesCard extends StatelessWidget {
  const ServicesCard({
    super.key,
    required this.priceLabel,
    required this.value,
    required this.onChanged,
  });

  final String priceLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Услуги',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Поздний выезд', style: TextStyle(fontSize: 18)),
                Text(
                  priceLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const Key('late_checkout_switch'),
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class RulesCard extends StatelessWidget {
  const RulesCard({super.key, required this.checkIn, required this.checkOut});

  final String checkIn;
  final String checkOut;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Правила проживания',
      child: Column(
        children: [
          _IconLine(icon: Icons.login_rounded, text: checkIn),
          const SizedBox(height: 18),
          _IconLine(icon: Icons.logout_rounded, text: checkOut),
        ],
      ),
    );
  }
}
