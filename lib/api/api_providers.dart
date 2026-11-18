import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time/today_provider.dart';
import 'mock/mock_server.dart';
import 'mock/mock_settings.dart';
import 'travel_api.dart';

/// Вместо сети передаёт запрос заглушке сервера. Чтобы перейти на настоящий
/// сервер, достаточно убрать этот адаптер из [dioProvider].
class MockAdapter implements HttpClientAdapter {
  MockAdapter(this.server);

  final MockServer server;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => server.handle(options);

  @override
  void close({bool force = false}) {}
}

/// Riverpod по умолчанию сам повторяет упавшие запросы. Нам это мешает:
/// ошибку нужно показать пользователю и дать кнопку «Повторить».
Duration? noRetry(int retryCount, Object error) => null;

final mockServerProvider = Provider<MockServer>(
  (ref) => MockServer(
    settings: () => ref.read(mockSettingsProvider),
    today: () => ref.read(todayProvider),
  ),
);

final dioProvider = Provider<Dio>((ref) {
  return Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    )
    ..httpClientAdapter = MockAdapter(ref.watch(mockServerProvider))
    ..transformer = SyncTransformer();
});

final travelApiProvider = Provider<TravelApi>(
  (ref) => TravelApi(ref.watch(dioProvider)),
);
