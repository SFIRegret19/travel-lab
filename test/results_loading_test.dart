import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/api/mock/mock_settings.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/router/app_router.dart';
import 'package:travel_lab/core/router/routes.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:travel_lab/features/results/widgets/results_loading.dart';
import 'package:travel_lab/features/search/search_provider.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('GolosText')
      ..addFont(rootBundle.load('assets/fonts/GolosText.ttf'));
    await loader.load();
  });

  const delay = Duration(milliseconds: 500);

  Future<ProviderContainer> open(
    WidgetTester tester, {
    MockSettings? settings,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        todayProvider.overrideWithValue(DateTime(2026, 10, 26)),
        instantMockApi,
      ],
    );
    addTearDown(container.dispose);
    container
        .read(mockSettingsProvider.notifier)
        .update((_) => settings ?? const MockSettings(latency: delay));
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TravelApp()),
    );
    appRouter.go(Routes.results);
    // Анимации загрузки бесконечны, поэтому pumpAndSettle здесь не годится.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return container;
  }

  Future<void> finishLoading(WidgetTester tester) async {
    await tester.pump(delay);
    await tester.pumpAndSettle();
  }

  testWidgets('пока идёт запрос, показана загрузка с фактом', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('results_loading')), findsOneWidget);
    expect(find.byKey(const Key('loading_globe')), findsOneWidget);
    expect(find.byKey(const Key('loading_line')), findsOneWidget);
    final fact = tester.widget<Text>(find.byKey(const Key('loading_fact')));
    expect(loadingFacts, contains(fact.data));
    expect(find.byKey(const Key('hotel_card_3')), findsNothing);
    expect(find.byKey(const Key('results_pill')), findsOneWidget);
    expect(find.byKey(const Key('chip_sort')), findsNothing);

    await finishLoading(tester);
    expect(find.byKey(const Key('results_loading')), findsNothing);
    expect(find.byKey(const Key('hotel_card_3')), findsOneWidget);
    expect(find.byKey(const Key('chip_sort')), findsOneWidget);
  });

  testWidgets('без задержки список виден сразу', (tester) async {
    await open(tester, settings: const MockSettings(latency: Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('results_loading')), findsNothing);
    expect(find.byKey(const Key('hotel_card_3')), findsOneWidget);
  });

  testWidgets('смена параметров поиска запускает загрузку заново', (
    tester,
  ) async {
    final container = await open(tester);
    await finishLoading(tester);
    expect(find.byKey(const Key('results_loading')), findsNothing);

    container.read(searchProvider.notifier).setAdults(2);
    await tester.pump();
    expect(find.byKey(const Key('results_loading')), findsOneWidget);

    await finishLoading(tester);
    expect(find.byKey(const Key('results_loading')), findsNothing);
    expect(find.byKey(const Key('hotel_card_3')), findsOneWidget);
  });

  testWidgets('нет сети: ошибка и «Повторить» возвращает список', (
    tester,
  ) async {
    final container = await open(
      tester,
      settings: const MockSettings(latency: delay, offline: true),
    );
    await finishLoading(tester);
    expect(find.byKey(const Key('error_state')), findsOneWidget);
    expect(find.text('Нет соединения'), findsOneWidget);
    expect(find.byKey(const Key('hotel_card_3')), findsNothing);

    container
        .read(mockSettingsProvider.notifier)
        .update((s) => s.copyWith(offline: false));
    await tester.tap(find.byKey(const Key('error_retry')));
    await tester.pump();
    expect(find.byKey(const Key('results_loading')), findsOneWidget);
    await finishLoading(tester);
    expect(find.byKey(const Key('error_state')), findsNothing);
    expect(find.byKey(const Key('hotel_card_3')), findsOneWidget);
  });

  testWidgets('ошибка сервера 500 показывает «Сервис недоступен»', (
    tester,
  ) async {
    await open(
      tester,
      settings: const MockSettings(latency: delay, serverError: true),
    );
    await finishLoading(tester);
    expect(find.text('Сервис недоступен'), findsOneWidget);
    expect(find.byKey(const Key('error_retry')), findsOneWidget);
  });

  testWidgets('пустая выдача это не ошибка', (tester) async {
    await open(
      tester,
      settings: const MockSettings(latency: delay, noResults: true),
    );
    await finishLoading(tester);
    expect(find.byKey(const Key('error_state')), findsNothing);
    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(find.byKey(const Key('reset_filters')), findsOneWidget);
  });

  test('в списке фактов нет пустых и повторов', () {
    expect(loadingFacts.every((f) => f.trim().isNotEmpty), isTrue);
    expect(loadingFacts.toSet(), hasLength(loadingFacts.length));
    expect(loadingFacts, contains(randomLoadingFact()));
  });
}
