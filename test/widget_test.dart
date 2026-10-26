import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_lab/app.dart';

void main() {
  testWidgets('Сценарий проходит от главного до подтверждения', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TravelApp()));
    await tester.pumpAndSettle();
    expect(find.text('Главный'), findsOneWidget);

    for (final step in const [
      ('Найти жильё', 'Где будете жить?'),
      ('Найти', 'Результаты'),
      ('Открыть отель', 'Карточка отеля'),
      ('Выбрать номер', 'Выбор номера'),
      ('Выбрать', 'Оформление'),
      ('Оплатить', 'Подтверждение'),
    ]) {
      await tester.tap(find.text(step.$1));
      await tester.pumpAndSettle();
      expect(find.text(step.$2), findsOneWidget);
    }
  });
}
