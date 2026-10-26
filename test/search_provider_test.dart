import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:travel_lab/features/search/search_provider.dart';

void main() {
  final today = DateTime(2026, 10, 26);

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(today)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('гости', () {
    test('взрослых не меньше одного', () {
      final c = makeContainer();
      c.read(searchProvider.notifier).setAdults(0);
      expect(c.read(searchProvider).adults, 1);
    });

    test('номеров не больше, чем взрослых', () {
      final c = makeContainer();
      final n = c.read(searchProvider.notifier);
      n.setRooms(5);
      expect(c.read(searchProvider).rooms, 1);

      n.setAdults(3);
      n.setRooms(3);
      expect(c.read(searchProvider).rooms, 3);

      n.setAdults(2);
      expect(c.read(searchProvider).rooms, 2);
    });

    test('дети не уходят в минус и не превышают предел', () {
      final c = makeContainer();
      final n = c.read(searchProvider.notifier);
      n.setChildren(-1);
      expect(c.read(searchProvider).children, 0);
      n.setChildren(100);
      expect(c.read(searchProvider).children, maxChildren);
    });
  });

  group('выбор дат', () {
    test('первое нажатие задаёт заезд, второе выезд', () {
      final c = makeContainer();
      final n = c.read(searchProvider.notifier);
      n.pickDate(DateTime(2026, 10, 27));
      expect(c.read(searchProvider).checkIn, DateTime(2026, 10, 27));
      expect(c.read(searchProvider).checkOut, isNull);

      n.pickDate(DateTime(2026, 10, 30));
      expect(c.read(searchProvider).checkOut, DateTime(2026, 10, 30));
      expect(c.read(searchProvider).hasFullRange, isTrue);
    });

    test('день не позже заезда начинает выбор заново', () {
      final c = makeContainer();
      final n = c.read(searchProvider.notifier);
      n.pickDate(DateTime(2026, 10, 30));
      n.pickDate(DateTime(2026, 10, 28));
      expect(c.read(searchProvider).checkIn, DateTime(2026, 10, 28));
      expect(c.read(searchProvider).checkOut, isNull);
    });

    test('нажатие при готовом диапазоне сбрасывает выезд', () {
      final c = makeContainer();
      final n = c.read(searchProvider.notifier);
      n.pickDate(DateTime(2026, 10, 27));
      n.pickDate(DateTime(2026, 10, 28));
      n.pickDate(DateTime(2026, 11, 3));
      expect(c.read(searchProvider).checkIn, DateTime(2026, 11, 3));
      expect(c.read(searchProvider).checkOut, isNull);
    });

    test('прошедшие дни игнорируются', () {
      final c = makeContainer();
      c.read(searchProvider.notifier).pickDate(DateTime(2026, 10, 25));
      expect(c.read(searchProvider).checkIn, isNull);
    });
  });
}
