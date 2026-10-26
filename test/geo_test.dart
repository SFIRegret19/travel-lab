import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_lab/data/geo.dart';
import 'package:travel_lab/data/hotels_catalog.dart';
import 'package:travel_lab/data/mock_data.dart';

void main() {
  test('у каждого города из подсказок есть свой центр', () {
    final centers = {for (final c in mockCities) cityCenter(c)};
    expect(centers, hasLength(mockCities.length));
  });

  test('неизвестный город падает на центр Москвы', () {
    expect(cityCenter('Нигде'), cityCenter('Москва'));
  });

  test('отель лежит от центра на расстоянии из каталога', () {
    const distance = Distance(roundResult: false);
    for (final city in mockCities) {
      for (final h in hotelsCatalog) {
        final km = distance.as(
          LengthUnit.Kilometer,
          cityCenter(city),
          hotelPosition(h, city),
        );
        expect(km, closeTo(h.distanceKm, 0.05), reason: '${h.id} $city');
      }
    }
  });

  test('отели одного города не совпадают и положение детерминировано', () {
    final points = {
      for (final h in hotelsCatalog)
        (
          hotelPosition(h, 'Москва').latitude.toStringAsFixed(4),
          hotelPosition(h, 'Москва').longitude.toStringAsFixed(4),
        ),
    };
    expect(points, hasLength(hotelsCatalog.length));
    final h = hotelsCatalog.first;
    expect(hotelPosition(h, 'Томск'), hotelPosition(h, 'Томск'));
  });
}
