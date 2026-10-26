import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/data/hotel_details.dart';
import 'package:travel_lab/data/hotel_reviews.dart';
import 'package:travel_lab/data/hotel_rooms.dart';
import 'package:travel_lab/data/models/hotel.dart';
import 'package:travel_lab/data/hotels_catalog.dart';

void main() {
  test('для каждого отеля каталога есть подробности', () {
    for (final h in hotelsCatalog) {
      final d = detailsFor(h);
      expect(d.description, contains(h.name), reason: h.id);
      expect(d.topAmenities, hasLength(3), reason: h.id);
      expect(d.amenities, isNotEmpty, reason: h.id);
      expect(d.facts, hasLength(4), reason: h.id);
      expect(d.scores, hasLength(6), reason: h.id);
      for (final (_, percent) in d.scores) {
        expect(percent, inInclusiveRange(0, 100), reason: h.id);
      }
    }
  });

  test('подробности детерминированы', () {
    final h = hotelsCatalog.first;
    expect(detailsFor(h).description, detailsFor(h).description);
    expect(detailsFor(h).facts, detailsFor(h).facts);
  });

  test('номера согласованы с записью каталога', () {
    for (final h in hotelsCatalog) {
      final rooms = roomsFor(h);
      expect(rooms, isNotEmpty, reason: h.id);
      final offers = [for (final r in rooms) ...r.offers];
      final first = rooms.first.offers.first;
      expect(first.price, h.price, reason: h.id);
      expect(first.oldPrice, h.oldPrice, reason: h.id);
      expect(first.discountPercent, h.discountPercent, reason: h.id);
      for (final o in offers.skip(1)) {
        expect(o.price, greaterThan(h.price), reason: h.id);
      }
      expect(offers.any((o) => o.refundable), h.freeCancellation, reason: h.id);
      expect(offers.any((o) => o.meal != MealPlan.none), h.breakfast);
      expect({for (final r in rooms) r.id}.length, rooms.length, reason: h.id);
    }
  });

  test('номера детерминированы', () {
    final h = hotelById('3')!;
    expect(
      [for (final r in roomsFor(h)) r.title],
      [for (final r in roomsFor(h)) r.title],
    );
    expect(roomsFor(h).first.left, roomsFor(h).first.left);
  });

  test('срок бесплатной отмены не уходит в прошлое', () {
    final today = DateTime(2026, 10, 26);
    expect(
      freeCancelUntil(DateTime(2026, 11, 5), today),
      DateTime(2026, 11, 4),
    );
    expect(freeCancelUntil(today, today), today);
    expect(freeCancelUntil(null, today), today);
  });

  test('у каждого отеля есть отзывы, порядок зависит от id', () {
    for (final h in hotelsCatalog) {
      final reviews = reviewsFor(h);
      expect(reviews, isNotEmpty, reason: h.id);
      expect(
        reviews.every((r) => r.rating >= 1 && r.rating <= 5),
        isTrue,
        reason: h.id,
      );
    }
    final a = reviewsFor(hotelById('1')!).first.author;
    final b = reviewsFor(hotelById('2')!).first.author;
    expect(a, isNot(b));
  });
}
