import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time/today_provider.dart';
import '../features/search/search_params.dart';
import 'hotels_catalog.dart';
import 'models/hotel.dart';

const mockCities = [
  'Москва',
  'Санкт-Петербург',
  'Сочи',
  'Казань',
  'Томск',
  'Екатеринбург',
  'Калининград',
  'Новосибирск',
];

/// «Продолжить поиск»: даты считаются от сегодняшнего дня.
final recentSearchesProvider = Provider<List<SearchParams>>((ref) {
  final today = ref.watch(todayProvider);
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);
  return [
    SearchParams(city: 'Москва', checkIn: day(1), checkOut: day(2)),
    SearchParams(city: 'Томск', checkIn: day(3), checkOut: day(4), adults: 2),
    SearchParams(
      city: 'Санкт-Петербург',
      checkIn: day(5),
      checkOut: day(6),
      adults: 2,
    ),
  ];
});

/// «Недавно смотрели»: отели из общего каталога.
final List<Hotel> recentlyViewed = [hotelById('1')!, hotelById('2')!];
