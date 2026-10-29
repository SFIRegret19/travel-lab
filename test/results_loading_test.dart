import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/router/app_router.dart';
import 'package:travel_lab/core/router/routes.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:travel_lab/features/results/results_state.dart';
import 'package:travel_lab/features/results/widgets/results_loading.dart';
import 'package:travel_lab/features/search/search_provider.dart';

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
    Duration load = delay,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        todayProvider.overrideWithValue(DateTime(2026, 10, 26)),
        resultsLoadDurationProvider.overrideWithValue(load),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TravelApp()),
    );
    appRouter.go(Routes.results);
    // Анимации загрузки бесконечны, поэтому pumpAndSettle здесь не годится.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return container;
  }

  testWidgets('сначала загрузка с фактом, потом список', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('results_loading')), findsOneWidget);
    expect(find.byKey(const Key('loading_globe')), findsOneWidget);
    expect(find.byKey(const Key('loading_line')), findsOneWidget);
    final fact = tester.widget<Text>(find.byKey(const Key('loading_fact')));
    expect(loadingFacts, contains(fact.data));
    expect(find.byKey(const Key('hotel_card_3')), findsNothing);
    expect(find.byKey(const Key('results_pill')), findsOneWidget);
    expect(find.byKey(const Key('chip_sort')), findsNothing);

    await tester.pump(delay);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('results_loading')), findsNothing);
    expect(find.byKey(const Key('hotel_card_3')), findsOneWidget);
    expect(find.byKey(const Key('chip_sort')), findsOneWidget);
  });

  testWidgets('нулевая задержка показывает список сразу', (tester) async {
    await open(tester, load: Duration.zero);
    expect(find.byKey(const Key('results_loading')), findsNothing);
    expect(find.byKey(const Key('hotel_card_3')), findsOneWidget);
  });

  testWidgets('смена параметров поиска запускает загрузку заново', (
    tester,
  ) async {
    final container = await open(tester);
    await tester.pump(delay);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('results_loading')), findsNothing);

    container.read(searchProvider.notifier).setAdults(2);
    await tester.pump();
    expect(find.byKey(const Key('results_loading')), findsOneWidget);

    await tester.pump(delay);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('results_loading')), findsNothing);
    expect(find.byKey(const Key('hotel_card_3')), findsOneWidget);
  });

  test('в списке фактов нет пустых и повторов', () {
    expect(loadingFacts.every((f) => f.trim().isNotEmpty), isTrue);
    expect(loadingFacts.toSet(), hasLength(loadingFacts.length));
    expect(loadingFacts, contains(randomLoadingFact()));
  });
}
