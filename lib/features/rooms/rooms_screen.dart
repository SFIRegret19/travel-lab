import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/skeleton.dart';
import '../hotel/hotel_state.dart';
import '../search/search_provider.dart';
import 'booking_selection.dart';
import 'rooms_state.dart';
import 'widgets/room_card.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(searchProvider);
    final page = ref.watch(hotelPageProvider(hotelId));
    final rooms = ref.watch(roomsProvider(hotelId));

    final loading = page.isLoading || rooms.isLoading;
    final error = page.hasError
        ? page.error
        : (rooms.hasError ? rooms.error : null);

    void retry() {
      ref.invalidate(hotelPageProvider(hotelId));
      ref.invalidate(roomsProvider(hotelId));
    }

    final Widget body;
    if (loading) {
      body = const _RoomsSkeleton();
    } else if (error != null) {
      body = ErrorState(
        error: error,
        onRetry: retry,
        onBack: () => context.pop(),
      );
    } else if (rooms.requireValue.isEmpty) {
      body = _NoRooms(
        onChangeDates: () => context.push(Routes.search, extra: true),
      );
    } else {
      final hotelPage = page.requireValue;
      body = ListView(
        key: const Key('rooms_list'),
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        children: [
          for (final room in rooms.requireValue)
            RoomCard(
              key: Key('room_${room.id}'),
              room: room,
              nights: params.nights,
              onSelect: (offer) {
                ref
                    .read(bookingSelectionProvider.notifier)
                    .select(
                      BookingSelection(
                        hotel: hotelPage.hotel,
                        details: hotelPage.details,
                        room: room,
                        offer: offer,
                      ),
                    );
                context.push(Routes.checkout);
              },
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          key: const Key('rooms_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              page.value?.hotel.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Text(
              '${formatRangeShort(params.checkIn, params.checkOut)}  '
              'Гостей: ${params.guests}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: body,
    );
  }
}

/// Пока номера грузятся: серые карточки на месте номеров.
class _RoomsSkeleton extends StatelessWidget {
  const _RoomsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('rooms_loading'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      children: const [
        SkeletonCard(lines: 5),
        SkeletonCard(lines: 5),
        SkeletonCard(lines: 5),
      ],
    );
  }
}

/// Сервер ответил `200` с пустым списком: на эти даты номеров нет.
class _NoRooms extends StatelessWidget {
  const _NoRooms({required this.onChangeDates});

  final VoidCallback onChangeDates;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('rooms_empty'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет свободных номеров',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'На выбранные даты свободных номеров нет. Попробуйте изменить даты.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('rooms_change_dates'),
            onPressed: onChangeDates,
            child: const Text('Изменить даты'),
          ),
        ],
      ),
    );
  }
}
