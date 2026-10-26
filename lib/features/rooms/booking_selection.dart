import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/hotel_rooms.dart';
import '../../data/models/hotel.dart';

/// Выбранный тариф: отель, номер и предложение. Нужен оформлению
/// и подтверждению.
class BookingSelection {
  const BookingSelection({
    required this.hotel,
    required this.room,
    required this.offer,
  });

  final Hotel hotel;
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
