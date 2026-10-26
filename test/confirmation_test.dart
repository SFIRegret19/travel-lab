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

  Order orderOf({required int paidNow, bool late = false}) {
    final hotel = hotelById('3')!;
    final room = roomsFor(hotel).first;
    return Order(
      selection: BookingSelection(
        hotel: hotel,
        room: room,
        offer: room.offers.first,
      ),
      checkIn: DateTime(2026, 10, 27),
      checkOut: DateTime(2026, 10, 28),
      guestNames: const ['Иванов Иван', 'Петрова Анна'],
      email: 'ivan.ivanov@example.com',
      phone: '79001234567',
      total: 1035,
      paidNow: paidNow,
      payMethod: 'Mastercard •• 4821',
      lateCheckout: late,
      number: 'TL-123456',
    );
  }

  Future<ProviderContainer> open(WidgetTester tester, {Order? order}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 10, 26))],
    );
    addTearDown(container.dispose);
    if (order != null) container.read(orderProvider.notifier).place(order);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TravelApp()),
    );
    appRouter.go(Routes.confirmation);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('без заказа показывает заглушку и ведёт на главный', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('confirmation_empty')), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmation_home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_search_pill')), findsOneWidget);
  });

  testWidgets('показывает номер заказа, гостей и суммы', (tester) async {
    await open(tester, order: orderOf(paidNow: 1035, late: true));
    expect(find.text('Бронирование подтверждено'), findsOneWidget);
    expect(find.text('Заказ TL-123456'), findsOneWidget);
    expect(
      find.text('Подтверждение отправим на ivan.ivanov@example.com'),
      findsOneWidget,
    );
    expect(find.text('Иванов Иван'), findsOneWidget);
    expect(find.text('Петрова Анна'), findsOneWidget);
    expect(find.text('Поздний выезд до 23:00'), findsOneWidget);
    final paid = find.byKey(const Key('confirmation_paid'));
    await tester.ensureVisible(paid);
    expect(
      find.descendant(of: paid, matching: find.text('1 035 ₽')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('confirmation_remaining')), findsNothing);
  });

  testWidgets('при оплате частями показывает остаток', (tester) async {
    await open(tester, order: orderOf(paidNow: 259));
    final remaining = find.byKey(const Key('confirmation_remaining'));
    await tester.ensureVisible(remaining);
    expect(
      find.descendant(of: remaining, matching: find.text('776 ₽, 3 платежа')),
      findsOneWidget,
    );
  });

  testWidgets('копирование номера показывает подтверждение', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await open(tester, order: orderOf(paidNow: 1035));
    await tester.tap(find.byKey(const Key('confirmation_copy')));
    await tester.pump();
    expect(copied, 'TL-123456');
    expect(find.text('Номер заказа скопирован'), findsOneWidget);
  });

  testWidgets('кнопка «На главный» и системное «назад» ведут домой', (
    tester,
  ) async {
    await open(tester, order: orderOf(paidNow: 1035));
    await tester.tap(find.byKey(const Key('confirmation_home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_search_pill')), findsOneWidget);

    appRouter.go(Routes.confirmation);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_search_pill')), findsOneWidget);
  });
}
