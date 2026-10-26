import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/router/app_router.dart';
import 'package:travel_lab/core/router/routes.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:travel_lab/features/rooms/booking_selection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('GolosText')
      ..addFont(rootBundle.load('assets/fonts/GolosText.ttf'));
    await loader.load();
  });

  Future<ProviderContainer> openRooms(WidgetTester tester, String id) async {
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
    appRouter.go(Routes.roomsPath(id));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('неизвестный отель показывает заглушку', (tester) async {
    await openRooms(tester, 'нет-такого');
    expect(find.byKey(const Key('rooms_not_found')), findsOneWidget);
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
    expect(find.text('Оформление'), findsOneWidget);
    final selection = container.read(bookingSelectionProvider)!;
    expect(selection.hotel.id, '3');
    expect(selection.room.id, 'r0');
    expect(selection.offer.id, 'o1');
  });
}
