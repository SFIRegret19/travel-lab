import 'hotel.dart';

enum PayMode { full, split }

class BookingGuest {
  const BookingGuest({required this.lastName, required this.firstName});

  final String lastName;
  final String firstName;

  String get fullName => '$lastName $firstName';
}

/// Тело запроса `POST /bookings`.
class BookingRequest {
  const BookingRequest({
    required this.hotelId,
    required this.roomId,
    required this.offerId,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.guests,
    required this.email,
    required this.phone,
    required this.lateCheckout,
    required this.payMode,
    required this.payMethod,
    required this.expectedTotal,
    this.promoCode,
  });

  final String hotelId;
  final String roomId;
  final String offerId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final List<BookingGuest> guests;
  final String email;
  final String phone;
  final bool lateCheckout;
  final PayMode payMode;

  /// Код способа оплаты: `mastercard`, `sbp` или `mir`.
  final String payMethod;
  final int expectedTotal;
  final String? promoCode;

  Map<String, dynamic> toJson() => {
    'hotelId': hotelId,
    'roomId': roomId,
    'offerId': offerId,
    'checkIn': isoDate(checkIn),
    'checkOut': isoDate(checkOut),
    'adults': adults,
    'children': children,
    'guests': [
      for (final g in guests)
        {'lastName': g.lastName, 'firstName': g.firstName},
    ],
    'contact': {'email': email, 'phone': phone},
    'lateCheckout': lateCheckout,
    'promoCode': ?promoCode,
    'payment': {'mode': payMode.name, 'method': payMethod},
    'expectedTotal': expectedTotal,
  };
}

/// Подтверждённая бронь: всё, что показывает экран подтверждения.
class Booking {
  const Booking({
    required this.id,
    required this.number,
    required this.hotelName,
    required this.street,
    required this.checkInTime,
    required this.checkOutTime,
    required this.roomTitle,
    required this.beds,
    required this.roomImageHue,
    required this.roomAmenities,
    required this.mealPlan,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.email,
    required this.phone,
    required this.lateCheckout,
    required this.payMode,
    required this.payMethod,
    required this.total,
    required this.paidNow,
    this.freeCancellationUntil,
  });

  final String id;
  final String number;
  final String hotelName;
  final String street;

  /// «14:00 - 00:00».
  final String checkInTime;
  final String checkOutTime;
  final String roomTitle;
  final String beds;
  final double roomImageHue;
  final List<String> roomAmenities;
  final MealPlan mealPlan;
  final DateTime? freeCancellationUntil;
  final DateTime checkIn;
  final DateTime checkOut;
  final List<BookingGuest> guests;
  final String email;
  final String phone;
  final bool lateCheckout;
  final PayMode payMode;
  final String payMethod;
  final int total;
  final int paidNow;

  int get remaining => total - paidNow;
}

/// «2026-11-20».
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime parseIsoDate(String s) => DateTime.parse(s);
