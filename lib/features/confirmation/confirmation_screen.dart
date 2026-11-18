import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/time/today_provider.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/hotel_rooms.dart';
import '../../data/models/booking.dart';
import '../checkout/widgets/booking_cards.dart';
import '../checkout/widgets/payment_cards.dart';
import '../hotel/widgets/section_card.dart';
import '../search/search_provider.dart';
import 'confirmation_state.dart';

/// Экран после оплаты. В оригинале его нет, оформлен в стиле остальных.
class ConfirmationScreen extends ConsumerWidget {
  const ConfirmationScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingProvider(bookingId));

    // Назад с оплаченного заказа возвращаться некуда: ведём на главный.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: booking.isLoading
          ? const _Loading()
          : booking.hasError
          ? Scaffold(
              body: SafeArea(
                child: ErrorState(
                  error: booking.error!,
                  onRetry: () => ref.invalidate(bookingProvider(bookingId)),
                  onBack: () => context.go(Routes.home),
                ),
              ),
            )
          : _Confirmed(booking: booking.requireValue),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('confirmation_loading'),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 32),
            Skeleton(height: 88, width: 88, radius: 44),
            SizedBox(height: 20),
            Skeleton(height: 32, width: 280),
            SizedBox(height: 12),
            Skeleton(height: 20, width: 160),
            SizedBox(height: 24),
            SkeletonCard(lines: 4),
            SkeletonCard(lines: 3),
          ],
        ),
      ),
    );
  }
}

class _Confirmed extends ConsumerWidget {
  const _Confirmed({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;
    final params = ref.watch(searchProvider);
    final today = ref.watch(todayProvider);
    final daysUntil = DateTime.utc(
      b.checkIn.year,
      b.checkIn.month,
      b.checkIn.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    final room = Room(
      id: '',
      title: b.roomTitle,
      area: 0,
      beds: b.beds,
      amenityGroups: {'': b.roomAmenities},
      offers: const [],
      imageHue: b.roomImageHue,
    );
    final offer = RoomOffer(
      id: '',
      meal: b.mealPlan,
      refundable: b.freeCancellationUntil != null,
      price: 0,
      freeCancellationUntil: b.freeCancellationUntil,
    );
    final payMethod = payMethods.firstWhere(
      (m) => m.code == b.payMethod,
      orElse: () => payMethods.first,
    );

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
                    'Заказ ${b.number}',
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
                      Clipboard.setData(ClipboardData(text: b.number));
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
                  'Подтверждение отправим на ${b.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              StayCard(
                hotelName: b.hotelName,
                address: '${params.displayCity}, ${b.street}',
                checkIn: b.checkIn,
                checkOut: b.checkOut,
                daysUntil: daysUntil,
                checkInTime: b.checkInTime,
                checkOutTime: b.checkOutTime,
              ),
              RoomSummaryCard(
                room: room,
                offer: offer,
                cancelText: cancelText(offer),
              ),
              SectionCard(
                title: 'Гости',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final guest in b.guests)
                      _Line(Icons.person_outline_rounded, guest.fullName),
                    _Line(Icons.mail_outline_rounded, b.email),
                    _Line(Icons.phone_outlined, b.phone),
                  ],
                ),
              ),
              SectionCard(
                title: 'Оплата',
                child: Column(
                  children: [
                    _Pair('Способ', payMethod.label),
                    if (b.lateCheckout)
                      const _Pair('Услуги', 'Поздний выезд до 23:00'),
                    _Pair('Стоимость', formatPrice(b.total)),
                    _Pair(
                      'Оплачено сейчас',
                      formatPrice(b.paidNow),
                      key: const Key('confirmation_paid'),
                    ),
                    if (b.remaining > 0)
                      _Pair(
                        'Остальное',
                        '${formatPrice(b.remaining)}, 3 платежа',
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
