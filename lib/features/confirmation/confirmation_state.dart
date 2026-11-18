import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_providers.dart';
import '../../data/models/booking.dart';

/// Ответ `GET /bookings/{bookingId}` для экрана «Подтверждение».
final bookingProvider = FutureProvider.autoDispose.family<Booking, String>(
  (ref, bookingId) => ref.watch(travelApiProvider).getBooking(bookingId),
  retry: noRetry,
);
