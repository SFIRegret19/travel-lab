import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/hotel_details.dart';
import '../../data/hotel_rooms.dart';
import '../../data/models/hotel.dart';

class BookingSelection {
  const BookingSelection({
    required this.hotel,
    required this.details,
    required this.room,
    required this.offer,
  });

  final Hotel hotel;
  final HotelDetails details;
  final Room room;
  final RoomOffer offer;
}

final bookingSelectionProvider =
    NotifierProvider<BookingSelectionNotifier, BookingSelection?>(
      BookingSelectionNotifier.new,
    );

class BookingSelectionNotifier extends Notifier<BookingSelection?> {
  @override
  BookingSelection? build() => null;

  void select(BookingSelection selection) => state = selection;
}
