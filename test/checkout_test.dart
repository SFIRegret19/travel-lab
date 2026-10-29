import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/router/app_router.dart';
import 'package:travel_lab/core/router/routes.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:travel_lab/data/hotel_rooms.dart';
import 'package:travel_lab/data/hotels_catalog.dart';
import 'package:travel_lab/features/checkout/order.dart';
import 'package:travel_lab/features/rooms/booking_selection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('GolosText')
      ..addFont(rootBundle.load('assets/fonts/GolosText.ttf'));
    await loader.load();
  });

  Future<ProviderContainer> openCheckout(
    WidgetTester tester, {
    bool withSelection = true,
    bool dismissModal = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 10, 26))],
    );
    addTearDown(container.dispose);
    if (withSelection) {
      final hotel = hotelById('3')!;
      final room = roomsFor(hotel).first;
      container
          .read(bookingSelectionProvider.notifier)
          .select(
            BookingSelection(hotel: hotel, room: room, offer: room.offers[0]),
          );
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TravelApp()),
    );
    appRouter.go(Routes.checkout);
    await tester.pumpAndSettle();
    if (withSelection && dismissModal) {
      await tester.tap(find.byKey(const Key('price_changed_ok')));
      await tester.pumpAndSettle();
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

  String totalText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('checkout_total'))).data!;

  testWidgets('без выбранного тарифа показывает заглушку', (tester) async {
    await openCheckout(tester, withSelection: false);
    expect(find.byKey(const Key('checkout_not_found')), findsOneWidget);
  });

  testWidgets('модалка показывает старую и новую цену', (tester) async {
    await openCheckout(tester, dismissModal: false);
    expect(find.text('Похоже, цена изменилась'), findsOneWidget);
    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );
    expect(inSheet('1 089 ₽'), findsOneWidget);
    expect(inSheet('1 035 ₽'), findsOneWidget);
    expect(inSheet('−54 ₽'), findsOneWidget);
    await tester.tap(find.byKey(const Key('price_changed_ok')));
    await tester.pumpAndSettle();
    expect(find.text('Похоже, цена изменилась'), findsNothing);
    expect(totalText(tester), '1 035 ₽');
  });

  testWidgets('модалка не возвращается при перерисовке', (tester) async {
    await openCheckout(tester);
    await tapKey(tester, 'late_checkout_switch');
    await tapKey(tester, 'late_checkout_switch');
    expect(find.text('Похоже, цена изменилась'), findsNothing);
  });

  testWidgets('даты без поиска: заезд сегодня', (tester) async {
    await openCheckout(tester);
    expect(find.text('26 окт, пн'), findsOneWidget);
    expect(find.text('27 окт, вт'), findsOneWidget);
    expect(find.text('Заезд сегодня'), findsWidgets);
  });

  testWidgets('поздний выезд меняет итог и кнопку', (tester) async {
    await openCheckout(tester);
    await tapKey(tester, 'late_checkout_switch');
    expect(totalText(tester), '2 235 ₽');
    expect(find.text('Оплатить 2 235 ₽'), findsOneWidget);
    await tapKey(tester, 'late_checkout_switch');
    expect(totalText(tester), '1 035 ₽');
  });

  testWidgets('промокод: неверный, верный и удаление', (tester) async {
    await openCheckout(tester);
    await tapKey(tester, 'promo_row');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('promo_apply')))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byKey(const Key('promo_field')), 'abc');
    await tester.pump();
    await tester.tap(find.byKey(const Key('promo_apply')));
    await tester.pumpAndSettle();
    expect(find.text('Промокод не найден'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('promo_field')), 'lab10');
    await tester.pump();
    await tester.tap(find.byKey(const Key('promo_apply')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('summary_promo')), findsOneWidget);
    // 1 150 − 115 − 104 = 931.
    expect(totalText(tester), '931 ₽');

    await tapKey(tester, 'promo_remove');
    expect(find.byKey(const Key('summary_promo')), findsNothing);
    expect(totalText(tester), '1 035 ₽');
  });

  testWidgets('пустое обязательное поле блокирует оплату', (tester) async {
    await openCheckout(tester);
    await tapKey(tester, 'clear_email');
    await tapKey(tester, 'checkout_pay');
    expect(find.text('Укажите почту'), findsOneWidget);
    expect(find.byKey(const Key('checkout_pay')), findsOneWidget);
    expect(find.text('Бронирование подтверждено'), findsNothing);
  });

  testWidgets('способ оплаты и Сплит меняют кнопку', (tester) async {
    await openCheckout(tester);
    await tapKey(tester, 'pay_method_1');
    expect(
      tester.widget<Text>(find.byKey(const Key('checkout_pay_method'))).data,
      'СБП',
    );
    await tapKey(tester, 'pay_mode_split');
    expect(find.text('Оплатить 259 ₽'), findsOneWidget);
    await tapKey(tester, 'pay_mode_full');
    expect(find.text('Оплатить 1 035 ₽'), findsOneWidget);
  });

  testWidgets('оплата сохраняет заказ и ведёт к подтверждению', (tester) async {
    final container = await openCheckout(tester);
    await tapKey(tester, 'checkout_pay');
    expect(find.text('Бронирование подтверждено'), findsOneWidget);
    final order = container.read(orderProvider)!;
    expect(order.total, 1035);
    expect(order.paidNow, 1035);
    expect(order.guestNames, ['Иванов Иван']);
    expect(order.selection.hotel.id, '3');
  });

  testWidgets('оплата частями списывает первый платёж', (tester) async {
    final container = await openCheckout(tester);
    await tapKey(tester, 'pay_mode_split');
    await tapKey(tester, 'checkout_pay');
    final order = container.read(orderProvider)!;
    expect(order.total, 1035);
    expect(order.paidNow, 259);
  });
}
