import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/data/hotels_catalog.dart';
import 'package:travel_lab/data/models/hotel.dart';
import 'package:travel_lab/features/results/results_state.dart';
import 'package:travel_lab/features/search/search_params.dart';

List<Hotel> run({
  SearchParams params = const SearchParams(),
  HotelFilters filters = const HotelFilters(),
  SortOrder order = SortOrder.popular,
}) => applyResults(hotelsCatalog, params, filters, order);

Hotel hotel(
  String id, {
  double rating = 4,
  int price = 100,
  String type = 'Х',
}) {
  return Hotel(
    id: id,
    name: id,
    rating: rating,
    street: '',
    type: type,
    price: price,
  );
}

void main() {
  group('сортировка', () {
    test('популярные идут в порядке каталога', () {
      expect(run().map((h) => h.id), hotelsCatalog.map((h) => h.id));
    });

    test('сначала дешевле и сначала дороже', () {
      final cheaper = run(order: SortOrder.cheaper)
          .map((h) => h.price)
          .toList();
      expect(cheaper, orderedEquals([...cheaper]..sort()));
      final pricier = run(order: SortOrder.pricier)
          .map((h) => h.price)
          .toList();
      expect(pricier, orderedEquals([...pricier]..sort((a, b) => b - a)));
    });

    test('высокий рейтинг', () {
      final ratings = run(order: SortOrder.rating)
          .map((h) => h.rating)
          .toList();
      expect(
        ratings,
        orderedEquals([...ratings]..sort((a, b) => b.compareTo(a))),
      );
    });

    test('ближайшие', () {
      final km = run(order: SortOrder.nearest)
          .map((h) => h.distanceKm)
          .toList();
      expect(km, orderedEquals([...km]..sort()));
    });

    test('при равных значениях сохраняется порядок каталога', () {
      final sorted = applyResults(
        [hotel('a'), hotel('b'), hotel('c', price: 50)],
        const SearchParams(),
        const HotelFilters(),
        SortOrder.cheaper,
      );
      expect(sorted.map((h) => h.id), ['c', 'a', 'b']);
    });
  });

  group('фильтры', () {
    test('бесплатная отмена и завтрак', () {
      final free = run(filters: const HotelFilters(freeCancellation: true));
      expect(free, isNotEmpty);
      expect(free.every((h) => h.freeCancellation), isTrue);

      final both = run(
        filters: const HotelFilters(freeCancellation: true, breakfast: true),
      );
      expect(both.every((h) => h.freeCancellation && h.breakfast), isTrue);
      expect(both.length, lessThanOrEqualTo(free.length));
    });

    test('тип жилья из формы поиска', () {
      final apartments = run(
        params: const SearchParams(type: AccommodationType.apartments),
      );
      expect(apartments, isNotEmpty);
      expect(apartments.every((h) => h.isApartment), isTrue);

      final hotels = run(
        params: const SearchParams(type: AccommodationType.hotels),
      );
      expect(hotels.any((h) => h.isApartment), isFalse);
    });

    test('если ничего не подходит, выдача пустая', () {
      final result = applyResults(
        [hotel('x')],
        const SearchParams(),
        const HotelFilters(breakfast: true),
        SortOrder.popular,
      );
      expect(result, isEmpty);
    });
  });

  group('скидка и ночи', () {
    test('процент скидки считается от старой цены', () {
      expect(hotelById('3')!.discountPercent, 10);
      expect(hotelById('2')!.discountPercent, isNull);
    });

    test('ночей не меньше одной, без дат одна', () {
      expect(const SearchParams().nights, 1);
      final p = SearchParams(
        checkIn: DateTime(2026, 10, 27),
        checkOut: DateTime(2026, 10, 30),
      );
      expect(p.nights, 3);
    });

    test('любой id каталога находится', () {
      for (final h in hotelsCatalog) {
        expect(hotelById(h.id), same(h));
      }
      expect(hotelById('нет'), isNull);
    });
  });
}
