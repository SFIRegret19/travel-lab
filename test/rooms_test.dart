import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/api/mock/mock_settings.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/router/app_router.dart';
import 'package:travel_lab/core/router/routes.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:travel_lab/features/rooms/booking_selection.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('GolosText')
      ..addFont(rootBundle.load('assets/fonts/GolosText.ttf'));
    await loader.load();
  });

  Future<ProviderContainer> openRooms(
    WidgetTester tester,
    String id, {
    MockSettings settings = const MockSettings(latency: Duration.zero),
    bool settle = true,
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
    container.read(mockSettingsProvider.notifier).update((_) => settings);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TravelApp()),
    );
    appRouter.go(Routes.roomsPath(id));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Загрузка анимирована бесконечно: pumpAndSettle здесь не годится.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
    return container;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('неизвестный отель: ошибка 404 без повтора', (tester) async {
    await openRooms(tester, 'нет-такого');
    expect(find.byKey(const Key('error_state')), findsOneWidget);
    expect(find.text('Отель не найден'), findsOneWidget);
    expect(find.byKey(const Key('error_retry')), findsNothing);
  });

  testWidgets('пока номера грузятся, показан скелетон', (tester) async {
    await openRooms(
      tester,
      '3',
      settings: const MockSettings(latency: Duration(milliseconds: 500)),
      settle: false,
    );
    expect(find.byKey(const Key('rooms_loading')), findsOneWidget);
    expect(find.byKey(const Key('room_r0')), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rooms_loading')), findsNothing);
    expect(find.byKey(const Key('room_r0')), findsOneWidget);
  });

  testWidgets('нет свободных номеров это не ошибка', (tester) async {
    await openRooms(
      tester,
      '3',
      settings: const MockSettings(latency: Duration.zero, noRooms: true),
    );
    expect(find.byKey(const Key('rooms_empty')), findsOneWidget);
    expect(find.text('Нет свободных номеров'), findsOneWidget);
    expect(find.byKey(const Key('error_state')), findsNothing);
    await tester.tap(find.byKey(const Key('rooms_change_dates')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rooms_empty')), findsNothing);
  });

  testWidgets('нет сети: ошибка и «Повторить» загружает номера', (
    tester,
  ) async {
    final container = await openRooms(
      tester,
      '3',
      settings: const MockSettings(latency: Duration.zero, offline: true),
    );
    expect(find.text('Нет соединения'), findsOneWidget);
    expect(find.byKey(const Key('room_r0')), findsNothing);

    container
        .read(mockSettingsProvider.notifier)
        .update((s) => s.copyWith(offline: false));
    await tester.tap(find.byKey(const Key('error_retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('error_state')), findsNothing);
    expect(find.byKey(const Key('room_r0')), findsOneWidget);
  });

  testWidgets('цена первого тарифа совпадает с ценой отеля', (tester) async {
    await openRooms(tester, '3');
    expect(find.text('Автор на Павелецкой'), findsOneWidget);
    expect(find.byKey(const Key('room_r0')), findsOneWidget);
    expect(find.text('1 089 ₽'), findsOneWidget);
    expect(find.text('−10%'), findsOneWidget);
    expect(find.text('Осталось 3 номера'), findsOneWidget);
  });

  testWidgets('«Все» открывает шторку удобств и закрывается', (tester) async {
    await openRooms(tester, '3');
    await tapKey(tester, 'room_amenities_r0');
    expect(find.text('Спальные места'), findsOneWidget);
    await tester.tap(find.byKey(const Key('room_amenities_close')));
    await tester.pumpAndSettle();
    expect(find.text('Спальные места'), findsNothing);
  });

  testWidgets('условия отмены: без возврата и с возвратом', (tester) async {
    await openRooms(tester, '3');
    await tapKey(tester, 'offer_cancel_r0_0');
    expect(find.text('Условия отмены'), findsOneWidget);
    expect(find.text('Оплата не возвращается'), findsWidgets);
    await tester.tap(find.byKey(const Key('cancel_ok')));
    await tester.pumpAndSettle();
    expect(find.text('Условия отмены'), findsNothing);

    // Без дат поиска срок отмены не уходит в прошлое.
    await tapKey(tester, 'offer_cancel_r0_1');
    expect(find.text('Бесплатная отмена до 26 окт'), findsWidgets);
  });

  testWidgets('«•••» открывает расшифровку цены', (tester) async {
    await openRooms(tester, '3');
    await tapKey(tester, 'offer_price_info_r0_0');
    expect(find.text('Информация о цене'), findsOneWidget);
    expect(find.byKey(const Key('price_total')), findsOneWidget);
  });

  testWidgets('«Выбрать» запоминает тариф и ведёт к оформлению', (
    tester,
  ) async {
    final container = await openRooms(tester, '3');
    await tapKey(tester, 'offer_select_r0_1');
    expect(find.text('Похоже, цена изменилась'), findsOneWidget);
    final selection = container.read(bookingSelectionProvider)!;
    expect(selection.hotel.id, '3');
    expect(selection.room.id, 'r0');
    expect(selection.offer.id, 'o1');
  });
}
