import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_providers.dart';
import '../../core/time/today_provider.dart';
import '../../data/hotel_rooms.dart';
import '../search/search_provider.dart';

/// Ответ `GET /hotels/{hotelId}/rooms` на даты и гостей из поиска. Пустой
/// список означает «нет свободных номеров», это не ошибка.
final roomsProvider = FutureProvider.autoDispose.family<List<Room>, String>((
  ref,
  hotelId,
) {
  final params = ref.watch(searchProvider);
  final (checkIn, checkOut) = params.stayRange(ref.watch(todayProvider));
  return ref
      .watch(travelApiProvider)
      .getRooms(
        hotelId,
        checkIn: checkIn,
        checkOut: checkOut,
        adults: params.adults,
        children: params.children,
      );
}, retry: noRetry);
