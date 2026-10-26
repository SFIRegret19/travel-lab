import '../core/format/formatters.dart';
import 'models/hotel.dart';

/// Тариф на номер. Цены — за одну ночь, как и в каталоге.
class RoomOffer {
  const RoomOffer({
    required this.id,
    required this.meal,
    required this.refundable,
    required this.price,
    this.oldPrice,
  });

  final String id;
  final MealPlan meal;

  /// true — есть бесплатная отмена до дня перед заездом.
  final bool refundable;
  final int price;
  final int? oldPrice;

  int? get discountPercent {
    final old = oldPrice;
    if (old == null || old <= price) return null;
    return ((1 - price / old) * 100).round();
  }
}

/// Номер отеля с набором тарифов.
class Room {
  const Room({
    required this.id,
    required this.title,
    required this.area,
    required this.beds,
    required this.amenityGroups,
    required this.offers,
    required this.imageHue,
    this.left,
  });

  final String id;
  final String title;

  /// Площадь, м².
  final int area;
  final String beds;

  /// Удобства по разделам: название раздела и пункты.
  final Map<String, List<String>> amenityGroups;
  final List<RoomOffer> offers;
  final double imageHue;

  /// Сколько номеров осталось; null — не показывать.
  final int? left;

  /// Все удобства списком, для галочек на карточке.
  List<String> get amenities => [
    for (final items in amenityGroups.values) ...items,
  ];
}

typedef _Spec = (
  String title,
  int area,
  String beds,
  List<String> extras,
  List<double> priceFactors,
);

const _hostel = <_Spec>[
  (
    'Кровать в общем 8-местном номере для мужчин и женщин',
    15,
    '1 односпальная кровать',
    [],
    [1.0, 1.2],
  ),
  ('Кровать в общем 4-местном номере', 12, '1 односпальная кровать', [], [1.5]),
  (
    'Двухместный номер с общей ванной',
    14,
    '2 односпальные кровати',
    ['Общая ванная комната'],
    [2.2],
  ),
];

const _apartments = <_Spec>[
  (
    'Студия',
    28,
    '1 двуспальная кровать',
    ['Кухня', 'Телевизор', 'Кондиционер'],
    [1.0, 1.2],
  ),
  (
    'Апартаменты с одной спальней',
    42,
    '1 двуспальная кровать, 1 диван-кровать',
    ['Кухня', 'Телевизор', 'Кондиционер', 'Стиральная машина'],
    [1.6],
  ),
  (
    'Апартаменты с двумя спальнями',
    60,
    '2 двуспальные кровати',
    ['Кухня', 'Телевизор', 'Кондиционер', 'Стиральная машина'],
    [2.4],
  ),
];

const _hotel = <_Spec>[
  (
    'Стандартный двухместный номер',
    18,
    '1 двуспальная или 2 односпальные кровати',
    ['Телевизор', 'Кондиционер', 'Фен'],
    [1.0, 1.2],
  ),
  (
    'Улучшенный номер',
    24,
    '1 двуспальная кровать',
    ['Телевизор', 'Кондиционер', 'Фен', 'Мини-холодильник'],
    [1.5],
  ),
  (
    'Люкс',
    38,
    '1 двуспальная кровать, 1 диван',
    ['Телевизор', 'Кондиционер', 'Фен', 'Мини-холодильник', 'Халаты'],
    [2.3],
  ),
];

/// Номера отеля. Выводятся из записи каталога детерминированно, так что
/// самый дешёвый тариф первого номера совпадает с ценой отеля в выдаче.
List<Room> roomsFor(Hotel h) {
  final seed = int.tryParse(h.id) ?? h.id.hashCode.abs();
  final specs = switch (h.type) {
    'Хостел' => _hostel,
    'Апартаменты' => _apartments,
    _ => _hotel,
  };

  return [
    for (var r = 0; r < specs.length; r++)
      () {
        final (title, area, beds, extras, factors) = specs[r];
        final isHostel = h.type == 'Хостел';
        return Room(
          id: 'r$r',
          title: title,
          area: area,
          beds: beds,
          imageHue: (h.imageHue + r * 25) % 360,
          left: switch (r) {
            0 => 2 + (seed + 1) % 3,
            2 => 1,
            _ => null,
          },
          amenityGroups: {
            if (h.wifi) 'Интернет и телефония': ['Интернет'],
            if (extras.isNotEmpty)
              isHostel ? 'Ванная комната' : 'В номере': extras,
          },
          offers: [
            for (var j = 0; j < factors.length; j++)
              RoomOffer(
                id: 'o$j',
                meal: h.meal,
                // Самый дешёвый тариф, как в оригинале, без возврата.
                refundable: h.freeCancellation && !(r == 0 && j == 0),
                price: r == 0 && j == 0
                    ? h.price
                    : (h.price * factors[j] / 10).round() * 10,
                oldPrice: r == 0 && j == 0 ? h.oldPrice : null,
              ),
          ],
        );
      }(),
  ];
}

/// Последний день бесплатной отмены: накануне заезда, но не раньше сегодня.
DateTime freeCancelUntil(DateTime? checkIn, DateTime today) {
  final day = (checkIn ?? today).subtract(const Duration(days: 1));
  final date = DateTime(day.year, day.month, day.day);
  return date.isBefore(today) ? today : date;
}

/// Строка про отмену под ценой тарифа и на оформлении.
String cancelText(RoomOffer offer, DateTime until) => offer.refundable
    ? 'Бесплатная отмена до ${formatDayMonth(until)}'
    : 'Оплата не возвращается';
