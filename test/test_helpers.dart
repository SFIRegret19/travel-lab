import 'package:travel_lab/api/mock/mock_settings.dart';

/// Заглушка сервера без задержки: тесты не ждут ответа и не зависают на
/// бесконечной анимации загрузки.
class InstantMockSettings extends MockSettingsNotifier {
  @override
  MockSettings build() => const MockSettings(latency: Duration.zero);
}

final instantMockApi = mockSettingsProvider.overrideWith(
  InstantMockSettings.new,
);
