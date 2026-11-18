import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/core/uuid.dart';

void main() {
  test('newUuid даёт UUID версии 4 в формате из спецификации', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    for (var i = 0; i < 50; i++) {
      expect(newUuid(), matches(pattern));
    }
  });

  test('ключи не повторяются', () {
    expect({for (var i = 0; i < 200; i++) newUuid()}, hasLength(200));
  });
}
