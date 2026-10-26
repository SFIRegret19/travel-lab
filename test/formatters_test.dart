import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/core/format/formatters.dart';

void main() {
  test('диапазон дат коротко', () {
    expect(formatRangeShort(null, null), 'Заезд — выезд');
    expect(formatRangeShort(DateTime(2026, 9, 25), null), '25 сен — выезд');
    expect(
      formatRangeShort(DateTime(2026, 9, 25), DateTime(2026, 9, 26)),
      '25 — 26 сен',
    );
    expect(
      formatRangeShort(DateTime(2026, 9, 30), DateTime(2026, 10, 2)),
      '30 сен — 2 окт',
    );
  });

  test('диапазон дат полностью', () {
    expect(
      formatRangeLong(DateTime(2026, 9, 25), DateTime(2026, 9, 26)),
      '25 - 26 сентября',
    );
    expect(
      formatRangeLong(DateTime(2026, 9, 30), DateTime(2026, 10, 2)),
      '30 сентября - 2 октября',
    );
  });

  test('склонение гостей', () {
    expect(formatGuests(1), '1 гость');
    expect(formatGuests(2), '2 гостя');
    expect(formatGuests(5), '5 гостей');
    expect(formatGuests(11), '11 гостей');
    expect(formatGuests(21), '21 гость');
  });

  test('цена с неразрывными пробелами', () {
    expect(formatPrice(1975), '1 975 ₽');
    expect(formatPrice(60000), '60 000 ₽');
    expect(formatPrice(999), '999 ₽');
  });
}
