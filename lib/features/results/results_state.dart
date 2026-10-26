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

/// Фильтры выдачи. Дальше сюда добавятся цена, питание, рейтинг и прочее.
class HotelFilters {
  const HotelFilters({this.freeCancellation = false, this.breakfast = false});

  final bool freeCancellation;
  final bool breakfast;

  bool get isEmpty => !freeCancellation && !breakfast;

  HotelFilters copyWith({bool? freeCancellation, bool? breakfast}) {
    return HotelFilters(
      freeCancellation: freeCancellation ?? this.freeCancellation,
      breakfast: breakfast ?? this.breakfast,
    );
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

  void toggleFreeCancellation() {
    state = state.copyWith(freeCancellation: !state.freeCancellation);
  }

  void toggleBreakfast() => state = state.copyWith(breakfast: !state.breakfast);

  void reset() => state = const HotelFilters();
}

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
  if (f.freeCancellation && !h.freeCancellation) return false;
  if (f.breakfast && !h.breakfast) return false;
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
