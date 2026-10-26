import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/format/formatters.dart';
import 'package:travel_lab/core/router/app_router.dart';
import 'package:travel_lab/data/hotels_catalog.dart';
import 'package:travel_lab/core/router/routes.dart';
import 'package:travel_lab/features/search/search_params.dart';
import 'package:travel_lab/features/search/search_provider.dart';
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

  testWidgets('Пустая выдача предлагает сбросить фильтры', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 10, 26))],
    );
    addTearDown(container.dispose);
    // В каталоге у обеих квартир нет завтрака.
    container
        .read(searchProvider.notifier)
        .setType(AccommodationType.apartments);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TravelApp()),
    );
    appRouter.go(Routes.results);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hotel_card_5')), findsOneWidget);

    // Чип «С завтраком» в конце горизонтального списка: сначала прокрутка.
    await tester.drag(
      find.byKey(const Key('chip_sort')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chip_breakfast')));
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reset_filters')));
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsNothing);
    expect(find.byKey(const Key('hotel_card_5')), findsOneWidget);
  });

  testWidgets('Шторка фильтров: применить, отбросить, ввести цену', (
    tester,
  ) async {
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
    appRouter.go(Routes.results);
    await tester.pumpAndSettle();

    final all = hotelsCatalog.length;
    final withBreakfast = hotelsCatalog.where((h) => h.breakfast).length;
    expect(find.byKey(const Key('hotel_card_3')), findsOneWidget);

    // Применить: живой счётчик меняется, список сокращается.
    await tester.tap(find.byKey(const Key('chip_filters')));
    await tester.pumpAndSettle();
    expect(find.text(formatFoundOffers(all)), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick_breakfast')));
    await tester.pumpAndSettle();
    expect(find.text(formatFoundOffers(withBreakfast)), findsOneWidget);
    await tester.tap(find.byKey(const Key('filters_apply')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hotel_card_3')), findsNothing);

    // Отбросить: изменения черновика не сохраняются.
    await tester.tap(find.byKey(const Key('chip_filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick_breakfast')));
    await tester.pumpAndSettle();
    expect(find.text(formatFoundOffers(all)), findsOneWidget);
    await tester.tap(find.byKey(const Key('filters_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hotel_card_3')), findsNothing);

    // Цена: чип открывает шторку, вводим верхнюю границу.
    await tester.tap(find.byKey(const Key('chip_price')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('price_max')), '2500');
    await tester.pumpAndSettle();
    final cheapBreakfast = hotelsCatalog
        .where((h) => h.breakfast && h.price <= 2500)
        .length;
    expect(find.text(formatFoundOffers(cheapBreakfast)), findsOneWidget);
    await tester.tap(find.byKey(const Key('filters_apply')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hotel_card_1')), findsOneWidget);
    expect(find.byKey(const Key('hotel_card_4')), findsNothing);
  });

  group('страница отеля', () {
    Future<ProviderContainer> openApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [todayProvider.overrideWithValue(DateTime(2026, 10, 26))],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TravelApp(),
        ),
      );
      return container;
    }

    testWidgets('неизвестный id показывает «Отель не найден»', (tester) async {
      await openApp(tester);
      appRouter.go(Routes.hotelPath('нет-такого'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hotel_not_found')), findsOneWidget);
    });

    testWidgets('без дат цена за одну ночь, в форме «Заезд — выезд»', (
      tester,
    ) async {
      await openApp(tester);
      appRouter.go(Routes.hotelPath('3'));
      await tester.pumpAndSettle();
      final one = formatPrice(hotelById('3')!.price);
      expect(
        find.descendant(
          of: find.byKey(const Key('hotel_select')),
          matching: find.text('Выбрать от $one'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('кнопка «Выбрать от» равна цене за все ночи', (tester) async {
      final container = await openApp(tester);
      container.read(searchProvider.notifier)
        ..pickDate(DateTime(2026, 10, 27))
        ..pickDate(DateTime(2026, 10, 30));
      appRouter.go(Routes.hotelPath('3'));
      await tester.pumpAndSettle();
      final three = formatPrice(hotelById('3')!.price * 3);
      expect(
        find.descendant(
          of: find.byKey(const Key('hotel_select')),
          matching: find.text('Выбрать от $three'),
        ),
        findsOneWidget,
      );
      // Кнопка в блоке «Предложения» показывает ту же цену.
      await tester.scrollUntilVisible(
        find.byKey(const Key('hotel_offers_select')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('hotel_scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('hotel_offers_select')),
          matching: find.text('Выбрать от $three'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('«Читать всё» раскрывает текст', (tester) async {
      await openApp(tester);
      appRouter.go(Routes.hotelPath('3'));
      await tester.pumpAndSettle();

      final scrollable = find
          .descendant(
            of: find.byKey(const Key('hotel_scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('hotel_read_more')),
        300,
        scrollable: scrollable,
      );
      expect(find.text('Читать всё'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('hotel_read_more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hotel_read_more')));
      await tester.pumpAndSettle();
      expect(find.text('Свернуть'), findsOneWidget);
    });

    testWidgets('плитка рейтинга ведёт к отзывам и назад', (tester) async {
      await openApp(tester);
      appRouter.go(Routes.hotelPath('3'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hotel_rating_tile')));
      await tester.pumpAndSettle();
      expect(find.text('Отзывы'), findsOneWidget);
      await tester.tap(find.byKey(const Key('reviews_back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hotel_select')), findsOneWidget);
    });
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
    // Роутер глобальный и помнит позицию предыдущего теста.
    appRouter.go(Routes.home);
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
    expect(find.byKey(const Key('results_pill')), findsOneWidget);
    expect(find.text('Сочи'), findsOneWidget);

    // Выдача: сортировка и быстрые фильтры, затем первая карточка.
    expect(find.byKey(const Key('hotel_card_3')), findsOneWidget);
    // Закрытие крестиком отменяет выбор в шторке.
    await tester.tap(find.byKey(const Key('chip_sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sort_pricier')));
    await tester.tap(find.byKey(const Key('sort_close')));
    await tester.pumpAndSettle();
    expect(find.text('Популярные'), findsOneWidget);
    expect(find.text('Сначала дороже'), findsNothing);

    await tester.tap(find.byKey(const Key('chip_sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sort_cheaper')));
    await tester.tap(find.byKey(const Key('sort_apply')));
    await tester.pumpAndSettle();
    expect(find.text('Сначала дешевле'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chip_sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sort_popular')));
    await tester.tap(find.byKey(const Key('sort_apply')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('hotel_card_3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hotel_select')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hotel_select')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rooms_list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('offer_select_r0_0')));
    await tester.pumpAndSettle();
    expect(find.text('Оформление'), findsOneWidget);
    await tester.tap(find.text('Оплатить'));
    await tester.pumpAndSettle();
    expect(find.text('Подтверждение'), findsOneWidget);
  });
}
