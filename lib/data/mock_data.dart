import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time/today_provider.dart';
import '../features/search/search_params.dart';
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

/// «Недавно смотрели».
const recentlyViewed = [
  Hotel(
    id: '1',
    name: 'Копенгаген',
    rating: 5.0,
    address: 'Москва, улица Буженинова',
    type: 'Гостиница',
    price: 1975,
    oldPrice: 2079,
    imageHue: 12,
  ),
  Hotel(
    id: '2',
    name: 'The Loft',
    rating: 4.9,
    address: 'Москва, Тверская улица',
    type: 'Гостиница',
    price: 2079,
    imageHue: 200,
  ),
];
