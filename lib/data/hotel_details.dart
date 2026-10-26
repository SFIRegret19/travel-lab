import 'package:flutter/material.dart';

import 'models/hotel.dart';

/// Удобство с названием и значком.
enum Amenity {
  laundry(
    'Прачечная и стиральная машина',
    Icons.local_laundry_service_outlined,
  ),
  delivery('Доставка еды и напитков в номер', Icons.room_service_outlined),
  wifi('Wi-Fi и интернет', Icons.wifi_rounded),
  parking('Парковка', Icons.local_parking_rounded),
  breakfast('Завтрак включён в цену', Icons.free_breakfast_outlined),
  luggage('Хранение багажа', Icons.luggage_outlined),
  cleaning('Ежедневная уборка номера', Icons.cleaning_services_outlined),
  taxi('Вызов такси', Icons.local_taxi_outlined),
  frontDesk('Круглосуточная стойка регистрации', Icons.access_time_rounded);

  const Amenity(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Пара «значение и подпись» для плиток «Об объекте».
typedef Fact = (String value, String caption);

/// Подробности об отеле для его страницы. Выводятся из записи каталога
/// детерминированно, так что для одного id всегда одно и то же.
class HotelDetails {
  const HotelDetails({
    required this.description,
    required this.topAmenities,
    required this.amenities,
    required this.checkIn,
    required this.checkOut,
    required this.rules,
    required this.scores,
    required this.metro,
    required this.facts,
  });

  final String description;

  /// Три удобства под названием отеля.
  final List<Amenity> topAmenities;

  /// Полный список для раздела «Удобства и услуги».
  final List<Amenity> amenities;
  final String checkIn;
  final String checkOut;

  /// Пункты правил: заголовок и пояснение.
  final List<(String, String?)> rules;

  /// Оценки по категориям, 0–100.
  final List<(String, int)> scores;
  final String metro;

  /// Плитки «Об объекте».
  final List<Fact> facts;
}

HotelDetails detailsFor(Hotel h) {
  final seed = int.tryParse(h.id) ?? h.id.hashCode.abs();

  final top = <Amenity>{
    if (h.type == 'Хостел') Amenity.laundry,
    if (h.wifi) Amenity.wifi,
    if (h.breakfast) Amenity.breakfast,
    if (h.parking) Amenity.parking,
    Amenity.delivery,
    Amenity.laundry,
    Amenity.luggage,
    Amenity.cleaning,
  }.take(3).toList();

  final all = <Amenity>[
    Amenity.luggage,
    Amenity.laundry,
    if (h.wifi) Amenity.wifi,
    if (h.parking) Amenity.parking,
    if (h.breakfast) Amenity.breakfast,
    Amenity.delivery,
    Amenity.cleaning,
    Amenity.taxi,
    Amenity.frontDesk,
  ];

  // Оценки считаются от общего рейтинга: чем он выше, тем выше все категории.
  final base = (h.rating * 20).round();
  const offsets = [
    ('Цена/качество', 0),
    ('Качество WiFi', -7),
    ('Расположение', -8),
    ('Чистота номеров', -11),
    ('Обслуживание', -19),
    ('Завтрак', -19),
  ];
  final scores = [
    for (final (label, offset) in offsets)
      (label, (base + offset).clamp(40, 100)),
  ];

  final built = 1985 + (seed * 7) % 30;
  final renovated = built + 10 + seed % 8;
  final rooms = 8 + (seed * 13) % 40;

  return HotelDetails(
    description:
        '${h.type} «${h.name}» находится в удобной части города, рядом с '
        'остановками транспорта и магазинами. На территории работает '
        '${h.wifi ? 'бесплатный Wi-Fi' : 'стойка с информацией для гостей'}, '
        'есть место для хранения багажа, а сотрудники помогут вызвать такси '
        'или подскажут, куда сходить поблизости. Заезд и выезд проходят без '
        'очередей, а в номерах всё необходимое для спокойного отдыха.',
    topAmenities: top,
    amenities: all,
    checkIn: 'С 14:00\nдо 00:00',
    checkOut: 'С 00:00\nдо 12:00',
    rules: const [
      ('Стойка регистрации', '24/7'),
      ('Ранний заезд', 'Платно, с 00:00'),
      ('Поздний выезд', 'Платно, до 23:00'),
      ('Ускоренная регистрация заезда/отъезда', null),
    ],
    scores: scores,
    metro: 'Центр, ${(h.distanceKm * 350).round()} м',
    facts: [
      (h.type, 'Тип объекта'),
      ('$built', 'Дата постройки'),
      ('$renovated', 'Дата реконструкции'),
      ('$rooms', 'Количество номеров'),
    ],
  );
}

/// Время заезда и выезда в двух видах: «14:00 - 00:00» и «Заезд с 14:00 до 00:00».
extension HotelDetailsTimes on HotelDetails {
  String get checkInTime =>
      checkIn.replaceAll('С ', '').replaceAll('\nдо ', ' - ');
  String get checkOutTime =>
      checkOut.replaceAll('С ', '').replaceAll('\nдо ', ' - ');
  String get checkInRule =>
      'Заезд ${checkIn.replaceAll('\n', ' ').replaceFirst('С', 'с')}';
  String get checkOutRule =>
      'Выезд ${checkOut.replaceAll('\n', ' ').replaceFirst('С', 'с')}';
}
