import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_providers.dart';
import '../../data/hotel_details.dart';

/// Ответ `GET /hotels/{hotelId}`: данные для карточки отеля и экрана отзывов.
/// Пока открыта карточка, провайдер жив, и номера с отзывами берут отель из него.
final hotelPageProvider = FutureProvider.autoDispose.family<HotelPage, String>(
  (ref, hotelId) => ref.watch(travelApiProvider).getHotel(hotelId),
  retry: noRetry,
);
