import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Поведение заглушки сервера. Меняется на демо-панели, чтобы показать
/// состояния ошибок без правки кода.
class MockSettings {
  const MockSettings({
    this.latency = const Duration(milliseconds: 900),
    this.offline = false,
    this.serverError = false,
    this.noResults = false,
    this.noRooms = false,
    this.soldOut = false,
    this.priceChanged = false,
    this.validationError = false,
  });

  /// Задержка ответа: на ней видно состояние загрузки.
  final Duration latency;

  /// Нет сети: запрос не доходит до сервера.
  final bool offline;

  /// Любой запрос заканчивается ответом 500.
  final bool serverError;

  /// Выдача пуста (200, `items: []`).
  final bool noResults;

  /// На выбранные даты нет номеров (200, `rooms: []`).
  final bool noRooms;

  /// Оформление отклоняется: тариф раскуплен (409 `OFFER_UNAVAILABLE`).
  final bool soldOut;

  /// Сервер считает сумму больше ожидаемой (409 `PRICE_CHANGED`).
  final bool priceChanged;

  /// Оформление отклоняется проверкой полей (422).
  final bool validationError;

  MockSettings copyWith({
    Duration? latency,
    bool? offline,
    bool? serverError,
    bool? noResults,
    bool? noRooms,
    bool? soldOut,
    bool? priceChanged,
    bool? validationError,
  }) {
    return MockSettings(
      latency: latency ?? this.latency,
      offline: offline ?? this.offline,
      serverError: serverError ?? this.serverError,
      noResults: noResults ?? this.noResults,
      noRooms: noRooms ?? this.noRooms,
      soldOut: soldOut ?? this.soldOut,
      priceChanged: priceChanged ?? this.priceChanged,
      validationError: validationError ?? this.validationError,
    );
  }
}

final mockSettingsProvider =
    NotifierProvider<MockSettingsNotifier, MockSettings>(
      MockSettingsNotifier.new,
    );

class MockSettingsNotifier extends Notifier<MockSettings> {
  @override
  MockSettings build() => const MockSettings();

  void update(MockSettings Function(MockSettings s) change) {
    state = change(state);
  }

  void reset() => state = const MockSettings();
}
