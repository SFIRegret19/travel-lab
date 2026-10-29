import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rooms/booking_selection.dart';

class Order {
  const Order({
    required this.selection,
    required this.checkIn,
    required this.checkOut,
    required this.guestNames,
    required this.email,
    required this.phone,
    required this.total,
    required this.paidNow,
    required this.payMethod,
    required this.lateCheckout,
    required this.number,
  });

  final BookingSelection selection;
  final DateTime checkIn;
  final DateTime checkOut;
  final List<String> guestNames;
  final String email;
  final String phone;

  final int total;

  /// Списано сейчас: вся сумма или первый платёж Сплита.
  final int paidNow;
  final String payMethod;
  final bool lateCheckout;
  final String number;
}

final orderProvider = NotifierProvider<OrderNotifier, Order?>(
  OrderNotifier.new,
);

class OrderNotifier extends Notifier<Order?> {
  @override
  Order? build() => null;

  void place(Order order) => state = order;
}
