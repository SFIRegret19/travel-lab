import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/format/formatters.dart';
import 'package:travel_lab/core/router/app_router.dart';
import 'package:travel_lab/core/router/routes.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:travel_lab/data/hotels_catalog.dart';
import 'package:travel_lab/features/results/results_state.dart';
import 'package:travel_lab/features/search/search_params.dart';
import 'package:travel_lab/features/search/search_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('GolosText')
      ..addFont(rootBundle.load('assets/fonts/GolosText.ttf'));
    await loader.load();
  });

  Future<ProviderContainer> open(
    WidgetTester tester, {
    String route = Routes.map,
    void Function(ProviderContainer)? setup,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        todayProvider.overrideWithValue(DateTime(2026, 10, 26)),
        resultsLoadDurationProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(container.dispose);
    setup?.call(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TravelApp()),
    );
    appRouter.go(route);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('на карте метка у каждого отеля выдачи', (tester) async {
    await open(tester);
    for (final h in hotelsCatalog) {
      expect(find.byKey(Key('map_pin_${h.id}')), findsOneWidget, reason: h.id);
    }
    expect(find.byKey(const Key('map_card')), findsNothing);
  });

  testWidgets('метка показывает цену, нажатие открывает карточку отеля', (
    tester,
  ) async {
    await open(tester);
    // Последняя метка лежит поверх остальных, нажатие точно попадает в неё.
    final hotel = hotelsCatalog.last;
    final pin = find.byKey(Key('map_pin_${hotel.id}'));
    expect(
      find.descendant(of: pin, matching: find.text(formatPrice(hotel.price))),
      findsOneWidget,
    );
    await tester.tap(pin);
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('map_card'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text(hotel.name)),
      findsOneWidget,
    );

    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hotel_select')), findsOneWidget);
  });

  testWidgets('баннер на выдаче открывает карту, «Список» возвращает', (
    tester,
  ) async {
    await open(tester, route: Routes.results);
    await tester.tap(find.byKey(const Key('map_banner')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map_list')), findsOneWidget);
    await tester.tap(find.byKey(const Key('map_list')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('results_pill')), findsOneWidget);

    await tester.tap(find.byKey(const Key('map_banner')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('results_pill')), findsOneWidget);
  });

  testWidgets('фильтры на карте меняют набор меток', (tester) async {
    final container = await open(tester);
    await tester.tap(find.byKey(const Key('map_filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filters_apply')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick_breakfast')));
    await tester.tap(find.byKey(const Key('filters_apply')));
    await tester.pumpAndSettle();
    final expected = container.read(resultsProvider);
    expect(expected.length, lessThan(hotelsCatalog.length));
    for (final h in hotelsCatalog) {
      expect(
        find.byKey(Key('map_pin_${h.id}')),
        expected.contains(h) ? findsOneWidget : findsNothing,
        reason: h.id,
      );
    }
  });

  testWidgets('кнопка «к отелям» работает и метки остаются', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('map_locate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map_pin_3')), findsOneWidget);
  });

  testWidgets('без подходящих отелей показывает сообщение', (tester) async {
    await open(
      tester,
      setup: (c) {
        c.read(searchProvider.notifier).setType(AccommodationType.apartments);
        c.read(filtersProvider.notifier).toggleBreakfast();
      },
    );
    expect(
      find.text('По выбранным фильтрам ничего не найдено'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('map_list')), findsOneWidget);
  });
}
