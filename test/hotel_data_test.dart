import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/data/hotel_details.dart';
import 'package:travel_lab/data/hotel_reviews.dart';
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
