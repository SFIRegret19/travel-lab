import 'package:latlong2/latlong.dart';

import '../../data/hotel_details.dart';
import '../../data/hotel_reviews.dart';
import '../../data/hotel_rooms.dart';
import '../../data/models/booking.dart';
import '../../data/models/hotel.dart';
import '../parsers.dart';

/// Сторона «сервера»: модели каталога → JSON по `api/openapi.yaml`.

double _round4(double v) => double.parse(v.toStringAsFixed(4));

Json _hotelBase(Hotel h) => {
  'id': h.id,
  'name': h.name,
  'type': h.type,
  'rating': h.rating,
  'reviewsCount': h.reviews,
  'street': h.street,
  'distanceKm': h.distanceKm,
  'pricePerNight': h.price,
  'oldPricePerNight': ?h.oldPrice,
  if (h.badge != HotelBadge.none) 'badge': h.badge.name,
  'recommended': h.recommended,
  'freeCancellation': h.freeCancellation,
  'mealPlan': h.meal.name,
  'stars': h.stars,
  'wifi': h.wifi,
  'parking': h.parking,
  'imageHue': h.imageHue,
};

/// Элемент выдачи: основные поля и координаты для карты.
Json hotelSummaryJson(Hotel h, LatLng position) => {
  ..._hotelBase(h),
  'location': {
    'lat': _round4(position.latitude),
    'lon': _round4(position.longitude),
  },
};

/// Ответ `GET /hotels/{hotelId}`.
Json hotelPageJson(Hotel h) {
  final d = detailsFor(h);
  return {
    ..._hotelBase(h),
    'description': d.description,
    'topAmenities': [for (final a in d.topAmenities) a.name],
    'amenities': [for (final a in d.amenities) a.name],
    'checkIn': {'from': d.checkInFrom, 'to': d.checkInTo},
    'checkOut': {'from': d.checkOutFrom, 'to': d.checkOutTo},
    'rules': [
      for (final (title, note) in d.rules) {'title': title, 'note': ?note},
    ],
    'categoryScores': [
      for (final (category, score) in d.scores)
        {'category': category, 'score': score},
    ],
    'landmark': {'name': d.landmark, 'distanceM': d.landmarkDistanceM},
    'buildYear': d.buildYear,
    'renovationYear': d.renovationYear,
    'roomsCount': d.roomsCount,
    'reviews': [for (final r in reviewsFor(h)) _review(r)],
  };
}

Json _review(Review r) => {
  'author': r.author,
  'date': isoDate(r.date),
  'rating': r.rating,
  'text': r.liked,
  'stay': {'month': isoDate(r.stayMonth).substring(0, 7), 'nights': r.nights},
  'regularGuest': r.regular,
  'hotelReply': ?r.reply,
};

/// Номер с тарифами. [cancelUntil] — последний день бесплатной отмены для
/// тарифов с возвратом.
Json roomJson(Room r, DateTime cancelUntil) => {
  'id': r.id,
  'title': r.title,
  'areaM2': r.area,
  'beds': r.beds,
  'imageHue': r.imageHue,
  'roomsLeft': r.left,
  'amenityGroups': [
    for (final e in r.amenityGroups.entries) {'title': e.key, 'items': e.value},
  ],
  'offers': [
    for (final o in r.offers)
      {
        'id': o.id,
        'mealPlan': o.meal.name,
        'freeCancellationUntil': o.refundable ? isoDate(cancelUntil) : null,
        'pricePerNight': o.price,
        'oldPricePerNight': o.oldPrice,
      },
  ],
};

/// Созданная бронь. [request] — тело `POST /bookings` как пришло от клиента.
Json bookingJson({
  required String id,
  required String number,
  required Hotel hotel,
  required Room room,
  required RoomOffer offer,
  required DateTime cancelUntil,
  required Json request,
  required int total,
  required int paidNow,
}) {
  final payment = request['payment'] as Json;
  return {
    'id': id,
    'number': number,
    'hotel': {
      'name': hotel.name,
      'street': hotel.street,
      'checkIn': {
        'from': detailsFor(hotel).checkInFrom,
        'to': detailsFor(hotel).checkInTo,
      },
      'checkOut': {
        'from': detailsFor(hotel).checkOutFrom,
        'to': detailsFor(hotel).checkOutTo,
      },
    },
    'room': {
      'title': room.title,
      'beds': room.beds,
      'imageHue': room.imageHue,
      'amenities': room.amenities,
    },
    'offer': {
      'mealPlan': offer.meal.name,
      'freeCancellationUntil': offer.refundable ? isoDate(cancelUntil) : null,
    },
    'checkIn': request['checkIn'],
    'checkOut': request['checkOut'],
    'guests': request['guests'],
    'contact': request['contact'],
    'lateCheckout': request['lateCheckout'] ?? false,
    'payment': {
      'mode': payment['mode'],
      'method': payment['method'],
      'total': total,
      'paidNow': paidNow,
    },
  };
}
