enum HotelBadge {
  none(null),
  fewRooms('Осталось мало номеров'),
  appOnly('Цена только в приложении');

  const HotelBadge(this.label);
  final String? label;
}

/// Отель из каталога. Записи не привязаны к городу: название города
/// подставляется при показе из параметров поиска.
class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    required this.rating,
    required this.street,
    required this.type,
    required this.price,
    this.reviews = 0,
    this.distanceKm = 1,
    this.oldPrice,
    this.badge = HotelBadge.none,
    this.recommended = false,
    this.freeCancellation = false,
    this.breakfast = false,
    this.imageHue = 30,
  });

  final String id;
  final String name;
  final double rating;
  final int reviews;
  final String street;
  final String type;
  final double distanceKm;

  /// Цена за одну ночь.
  final int price;
  final int? oldPrice;
  final HotelBadge badge;
  final bool recommended;
  final bool freeCancellation;
  final bool breakfast;

  /// Оттенок градиента-заглушки вместо фото (0–360).
  final double imageHue;

  bool get isApartment => type == 'Апартаменты';

  int? get discountPercent {
    final old = oldPrice;
    if (old == null || old <= price) return null;
    return ((1 - price / old) * 100).round();
  }
}
