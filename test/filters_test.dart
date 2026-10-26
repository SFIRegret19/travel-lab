import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/core/format/formatters.dart';
import 'package:travel_lab/data/hotels_catalog.dart';
import 'package:travel_lab/data/models/hotel.dart';
import 'package:travel_lab/features/results/results_state.dart';
import 'package:travel_lab/features/search/search_params.dart';

List<Hotel> run(
  HotelFilters filters, {
  SearchParams params = const SearchParams(),
}) => applyResults(hotelsCatalog, params, filters, SortOrder.popular);

void main() {
  group('цена', () {
    test('считается за весь срок проживания', () {
      final twoNights = SearchParams(
        checkIn: DateTime(2026, 10, 27),
        checkOut: DateTime(2026, 10, 29),
      );
      final result = run(
        const HotelFilters(priceMin: 3000, priceMax: 5000),
        params: twoNights,
      );
      expect(result, isNotEmpty);
      expect(
        result.every((h) => h.price * 2 >= 3000 && h.price * 2 <= 5000),
        isTrue,
      );
      // На одну ночь те же границы дают другой набор.
      final oneNight = run(const HotelFilters(priceMin: 3000, priceMax: 5000));
      expect(oneNight.map((h) => h.id), isNot(result.map((h) => h.id)));
    });

    test('верхняя граница «60 000+» не ограничивает', () {
      const f = HotelFilters(priceMin: 1000);
      final result = run(f);
      expect(result.any((h) => h.price >= 8000), isTrue);
      expect(f.hasPrice, isTrue);
      expect(const HotelFilters().hasPrice, isFalse);
    });
  });

  group('объединение условий', () {
    test('внутри группы «или»: типы размещения', () {
      final hostels = run(const HotelFilters(types: {'Хостел'}));
      final both = run(const HotelFilters(types: {'Хостел', 'Апартаменты'}));
      expect(both.length, greaterThan(hostels.length));
      expect(both.every((h) => h.type == 'Хостел' || h.isApartment), isTrue);
    });

    test('между группами «и»: питание и бесплатная отмена', () {
      final result = run(
        const HotelFilters(
          meals: {MealPlan.breakfast, MealPlan.allInclusive},
          freeCancellation: true,
        ),
      );
      expect(result, isNotEmpty);
      expect(
        result.every(
          (h) =>
              h.freeCancellation &&
              (h.meal == MealPlan.breakfast || h.meal == MealPlan.allInclusive),
        ),
        isTrue,
      );
    });

    test('«С завтраком» и «Без питания» вместе дают пустую выдачу', () {
      final result = run(
        const HotelFilters(breakfast: true, meals: {MealPlan.none}),
      );
      expect(result, isEmpty);
    });

    test('звёзды: набор значений', () {
      final result = run(const HotelFilters(stars: {4, 5}));
      expect(result, isNotEmpty);
      expect(result.every((h) => h.stars == 4 || h.stars == 5), isTrue);
    });
  });

  group('отдельные условия', () {
    test('скидка', () {
      final result = run(const HotelFilters(anyDiscount: true));
      expect(result, isNotEmpty);
      expect(result.every((h) => h.oldPrice != null), isTrue);
    });

    test('рейтинг задаётся порогом и сбрасывается повторным нажатием', () {
      final result = run(const HotelFilters(minRating: 4.5));
      expect(result.every((h) => h.rating >= 4.5), isTrue);
      expect(result.length, lessThan(hotelsCatalog.length));

      final once = const HotelFilters().toggleMinRating(4.5);
      expect(once.minRating, 4.5);
      expect(once.toggleMinRating(4.5).minRating, 0);
      expect(once.toggleMinRating(4.0).minRating, 4.0);
    });

    test('Wi-Fi и парковка', () {
      final wifi = run(const HotelFilters(wifi: true));
      expect(wifi.every((h) => h.wifi), isTrue);
      final parking = run(const HotelFilters(parking: true));
      expect(parking.every((h) => h.parking), isTrue);
      expect(parking.length, lessThan(hotelsCatalog.length));
    });
  });

  group('сброс', () {
    test('isEmpty учитывает каждое поле', () {
      expect(const HotelFilters().isEmpty, isTrue);
      expect(const HotelFilters(priceMin: 100).isEmpty, isFalse);
      expect(const HotelFilters(priceMax: 5000).isEmpty, isFalse);
      expect(const HotelFilters(anyDiscount: true).isEmpty, isFalse);
      expect(const HotelFilters(types: {'Хостел'}).isEmpty, isFalse);
      expect(const HotelFilters(meals: {MealPlan.none}).isEmpty, isFalse);
      expect(const HotelFilters(breakfast: true).isEmpty, isFalse);
      expect(const HotelFilters(freeCancellation: true).isEmpty, isFalse);
      expect(const HotelFilters(minRating: 3).isEmpty, isFalse);
      expect(const HotelFilters(stars: {5}).isEmpty, isFalse);
      expect(const HotelFilters(wifi: true).isEmpty, isFalse);
      expect(const HotelFilters(parking: true).isEmpty, isFalse);
    });

    test('reset очищает всё, включая цену и звёзды', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(filtersProvider.notifier)
          .apply(
            const HotelFilters(
              priceMin: 500,
              priceMax: 4000,
              stars: {4},
              types: {'Хостел'},
              wifi: true,
            ),
          );
      expect(container.read(filtersProvider).isEmpty, isFalse);
      container.read(filtersProvider.notifier).reset();
      expect(container.read(filtersProvider).isEmpty, isTrue);
    });
  });

  test('склонение «предложений»', () {
    expect(formatFoundOffers(1), 'Нашли 1 предложение');
    expect(formatFoundOffers(3), 'Нашли 3 предложения');
    expect(formatFoundOffers(5), 'Нашли 5 предложений');
    expect(formatFoundOffers(11), 'Нашли 11 предложений');
    expect(formatFoundOffers(21), 'Нашли 21 предложение');
  });
}
