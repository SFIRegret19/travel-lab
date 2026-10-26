import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/time/today_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // В тестах по умолчанию шрифт Ahem с очень широкими буквами, поэтому
  // грузим настоящий Golos Text, чтобы размеры совпадали с приложением.
  setUpAll(() async {
    final loader = FontLoader('GolosText')
      ..addFont(rootBundle.load('assets/fonts/GolosText.ttf'));
    await loader.load();
  });

  testWidgets('Сценарий проходит от главного до подтверждения', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [todayProvider.overrideWithValue(DateTime(2026, 10, 26))],
        child: const TravelApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Продолжить поиск'), findsOneWidget);

    // Главный -> поиск.
    await tester.tap(find.byKey(const Key('home_search_pill')));
    await tester.pumpAndSettle();
    expect(find.text('Где будете жить?'), findsWidgets);

    // Выбор города через подсказки.
    await tester.tap(find.byKey(const Key('city_input')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('city_field')), 'Соч');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сочи'));
    await tester.pumpAndSettle();

    // Даты: пока не выбран выезд, «Дальше» недоступна.
    final next = find.byKey(const Key('next_button'));
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.tap(find.byKey(const Key('day_2026-10-27')));
    await tester.pump();
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.tap(find.byKey(const Key('day_2026-10-28')));
    await tester.pump();
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
    await tester.tap(next);
    await tester.pumpAndSettle();

    // Гости -> результаты.
    await tester.tap(find.byKey(const Key('adults_plus')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('search_button')));
    await tester.pumpAndSettle();
    expect(find.text('Результаты'), findsOneWidget);

    for (final step in const [
      ('Открыть отель', 'Карточка отеля'),
      ('Выбрать номер', 'Выбор номера'),
      ('Выбрать', 'Оформление'),
      ('Оплатить', 'Подтверждение'),
    ]) {
      await tester.tap(find.text(step.$1));
      await tester.pumpAndSettle();
      expect(find.text(step.$2), findsOneWidget);
    }
  });
}
