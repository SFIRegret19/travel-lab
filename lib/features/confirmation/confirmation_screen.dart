import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/time/today_provider.dart';
import '../../data/hotel_details.dart';
import '../../data/hotel_rooms.dart';
import '../checkout/order.dart';
import '../checkout/widgets/booking_cards.dart';
import '../hotel/widgets/section_card.dart';
import '../search/search_provider.dart';

/// Экран после оплаты. В оригинале его нет, оформлен в стиле остальных.
class ConfirmationScreen extends ConsumerWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider);

    // Назад с оплаченного заказа возвращаться некуда: ведём на главный.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: order == null ? const _Empty() : _Confirmed(order: order),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Нет оформленного заказа',
                key: Key('confirmation_empty'),
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('confirmation_home'),
                onPressed: () => context.go(Routes.home),
                child: const Text('На главный'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Confirmed extends ConsumerWidget {
  const _Confirmed({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = order.selection;
    final hotel = selection.hotel;
    final offer = selection.offer;
    final params = ref.watch(searchProvider);
    final today = ref.watch(todayProvider);
    final details = detailsFor(hotel);
    final daysUntil = DateTime.utc(
      order.checkIn.year,
      order.checkIn.month,
      order.checkIn.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    final remaining = order.total - order.paidNow;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            key: const Key('confirmation_home'),
            onPressed: () => context.go(Routes.home),
            child: const Text('На главный'),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: const Key('confirmation_scroll'),
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ratingGreen,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Бронирование подтверждено',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Заказ ${order.number}',
                    key: const Key('confirmation_number'),
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    key: const Key('confirmation_copy'),
                    tooltip: 'Скопировать номер заказа',
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: order.number));
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Номер заказа скопирован'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  'Подтверждение отправим на ${order.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              StayCard(
                hotel: hotel,
                address: '${params.displayCity}, ${hotel.street}',
                checkIn: order.checkIn,
                checkOut: order.checkOut,
                daysUntil: daysUntil,
                checkInTime: details.checkInTime,
                checkOutTime: details.checkOutTime,
              ),
              RoomSummaryCard(
                room: selection.room,
                offer: offer,
                cancelText: cancelText(
                  offer,
                  freeCancelUntil(order.checkIn, today),
                ),
              ),
              SectionCard(
                title: 'Гости',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final name in order.guestNames)
                      _Line(Icons.person_outline_rounded, name),
                    _Line(Icons.mail_outline_rounded, order.email),
                    _Line(Icons.phone_outlined, order.phone),
                  ],
                ),
              ),
              SectionCard(
                title: 'Оплата',
                child: Column(
                  children: [
                    _Pair('Способ', order.payMethod),
                    if (order.lateCheckout)
                      const _Pair('Услуги', 'Поздний выезд до 23:00'),
                    _Pair('Стоимость', formatPrice(order.total)),
                    _Pair(
                      'Оплачено сейчас',
                      formatPrice(order.paidNow),
                      key: const Key('confirmation_paid'),
                    ),
                    if (remaining > 0)
                      _Pair(
                        'Остальное',
                        '${formatPrice(remaining)}, 3 платежа',
                        key: const Key('confirmation_remaining'),
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

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17))),
        ],
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}
