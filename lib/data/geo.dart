import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'models/hotel.dart';

/// Центры городов из списка подсказок.
const _cityCenters = {
  'Москва': LatLng(55.7558, 37.6173),
  'Санкт-Петербург': LatLng(59.9343, 30.3351),
  'Сочи': LatLng(43.5855, 39.7231),
  'Казань': LatLng(55.7887, 49.1221),
  'Томск': LatLng(56.4846, 84.9476),
  'Екатеринбург': LatLng(56.8389, 60.6057),
  'Калининград': LatLng(54.7104, 20.4522),
  'Новосибирск': LatLng(55.0084, 82.9357),
};

/// Центр города; для неизвестного названия — центр Москвы.
LatLng cityCenter(String city) => _cityCenters[city] ?? _cityCenters['Москва']!;

/// Положение отеля на карте. Отели каталога вымышленные и не привязаны
/// к городу, поэтому кладём их вокруг центра выбранного города: на
/// расстоянии `distanceKm`, в направлении, зависящем от id отеля.
LatLng hotelPosition(Hotel hotel, String city) {
  final center = cityCenter(city);
  final seed = int.tryParse(hotel.id) ?? hotel.id.hashCode.abs();
  final bearing = (seed * 137.5) % 360 * pi / 180;
  const kmPerDegree = 111.32;
  final dLat = hotel.distanceKm * cos(bearing) / kmPerDegree;
  final dLng =
      hotel.distanceKm *
      sin(bearing) /
      (kmPerDegree * cos(center.latitudeInRad));
  return LatLng(center.latitude + dLat, center.longitude + dLng);
}
