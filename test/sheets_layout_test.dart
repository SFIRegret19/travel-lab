import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/features/checkout/widgets/checkout_sheets.dart';
import 'package:travel_lab/features/rooms/widgets/room_sheets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('GolosText')
      ..addFont(rootBundle.load('assets/fonts/GolosText.ttf'));
    await loader.load();
  });

  // Mi 8: 1080x2248 при плотности 2.75. Шторка без isScrollControlled
  // ограничена 9/16 высоты, и содержимое вылезало под системную панель.
  Future<void> open(
    WidgetTester tester,
    Future<void> Function(BuildContext) show,
  ) async {
    tester.view.physicalSize = const Size(1080, 2248);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'GolosText'),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () => show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('шторка «цена изменилась» целиком помещается на телефоне', (
    tester,
  ) async {
    await open(
      tester,
      (c) => showPriceChangedSheet(c, oldPrice: 12000, newPrice: 12480),
    );
    expect(tester.takeException(), isNull);
    final button = tester.getRect(find.byKey(const Key('price_changed_ok')));
    expect(button.bottom, lessThanOrEqualTo(2248 / 2.75));
    await tester.tap(find.byKey(const Key('price_changed_ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('price_changed_ok')), findsNothing);
  });

  testWidgets('шторка «условия отмены» без переполнения', (tester) async {
    await open(
      tester,
      (c) => showCancellationSheet(c, until: DateTime(2026, 11, 20)),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('cancel_ok')), findsOneWidget);
  });
}
