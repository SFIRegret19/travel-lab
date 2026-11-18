import 'package:flutter/material.dart';

import 'hotel_reviews.dart';
import 'models/hotel.dart';

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

typedef Fact = (String value, String caption);

/// Подробности для страницы отеля в том виде, в каком они приходят от сервера.
class HotelDetails {
  const HotelDetails({
    required this.description,
    required this.topAmenities,
    required this.amenities,
    required this.checkInFrom,
    required this.checkInTo,
    required this.checkOutFrom,
    required this.checkOutTo,
    required this.rules,
    required this.scores,
    required this.landmark,
    required this.landmarkDistanceM,
    required this.objectType,
    required this.buildYear,
    required this.renovationYear,
    required this.roomsCount,
  });

  final String description;
  final List<Amenity> topAmenities;
  final List<Amenity> amenities;
  final String checkInFrom;
  final String checkInTo;
  final String checkOutFrom;
  final String checkOutTo;

  /// Правила проживания: заголовок и необязательное пояснение.
  final List<(String, String?)> rules;

  /// Оценки по категориям, 0–100.
  final List<(String, int)> scores;
  final String landmark;
  final int landmarkDistanceM;
  final String objectType;
  final int buildYear;
  final int renovationYear;
  final int roomsCount;

  String get checkIn => 'С $checkInFrom\nдо $checkInTo';
  String get checkOut => 'С $checkOutFrom\nдо $checkOutTo';
  String get metro => '$landmark, $landmarkDistanceM м';

  List<Fact> get facts => [
    (objectType, 'Тип объекта'),
    ('$buildYear', 'Дата постройки'),
    ('$renovationYear', 'Дата реконструкции'),
    ('$roomsCount', 'Количество номеров'),
  ];
}

/// Ответ `GET /hotels/{hotelId}`: отель, подробности и отзывы одним куском.
class HotelPage {
  const HotelPage({
    required this.hotel,
    required this.details,
    required this.reviews,
  });

  final Hotel hotel;
  final HotelDetails details;
  final List<Review> reviews;
}

/// Подробности отеля, выведенные из записи каталога (данные «сервера»).
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
    checkInFrom: '14:00',
    checkInTo: '00:00',
    checkOutFrom: '00:00',
    checkOutTo: '12:00',
    rules: const [
      ('Стойка регистрации', '24/7'),
      ('Ранний заезд', 'Платно, с 00:00'),
      ('Поздний выезд', 'Платно, до 23:00'),
      ('Ускоренная регистрация заезда/отъезда', null),
    ],
    scores: scores,
    landmark: 'Центр',
    landmarkDistanceM: (h.distanceKm * 350).round(),
    objectType: h.type,
    buildYear: built,
    renovationYear: built + 10 + seed % 8,
    roomsCount: 8 + (seed * 13) % 40,
  );
}

extension HotelDetailsTimes on HotelDetails {
  String get checkInTime => '$checkInFrom - $checkInTo';
  String get checkOutTime => '$checkOutFrom - $checkOutTo';
  String get checkInRule => 'Заезд с $checkInFrom до $checkInTo';
  String get checkOutRule => 'Выезд с $checkOutFrom до $checkOutTo';
}
