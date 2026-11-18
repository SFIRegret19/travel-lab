import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/api/mock/mock_settings.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/router/app_router.dart';
import 'package:travel_lab/core/router/routes.dart';
import 'package:travel_lab/core/time/today_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('GolosText')
      ..addFont(rootBundle.load('assets/fonts/GolosText.ttf'));
    await loader.load();
  });

  Future<ProviderContainer> openHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 10, 26))],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TravelApp()),
    );
    appRouter.go(Routes.home);
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> openPanel(WidgetTester tester) async {
    await tester.longPress(find.byKey(const Key('home_demo_trigger')));
    await tester.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester tester, String name) async {
    final finder = find.byKey(Key('demo_switch_$name'));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('обычное нажатие на заголовок панель не открывает', (
    tester,
  ) async {
    await openHome(tester);
    await tester.tap(find.byKey(const Key('home_demo_trigger')));
    await tester.pumpAndSettle();
    expect(find.text('Режим демонстрации'), findsNothing);
  });

  testWidgets(
    'долгое нажатие открывает панель, переключатели меняют заглушку',
    (tester) async {
      final container = await openHome(tester);
      await openPanel(tester);
      expect(find.text('Режим демонстрации'), findsOneWidget);

      await toggle(tester, 'offline');
      await toggle(tester, 'soldOut');
      final s = container.read(mockSettingsProvider);
      expect(s.offline, isTrue);
      expect(s.soldOut, isTrue);
      expect(s.serverError, isFalse);

      await tester.tap(find.text('3 с'));
      await tester.pumpAndSettle();
      expect(
        container.read(mockSettingsProvider).latency,
        const Duration(seconds: 3),
      );
    },
  );

  testWidgets('«Сбросить всё» возвращает исходные режимы', (tester) async {
    final container = await openHome(tester);
    await openPanel(tester);
    await toggle(tester, 'priceChanged');
    await toggle(tester, 'validationError');
    final reset = find.byKey(const Key('demo_reset'));
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();
    final s = container.read(mockSettingsProvider);
    expect(s.priceChanged, isFalse);
    expect(s.validationError, isFalse);
    expect(s.latency, const Duration(milliseconds: 900));
  });

  testWidgets('режим из панели доходит до экрана: нет сети на выдаче', (
    tester,
  ) async {
    await openHome(tester);
    await openPanel(tester);
    await toggle(tester, 'offline');
    final close = find.byKey(const Key('demo_close'));
    await tester.ensureVisible(close);
    await tester.pumpAndSettle();
    await tester.tap(close);
    await tester.pumpAndSettle();

    appRouter.go(Routes.results);
    await tester.pumpAndSettle();
    expect(find.text('Нет соединения'), findsOneWidget);
    expect(find.byKey(const Key('error_retry')), findsOneWidget);
  });
}
