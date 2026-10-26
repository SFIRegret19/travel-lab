import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/today_provider.dart';
import 'search_params.dart';

const maxAdults = 10;
const maxChildren = 6;

final searchProvider = NotifierProvider<SearchNotifier, SearchParams>(
  SearchNotifier.new,
);

/// Состояние формы поиска. Правила по гостям живут здесь, а не в виджетах:
/// взрослых не меньше 1, номеров не больше, чем взрослых.
class SearchNotifier extends Notifier<SearchParams> {
  @override
  SearchParams build() => const SearchParams();

  void apply(SearchParams params) => state = params;

  void setCity(String? city) {
    state = city == null
        ? state.copyWith(clearCity: true)
        : state.copyWith(city: city);
  }

  void setType(AccommodationType type) => state = state.copyWith(type: type);

  /// Нажатие на день в календаре. Первое нажатие задаёт заезд, второе,
  /// более позднее, выезд. Нажатие на день не позже заезда (или при уже
  /// выбранном диапазоне) начинает выбор заново.
  void pickDate(DateTime day) {
    final today = ref.read(todayProvider);
    if (day.isBefore(today)) return;

    final from = state.checkIn;
    if (from == null || state.hasFullRange || !day.isAfter(from)) {
      state = state.copyWith(clearDates: true).copyWith(checkIn: day);
    } else {
      state = state.copyWith(checkOut: day);
    }
  }

  void setAdults(int value) {
    final adults = value.clamp(1, maxAdults);
    state = state.copyWith(
      adults: adults,
      rooms: state.rooms > adults ? adults : state.rooms,
    );
  }

  void setChildren(int value) {
    state = state.copyWith(children: value.clamp(0, maxChildren));
  }

  void setRooms(int value) {
    state = state.copyWith(rooms: value.clamp(1, state.adults));
  }
}
