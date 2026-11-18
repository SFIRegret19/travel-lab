import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/api/mock/mock_settings.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/router/app_router.dart';
import 'package:travel_lab/core/router/routes.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:travel_lab/data/hotel_details.dart';
import 'package:travel_lab/data/hotel_rooms.dart';
import 'package:travel_lab/data/hotels_catalog.dart';
import 'package:travel_lab/features/rooms/booking_selection.dart';

import 'test_helpers.dart';

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
    MockSettings settings = const MockSettings(latency: Duration.zero),
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
    if (withSelection) {
      final hotel = hotelsCatalog.firstWhere((h) => h.id == '3');
      final room = roomsFor(hotel).first;
      container
          .read(bookingSelectionProvider.notifier)
          .select(
            BookingSelection(
              hotel: hotel,
              details: detailsFor(hotel),
              room: room,
              offer: room.offers[0],
            ),
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

  testWidgets('оплата создаёт бронь и ведёт к подтверждению', (tester) async {
    await openCheckout(tester);
    await tapKey(tester, 'checkout_pay');
    expect(find.text('Бронирование подтверждено'), findsOneWidget);
    expect(find.text('Заказ TL-482916'), findsOneWidget);
    expect(find.text('Иванов Иван'), findsOneWidget);
    final paid = find.byKey(const Key('confirmation_paid'));
    await tester.ensureVisible(paid);
    expect(
      find.descendant(of: paid, matching: find.text('1 035 ₽')),
      findsOneWidget,
    );
  });

  testWidgets('оплата частями списывает первый платёж', (tester) async {
    await openCheckout(tester);
    await tapKey(tester, 'pay_mode_split');
    await tapKey(tester, 'checkout_pay');
    final paid = find.byKey(const Key('confirmation_paid'));
    await tester.ensureVisible(paid);
    expect(
      find.descendant(of: paid, matching: find.text('259 ₽')),
      findsOneWidget,
    );
  });

  group('ответы сервера', () {
    testWidgets('пока идёт запрос, кнопка заблокирована и бронь одна', (
      tester,
    ) async {
      await openCheckout(
        tester,
        settings: const MockSettings(latency: Duration(milliseconds: 500)),
      );
      final pay = find.byKey(const Key('checkout_pay'));
      await tester.ensureVisible(pay);
      await tester.pumpAndSettle();
      await tester.tap(pay);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('checkout_submitting')), findsOneWidget);
      expect(find.text('Оформляем заказ…'), findsOneWidget);
      expect(tester.widget<FilledButton>(pay).onPressed, isNull);

      // Повторное нажатие во время запроса игнорируется.
      await tester.tap(pay, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('Заказ TL-482916'), findsOneWidget);
    });

    testWidgets('цена выросла: модалка, новая сумма и повторная оплата', (
      tester,
    ) async {
      await openCheckout(
        tester,
        settings: const MockSettings(
          latency: Duration.zero,
          priceChanged: true,
        ),
      );
      await tapKey(tester, 'checkout_pay');
      expect(find.text('Похоже, цена изменилась'), findsOneWidget);
      expect(find.byKey(const Key('price_changed_text')), findsOneWidget);
      Finder inSheet(String text) => find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(text),
      );
      expect(inSheet('1 035 ₽'), findsOneWidget);
      expect(inSheet('1 076 ₽'), findsOneWidget);
      expect(inSheet('+41 ₽'), findsOneWidget);

      await tester.tap(find.byKey(const Key('price_changed_ok')));
      await tester.pumpAndSettle();
      expect(find.text('Бронирование подтверждено'), findsNothing);
      expect(totalText(tester), '1 076 ₽');
      expect(find.byKey(const Key('summary_surcharge')), findsOneWidget);

      await tapKey(tester, 'checkout_pay');
      expect(find.text('Бронирование подтверждено'), findsOneWidget);
      final paid = find.byKey(const Key('confirmation_paid'));
      await tester.ensureVisible(paid);
      expect(
        find.descendant(of: paid, matching: find.text('1 076 ₽')),
        findsOneWidget,
      );
    });

    testWidgets('тариф раскуплен: диалог и возврат', (tester) async {
      await openCheckout(
        tester,
        settings: const MockSettings(latency: Duration.zero, soldOut: true),
      );
      await tapKey(tester, 'checkout_pay');
      expect(find.byKey(const Key('offer_unavailable_dialog')), findsOneWidget);
      expect(find.text('Номер уже забронирован'), findsOneWidget);
      await tester.tap(find.byKey(const Key('offer_unavailable_ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('offer_unavailable_dialog')), findsNothing);
      expect(find.text('Бронирование подтверждено'), findsNothing);
    });

    testWidgets('сервер отклонил поля: ошибка под полем почты', (tester) async {
      await openCheckout(
        tester,
        settings: const MockSettings(
          latency: Duration.zero,
          validationError: true,
        ),
      );
      await tapKey(tester, 'checkout_pay');
      expect(find.text('Некорректная почта'), findsOneWidget);
      expect(find.text('Бронирование подтверждено'), findsNothing);
      // Кнопка снова доступна: можно исправить и отправить заново.
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('checkout_pay')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('нет сети: «Повторить» отправляет тот же заказ', (
      tester,
    ) async {
      final container = await openCheckout(
        tester,
        settings: const MockSettings(latency: Duration.zero, offline: true),
      );
      await tapKey(tester, 'checkout_pay');
      expect(find.text('Нет соединения. Заказ не оформлен'), findsOneWidget);
      expect(find.text('Бронирование подтверждено'), findsNothing);
      // Форма осталась заполненной.
      expect(find.text('Иванов'), findsOneWidget);

      container
          .read(mockSettingsProvider.notifier)
          .update((s) => s.copyWith(offline: false));
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(find.text('Бронирование подтверждено'), findsOneWidget);
      expect(find.text('Заказ TL-482916'), findsOneWidget);
    });

    testWidgets('ошибка сервера 500: снекбар с повтором', (tester) async {
      await openCheckout(
        tester,
        settings: const MockSettings(latency: Duration.zero, serverError: true),
      );
      await tapKey(tester, 'checkout_pay');
      expect(find.text('Сервис недоступен. Заказ не оформлен'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });
  });
}
