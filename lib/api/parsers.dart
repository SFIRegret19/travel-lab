import 'package:latlong2/latlong.dart';

import '../data/hotel_details.dart';
import '../data/hotel_reviews.dart';
import '../data/hotel_rooms.dart';
import '../data/models/booking.dart';
import '../data/models/hotel.dart';

/// Разбор ответов сервера: JSON → модели приложения. Поля и типы описаны
/// в `api/openapi.yaml`.
typedef Json = Map<String, dynamic>;

List<Hotel> hotelsFromJson(Json j) => [
  for (final h in j['items'] as List) hotelFromJson(h as Json),
];

Hotel hotelFromJson(Json j) {
  final location = j['location'] as Json?;
  final badge = j['badge'] as String?;
  return Hotel(
    id: j['id'] as String,
    name: j['name'] as String,
    rating: (j['rating'] as num).toDouble(),
    reviews: j['reviewsCount'] as int,
    street: j['street'] as String,
    type: j['type'] as String,
    distanceKm: (j['distanceKm'] as num).toDouble(),
    price: j['pricePerNight'] as int,
    oldPrice: j['oldPricePerNight'] as int?,
    badge: badge == null ? HotelBadge.none : HotelBadge.values.byName(badge),
    recommended: j['recommended'] as bool? ?? false,
    freeCancellation: j['freeCancellation'] as bool? ?? false,
    meal: MealPlan.values.byName(j['mealPlan'] as String? ?? 'none'),
    stars: j['stars'] as int? ?? 0,
    wifi: j['wifi'] as bool? ?? true,
    parking: j['parking'] as bool? ?? false,
    imageHue: (j['imageHue'] as num).toDouble(),
    location: location == null
        ? null
        : LatLng(
            (location['lat'] as num).toDouble(),
            (location['lon'] as num).toDouble(),
          ),
  );
}

HotelPage hotelPageFromJson(Json j) => HotelPage(
  hotel: hotelFromJson(j),
  details: detailsFromJson(j),
  reviews: [for (final r in j['reviews'] as List) reviewFromJson(r as Json)],
);

HotelDetails detailsFromJson(Json j) {
  final checkIn = j['checkIn'] as Json;
  final checkOut = j['checkOut'] as Json;
  final landmark = j['landmark'] as Json;
  List<Amenity> amenities(String key) => [
    for (final a in j[key] as List) Amenity.values.byName(a as String),
  ];
  return HotelDetails(
    description: j['description'] as String,
    topAmenities: amenities('topAmenities'),
    amenities: amenities('amenities'),
    checkInFrom: checkIn['from'] as String,
    checkInTo: checkIn['to'] as String,
    checkOutFrom: checkOut['from'] as String,
    checkOutTo: checkOut['to'] as String,
    rules: [
      for (final r in j['rules'] as List)
        ((r as Json)['title'] as String, r['note'] as String?),
    ],
    scores: [
      for (final s in j['categoryScores'] as List)
        ((s as Json)['category'] as String, s['score'] as int),
    ],
    landmark: landmark['name'] as String,
    landmarkDistanceM: landmark['distanceM'] as int,
    objectType: j['type'] as String,
    buildYear: j['buildYear'] as int,
    renovationYear: j['renovationYear'] as int,
    roomsCount: j['roomsCount'] as int,
  );
}

Review reviewFromJson(Json j) {
  final stay = j['stay'] as Json;
  return Review(
    author: j['author'] as String,
    date: parseIsoDate(j['date'] as String),
    rating: j['rating'] as int,
    liked: j['text'] as String,
    stayMonth: DateTime.parse('${stay['month']}-01'),
    nights: stay['nights'] as int,
    regular: j['regularGuest'] as bool? ?? false,
    reply: j['hotelReply'] as String?,
  );
}

List<Room> roomsFromJson(Json j) => [
  for (final r in j['rooms'] as List) roomFromJson(r as Json),
];

Room roomFromJson(Json j) => Room(
  id: j['id'] as String,
  title: j['title'] as String,
  area: j['areaM2'] as int,
  beds: j['beds'] as String,
  imageHue: (j['imageHue'] as num).toDouble(),
  left: j['roomsLeft'] as int?,
  amenityGroups: {
    for (final g in j['amenityGroups'] as List)
      (g as Json)['title'] as String: [
        for (final item in g['items'] as List) item as String,
      ],
  },
  offers: [for (final o in j['offers'] as List) offerFromJson(o as Json)],
);

RoomOffer offerFromJson(Json j) {
  final until = j['freeCancellationUntil'] as String?;
  return RoomOffer(
    id: j['id'] as String,
    meal: MealPlan.values.byName(j['mealPlan'] as String),
    refundable: until != null,
    price: j['pricePerNight'] as int,
    oldPrice: j['oldPricePerNight'] as int?,
    freeCancellationUntil: until == null ? null : parseIsoDate(until),
  );
}

/// `{from: 14:00, to: 00:00}` → «14:00 - 00:00».
String _timeWindow(Json w) => '${w['from']} - ${w['to']}';

Booking bookingFromJson(Json j) {
  final hotel = j['hotel'] as Json;
  final room = j['room'] as Json;
  final offer = j['offer'] as Json;
  final contact = j['contact'] as Json;
  final payment = j['payment'] as Json;
  final until = offer['freeCancellationUntil'] as String?;
  return Booking(
    id: j['id'] as String,
    number: j['number'] as String,
    hotelName: hotel['name'] as String,
    street: hotel['street'] as String,
    checkInTime: _timeWindow(hotel['checkIn'] as Json),
    checkOutTime: _timeWindow(hotel['checkOut'] as Json),
    roomTitle: room['title'] as String,
    beds: room['beds'] as String,
    roomImageHue: (room['imageHue'] as num).toDouble(),
    roomAmenities: [for (final a in room['amenities'] as List) a as String],
    mealPlan: MealPlan.values.byName(offer['mealPlan'] as String),
    freeCancellationUntil: until == null ? null : parseIsoDate(until),
    checkIn: parseIsoDate(j['checkIn'] as String),
    checkOut: parseIsoDate(j['checkOut'] as String),
    guests: [
      for (final g in j['guests'] as List)
        BookingGuest(
          lastName: (g as Json)['lastName'] as String,
          firstName: g['firstName'] as String,
        ),
    ],
    email: contact['email'] as String,
    phone: contact['phone'] as String,
    lateCheckout: j['lateCheckout'] as bool,
    payMode: PayMode.values.byName(payment['mode'] as String),
    payMethod: payment['method'] as String,
    total: payment['total'] as int,
    paidNow: payment['paidNow'] as int,
  );
}
