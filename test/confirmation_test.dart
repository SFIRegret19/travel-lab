import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/api/api_providers.dart';
import 'package:travel_lab/api/mock/mock_settings.dart';
import 'package:travel_lab/app.dart';
import 'package:travel_lab/core/router/app_router.dart';
import 'package:travel_lab/core/router/routes.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:travel_lab/data/models/booking.dart';
import 'package:travel_lab/features/confirmation/confirmation_state.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('GolosText')
      ..addFont(rootBundle.load('assets/fonts/GolosText.ttf'));
    await loader.load();
  });

  /// Создаёт бронь отеля №3 через заглушку и возвращает её id.
  Future<String> book(
    ProviderContainer container, {
    int total = 1035,
    PayMode mode = PayMode.full,
    bool late = false,
    int adults = 1,
  }) async {
    final booking = await container
        .read(travelApiProvider)
        .createBooking(
          BookingRequest(
            hotelId: '3',
            roomId: 'r0',
            offerId: 'o0',
            checkIn: DateTime(2026, 10, 27),
            checkOut: DateTime(2026, 10, 28),
            adults: adults,
            children: 0,
            guests: [
              const BookingGuest(lastName: 'Иванов', firstName: 'Иван'),
              if (adults > 1)
                const BookingGuest(lastName: 'Петрова', firstName: 'Анна'),
            ],
            email: 'ivan.ivanov@example.com',
            phone: '79001234567',
            lateCheckout: late,
            payMode: mode,
            payMethod: 'mastercard',
            expectedTotal: total,
          ),
          idempotencyKey: 'test-${DateTime.now().microsecondsSinceEpoch}',
        );
    return booking.id;
  }

  Future<ProviderContainer> open(
    WidgetTester tester, {
    String? bookingId,
    Future<String> Function(ProviderContainer)? create,
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
    final id = create != null
        ? (await tester.runAsync(() => create(container)))!
        : bookingId!;
    container.read(mockSettingsProvider.notifier).update((_) => settings);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TravelApp()),
    );
    appRouter.go(Routes.confirmationPath(id));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('неизвестная бронь: «не найдено» без повтора и выход домой', (
    tester,
  ) async {
    await open(tester, bookingId: 'bk_nope');
    expect(find.byKey(const Key('error_state')), findsOneWidget);
    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(find.byKey(const Key('error_retry')), findsNothing);
    await tester.tap(find.byKey(const Key('error_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_search_pill')), findsOneWidget);
  });

  testWidgets('показывает номер заказа, гостей и суммы', (tester) async {
    await open(
      tester,
      create: (c) => book(c, total: 2235, late: true, adults: 2),
    );
    expect(find.text('Бронирование подтверждено'), findsOneWidget);
    expect(find.text('Заказ TL-482916'), findsOneWidget);
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
      find.descendant(of: paid, matching: find.text('2 235 ₽')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('confirmation_remaining')), findsNothing);
  });

  testWidgets('при оплате частями показывает остаток', (tester) async {
    await open(tester, create: (c) => book(c, mode: PayMode.split));
    final remaining = find.byKey(const Key('confirmation_remaining'));
    await tester.ensureVisible(remaining);
    expect(
      find.descendant(of: remaining, matching: find.text('776 ₽, 3 платежа')),
      findsOneWidget,
    );
  });

  testWidgets('пока бронь грузится, показан скелетон', (tester) async {
    final container = await open(tester, create: book);
    // Первая бронь заглушки получает id bk_5e8d2b: включаем задержку и
    // перезапрашиваем её, чтобы поймать промежуточный кадр.
    container
        .read(mockSettingsProvider.notifier)
        .update((s) => s.copyWith(latency: const Duration(milliseconds: 500)));
    container.invalidate(bookingProvider('bk_5e8d2b'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('confirmation_loading')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Бронирование подтверждено'), findsOneWidget);
  });

  testWidgets('нет сети: ошибка, «Повторить» загружает бронь', (tester) async {
    final container = await open(
      tester,
      create: book,
      settings: const MockSettings(latency: Duration.zero, offline: true),
    );
    expect(find.text('Нет соединения'), findsOneWidget);
    container
        .read(mockSettingsProvider.notifier)
        .update((s) => s.copyWith(offline: false));
    await tester.tap(find.byKey(const Key('error_retry')));
    await tester.pumpAndSettle();
    expect(find.text('Бронирование подтверждено'), findsOneWidget);
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
    await open(tester, create: book);
    await tester.tap(find.byKey(const Key('confirmation_copy')));
    await tester.pump();
    expect(copied, 'TL-482916');
    expect(find.text('Номер заказа скопирован'), findsOneWidget);
  });

  testWidgets('кнопка «На главный» и системное «назад» ведут домой', (
    tester,
  ) async {
    final container = await open(tester, create: book);
    await tester.tap(find.byKey(const Key('confirmation_home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_search_pill')), findsOneWidget);

    final again = (await tester.runAsync(() => book(container)))!;
    appRouter.go(Routes.confirmationPath(again));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_search_pill')), findsOneWidget);
  });
}
