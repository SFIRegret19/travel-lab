import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/hotels_catalog.dart';
import '../../data/models/hotel.dart';
import '../search/search_params.dart';
import '../search/search_provider.dart';

enum SortOrder {
  popular('Популярные'),
  cheaper('Сначала дешевле'),
  pricier('Сначала дороже'),
  rating('Высокий рейтинг'),
  nearest('Ближайшие');

  const SortOrder(this.label);
  final String label;
}

/// Верхняя граница ползунка цены. Значение равно границе = «60 000+», то есть
/// без ограничения сверху.
const priceCap = 60000;

/// Фильтры выдачи.
///
/// Правило объединения: внутри группы (типы размещения, питание, звёзды)
/// условия соединяются через «или», между группами через «и».
/// [breakfast] — быстрый чип «С завтраком»: подходит любой тип питания,
/// кроме «Без питания». С выбором в [meals] он складывается по «и».
class HotelFilters {
  const HotelFilters({
    this.priceMin = 0,
    this.priceMax = priceCap,
    this.anyDiscount = false,
    this.types = const {},
    this.meals = const {},
    this.breakfast = false,
    this.freeCancellation = false,
    this.minRating = 0,
    this.stars = const {},
    this.wifi = false,
    this.parking = false,
  });

  /// Границы цены за весь срок проживания, ₽.
  final int priceMin;
  final int priceMax;
  final bool anyDiscount;
  final Set<String> types;
  final Set<MealPlan> meals;
  final bool breakfast;
  final bool freeCancellation;

  /// Порог рейтинга, 0 — без порога.
  final double minRating;
  final Set<int> stars;
  final bool wifi;
  final bool parking;

  bool get hasPrice => priceMin > 0 || priceMax < priceCap;

  bool get isEmpty =>
      !hasPrice &&
      !anyDiscount &&
      types.isEmpty &&
      meals.isEmpty &&
      !breakfast &&
      !freeCancellation &&
      minRating == 0 &&
      stars.isEmpty &&
      !wifi &&
      !parking;

  HotelFilters copyWith({
    int? priceMin,
    int? priceMax,
    bool? anyDiscount,
    Set<String>? types,
    Set<MealPlan>? meals,
    bool? breakfast,
    bool? freeCancellation,
    double? minRating,
    Set<int>? stars,
    bool? wifi,
    bool? parking,
  }) {
    return HotelFilters(
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      anyDiscount: anyDiscount ?? this.anyDiscount,
      types: types ?? this.types,
      meals: meals ?? this.meals,
      breakfast: breakfast ?? this.breakfast,
      freeCancellation: freeCancellation ?? this.freeCancellation,
      minRating: minRating ?? this.minRating,
      stars: stars ?? this.stars,
      wifi: wifi ?? this.wifi,
      parking: parking ?? this.parking,
    );
  }

  HotelFilters toggleType(String type) =>
      copyWith(types: _toggled(types, type));
  HotelFilters toggleMeal(MealPlan meal) =>
      copyWith(meals: _toggled(meals, meal));
  HotelFilters toggleStars(int count) =>
      copyWith(stars: _toggled(stars, count));

  /// Рейтинг выбирается порогом: повторное нажатие на тот же сбрасывает.
  HotelFilters toggleMinRating(double value) =>
      copyWith(minRating: minRating == value ? 0 : value);

  static Set<T> _toggled<T>(Set<T> set, T value) {
    return set.contains(value) ? ({...set}..remove(value)) : {...set, value};
  }
}

final sortProvider = NotifierProvider<SortNotifier, SortOrder>(
  SortNotifier.new,
);

class SortNotifier extends Notifier<SortOrder> {
  @override
  SortOrder build() => SortOrder.popular;

  void set(SortOrder order) => state = order;
}

final filtersProvider = NotifierProvider<FiltersNotifier, HotelFilters>(
  FiltersNotifier.new,
);

class FiltersNotifier extends Notifier<HotelFilters> {
  @override
  HotelFilters build() => const HotelFilters();

  void apply(HotelFilters filters) => state = filters;

  void toggleFreeCancellation() {
    state = state.copyWith(freeCancellation: !state.freeCancellation);
  }

  void toggleBreakfast() => state = state.copyWith(breakfast: !state.breakfast);

  void reset() => state = const HotelFilters();
}

/// Сколько «грузится» выдача при открытии и при смене параметров поиска.
/// Нулевая длительность отключает экран загрузки (так делают тесты).
final resultsLoadDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 2500),
);

/// Выдача: фильтры и сортировка поверх каталога.
final resultsProvider = Provider<List<Hotel>>((ref) {
  return applyResults(
    hotelsCatalog,
    ref.watch(searchProvider),
    ref.watch(filtersProvider),
    ref.watch(sortProvider),
  );
});

/// Чистая функция выдачи. При равных значениях порядок каталога сохраняется:
/// сравнение добивается индексом, потому что `List.sort` не стабилен.
List<Hotel> applyResults(
  List<Hotel> catalog,
  SearchParams params,
  HotelFilters filters,
  SortOrder order,
) {
  final indexed = <(int, Hotel)>[
    for (var i = 0; i < catalog.length; i++)
      if (_matches(catalog[i], params, filters)) (i, catalog[i]),
  ];

  int byOrder(Hotel a, Hotel b) => switch (order) {
    SortOrder.popular => 0,
    SortOrder.cheaper => a.price.compareTo(b.price),
    SortOrder.pricier => b.price.compareTo(a.price),
    SortOrder.rating => b.rating.compareTo(a.rating),
    SortOrder.nearest => a.distanceKm.compareTo(b.distanceKm),
  };

  indexed.sort((a, b) {
    final c = byOrder(a.$2, b.$2);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

bool _matches(Hotel h, SearchParams params, HotelFilters f) {
  switch (params.type) {
    case AccommodationType.any:
      break;
    case AccommodationType.hotels:
      if (h.isApartment) return false;
    case AccommodationType.apartments:
      if (!h.isApartment) return false;
  }

  final total = h.price * params.nights;
  if (total < f.priceMin) return false;
  if (f.priceMax < priceCap && total > f.priceMax) return false;

  if (f.anyDiscount && h.oldPrice == null) return false;
  if (f.types.isNotEmpty && !f.types.contains(h.type)) return false;
  if (f.meals.isNotEmpty && !f.meals.contains(h.meal)) return false;
  if (f.breakfast && !h.breakfast) return false;
  if (f.freeCancellation && !h.freeCancellation) return false;
  if (h.rating < f.minRating) return false;
  if (f.stars.isNotEmpty && !f.stars.contains(h.stars)) return false;
  if (f.wifi && !h.wifi) return false;
  if (f.parking && !h.parking) return false;
  return true;
}

/// Избранное: множество id отелей.
final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
  }
}
