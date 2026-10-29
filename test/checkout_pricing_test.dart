import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/data/hotel_rooms.dart';
import 'package:travel_lab/data/hotels_catalog.dart';
import 'package:travel_lab/features/checkout/checkout_pricing.dart';

void main() {
  test('пример из эталона: 1 089 ₽ превращаются в 1 035 ₽', () {
    const price = CheckoutPrice(shownTotal: 1089, discountPercent: 10);
    expect(price.current, 1035);
    expect(1089 - price.current, 54);
    expect(price.gross, 1150);
    expect(price.discount, 115);
    expect(price.total, 1035);
    expect(price.splitPart, 259);
  });

  test('строки расчёта сходятся с «К оплате» для всех тарифов', () {
    for (final hotel in hotelsCatalog) {
      for (final room in roomsFor(hotel)) {
        for (final offer in room.offers) {
          for (final nights in [1, 2, 7]) {
            final shown = offer.price * nights;
            final reason = '${hotel.id} ${room.id} ${offer.id} x$nights';
            final price = CheckoutPrice(
              shownTotal: shown,
              discountPercent: offer.discountPercent,
              lateCheckout: true,
              lateCheckoutPrice: 1200,
              promoPercent: 10,
            );
            expect(price.current, lessThan(shown), reason: reason);
            expect(price.gross - price.discount, price.current, reason: reason);
            expect(
              price.gross - price.discount - price.promo + price.late,
              price.total,
              reason: reason,
            );
            expect(price.promo, greaterThan(0), reason: reason);
            expect(price.splitPart * 4, greaterThanOrEqualTo(price.total));
            expect(price.splitPart * 3, lessThan(price.total));
          }
        }
      }
    }
  });

  test('без услуг и промокода итог равен новой цене', () {
    const price = CheckoutPrice(shownTotal: 5000, discountPercent: null);
    expect(price.total, price.current);
    expect(price.discount, 0);
    expect(price.promo, 0);
    expect(price.late, 0);
  });

  test('промокод ищется без учёта регистра и пробелов', () {
    expect(promoPercentFor(' lab10 '), 10);
    expect(promoPercentFor('LAB10'), 10);
    expect(promoPercentFor('нет'), isNull);
    expect(promoPercentFor(''), isNull);
  });
}
