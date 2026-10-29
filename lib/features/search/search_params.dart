enum AccommodationType {
  any('Всё равно'),
  hotels('Отели'),
  apartments('Квартиры');

  const AccommodationType(this.label);
  final String label;
}

class SearchParams {
  const SearchParams({
    this.city,
    this.type = AccommodationType.any,
    this.checkIn,
    this.checkOut,
    this.adults = 1,
    this.children = 0,
    this.rooms = 1,
  });

  final String? city;
  final AccommodationType type;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final int children;
  final int rooms;

  int get guests => adults + children;

  /// Город для показа в адресах отелей: без выбранного города — Москва.
  String get displayCity => city ?? 'Москва';
  bool get hasFullRange => checkIn != null && checkOut != null;

  /// Число ночей. Без дат считаем одну: поиск можно запустить и без них.
  int get nights {
    final from = checkIn;
    final to = checkOut;
    if (from == null || to == null) return 1;
    final days = DateTime.utc(
      to.year,
      to.month,
      to.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
    return days < 1 ? 1 : days;
  }

  /// Даты проживания для оформления. Без выбранных дат считаем, что
  /// заезд сегодня, а выезд через [nights] ночей.
  (DateTime, DateTime) stayRange(DateTime today) {
    final from = checkIn ?? today;
    return (
      DateTime(from.year, from.month, from.day),
      DateTime(from.year, from.month, from.day + nights),
    );
  }

  /// [city], [checkIn] и [checkOut] можно сбросить в null только через
  /// [clearCity] и [clearDates], иначе null означает «не менять».
  SearchParams copyWith({
    String? city,
    bool clearCity = false,
    AccommodationType? type,
    DateTime? checkIn,
    DateTime? checkOut,
    bool clearDates = false,
    int? adults,
    int? children,
    int? rooms,
  }) {
    return SearchParams(
      city: clearCity ? null : (city ?? this.city),
      type: type ?? this.type,
      checkIn: clearDates ? null : (checkIn ?? this.checkIn),
      checkOut: clearDates ? null : (checkOut ?? this.checkOut),
      adults: adults ?? this.adults,
      children: children ?? this.children,
      rooms: rooms ?? this.rooms,
    );
  }
}
