import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/time/today_provider.dart';
import '../../data/hotel_rooms.dart';
import '../../data/hotels_catalog.dart';
import '../search/search_provider.dart';
import 'booking_selection.dart';
import 'widgets/room_card.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotel = hotelById(hotelId);
    if (hotel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Отель не найден', key: Key('rooms_not_found')),
        ),
      );
    }

    final params = ref.watch(searchProvider);
    final today = ref.watch(todayProvider);
    final rooms = roomsFor(hotel);
    final cancelUntil = freeCancelUntil(params.checkIn, today);

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
              hotel.name,
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
      body: ListView(
        key: const Key('rooms_list'),
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        children: [
          for (final room in rooms)
            RoomCard(
              key: Key('room_${room.id}'),
              room: room,
              nights: params.nights,
              cancelUntil: cancelUntil,
              onSelect: (offer) {
                ref
                    .read(bookingSelectionProvider.notifier)
                    .select(
                      BookingSelection(hotel: hotel, room: room, offer: offer),
                    );
                context.push(Routes.checkout);
              },
            ),
        ],
      ),
    );
  }
}
