// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/api/api_providers.dart';
import 'package:travel_lab/api/mock/mock_settings.dart';
import 'package:travel_lab/api/parsers.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:yaml/yaml.dart';

/// Контракт между `api/openapi.yaml` и кодом: и примеры из спецификации,
/// и настоящие ответы заглушки должны соответствовать описанным схемам.
dynamic _plain(dynamic n) {
  if (n is YamlMap) {
    return {for (final e in n.entries) e.key.toString(): _plain(e.value)};
  }
  if (n is YamlList) return [for (final e in n) _plain(e)];
  return n;
}

void main() {
  final spec =
      _plain(loadYaml(File('api/openapi.yaml').readAsStringSync())) as Json;
  final components = spec['components'] as Json;

  Json deref(String ref) {
    dynamic node = spec;
    for (final part in ref.substring(2).split('/')) {
      node = (node as Json)[part];
    }
    return node as Json;
  }

  /// Раскрывает `$ref` и `allOf` в одну схему.
  Json resolve(Json s) {
    if (s.containsKey(r'$ref')) return resolve(deref(s[r'$ref'] as String));
    final parts = s['allOf'] as List?;
    if (parts == null) return s;
    final merged = <String, dynamic>{'type': 'object'};
    final props = <String, dynamic>{};
    final required = <dynamic>[];
    for (final part in parts) {
      final r = resolve(part as Json);
      props.addAll((r['properties'] as Json?) ?? const {});
      required.addAll((r['required'] as List?) ?? const []);
    }
    return merged
      ..['properties'] = props
      ..['required'] = required;
  }

  void conform(Json schema, dynamic value, String path, List<String> bad) {
    final s = resolve(schema);
    if (value == null) {
      if (s['nullable'] != true) bad.add('$path: null не разрешён');
      return;
    }
    final enumValues = s['enum'] as List?;
    if (enumValues != null && !enumValues.contains(value)) {
      bad.add('$path: значение $value вне enum $enumValues');
    }
    switch (s['type']) {
      case 'integer':
        if (value is! int) bad.add('$path: ожидался integer, пришло $value');
      case 'number':
        if (value is! num) bad.add('$path: ожидался number, пришло $value');
      case 'boolean':
        if (value is! bool) bad.add('$path: ожидался boolean, пришло $value');
      case 'string':
        if (value is! String) {
          bad.add('$path: ожидалась строка, пришло $value');
        } else if (s['format'] == 'date' &&
            !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
          bad.add('$path: дата не в формате yyyy-MM-dd: $value');
        }
      case 'array':
        if (value is! List) {
          bad.add('$path: ожидался массив');
        } else {
          for (var i = 0; i < value.length; i++) {
            conform(s['items'] as Json, value[i], '$path[$i]', bad);
          }
        }
      case 'object':
        if (value is! Map) {
          bad.add('$path: ожидался объект');
          return;
        }
        final props = (s['properties'] as Json?) ?? const {};
        for (final key in value.keys) {
          if (!props.containsKey(key)) bad.add('$path.$key: поля нет в схеме');
        }
        for (final key in (s['required'] as List?) ?? const []) {
          if (!value.containsKey(key)) bad.add('$path.$key: обязательное поле');
        }
        value.forEach((key, v) {
          final p = props[key];
          if (p != null) conform(p as Json, v, '$path.$key', bad);
        });
    }
  }

  /// Все пары (схема, значение) из примеров запросов и ответов.
  Iterable<(String, Json, dynamic)> specExamples() sync* {
    Iterable<(String, Json, dynamic)> fromContent(
      String where,
      Json? media,
    ) sync* {
      final json = (media?['content'] as Json?)?['application/json'] as Json?;
      if (json == null) return;
      final schema = json['schema'] as Json;
      final examples = (json['examples'] as Json?) ?? const {};
      for (final e in examples.entries) {
        var ex = e.value as Json;
        if (ex.containsKey(r'$ref')) ex = deref(ex[r'$ref'] as String);
        yield ('$where/${e.key}', schema, ex['value']);
      }
    }

    for (final p in (spec['paths'] as Json).entries) {
      for (final m in (p.value as Json).entries) {
        final op = m.value as Json;
        final name = '${m.key.toUpperCase()} ${p.key}';
        yield* fromContent('$name запрос', op['requestBody'] as Json?);
        for (final r in (op['responses'] as Json).entries) {
          var response = r.value as Json;
          if (response.containsKey(r'$ref')) {
            response = deref(response[r'$ref'] as String);
          }
          yield* fromContent('$name → ${r.key}', response);
        }
      }
    }
  }

  test('в спецификации 5 запросов и в каждом есть примеры', () {
    final paths = spec['paths'] as Json;
    final operations = [
      for (final p in paths.entries)
        for (final m in (p.value as Json).keys) '${m.toUpperCase()} ${p.key}',
    ];
    expect(operations, [
      'GET /hotels',
      'GET /hotels/{hotelId}',
      'GET /hotels/{hotelId}/rooms',
      'POST /bookings',
      'GET /bookings/{bookingId}',
    ]);
    final withExamples = {
      for (final e in specExamples())
        e.$1.split(' →').first.split(' запрос').first,
    };
    expect(withExamples, hasLength(5));
  });

  test('примеры из спецификации соответствуют своим схемам', () {
    final bad = <String>[];
    var checked = 0;
    for (final (where, schema, value) in specExamples()) {
      checked++;
      conform(schema, value, where, bad);
    }
    expect(checked, greaterThan(15));
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('примеры успешных ответов разбираются кодом приложения', () {
    Json example(String path, String method, String code, String name) {
      final op = ((spec['paths'] as Json)[path] as Json)[method] as Json;
      final response = (op['responses'] as Json)[code] as Json;
      final media = (response['content'] as Json)['application/json'] as Json;
      var ex = (media['examples'] as Json)[name] as Json;
      if (ex.containsKey(r'$ref')) ex = deref(ex[r'$ref'] as String);
      return ex['value'] as Json;
    }

    final hotels = hotelsFromJson(example('/hotels', 'get', '200', 'found'));
    expect(hotels.first.name, 'Автор на Павелецкой');
    expect(hotels.first.location, isNotNull);
    expect(hotelsFromJson(example('/hotels', 'get', '200', 'empty')), isEmpty);

    final page = hotelPageFromJson(
      example('/hotels/{hotelId}', 'get', '200', 'hotel'),
    );
    expect(page.details.metro, 'Центр, 945 м');
    expect(page.reviews, isNotEmpty);

    final rooms = roomsFromJson(
      example('/hotels/{hotelId}/rooms', 'get', '200', 'available'),
    );
    expect(
      rooms.first.offers.last.freeCancellationUntil,
      DateTime(2026, 11, 19),
    );
    expect(
      roomsFromJson(
        example('/hotels/{hotelId}/rooms', 'get', '200', 'soldOut'),
      ),
      isEmpty,
    );

    final booking = bookingFromJson(
      example('/bookings/{bookingId}', 'get', '200', 'booking'),
    );
    expect(booking.number, 'TL-482915');
    expect(booking.total, 1035);
  });

  test('настоящие ответы заглушки соответствуют схемам', () async {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 11, 18))],
    );
    addTearDown(container.dispose);
    container
        .read(mockSettingsProvider.notifier)
        .update((_) => const MockSettings(latency: Duration.zero));
    final dio = container.read(dioProvider);
    final schemas = components['schemas'] as Json;

    Future<Json> get(String path, [Map<String, dynamic>? query]) async =>
        (await dio.get<Json>(path, queryParameters: query)).data!;

    final bad = <String>[];
    conform(
      schemas['HotelSearchResult'] as Json,
      await get('/hotels', {'city': 'Москва'}),
      'GET /hotels',
      bad,
    );
    conform(
      schemas['HotelDetails'] as Json,
      await get('/hotels/3'),
      'GET /hotels/3',
      bad,
    );
    conform(
      schemas['RoomsResult'] as Json,
      await get('/hotels/3/rooms', {
        'checkIn': '2026-11-20',
        'checkOut': '2026-11-21',
      }),
      'GET /hotels/3/rooms',
      bad,
    );

    final created = await dio.post<Json>(
      '/bookings',
      options: Options(headers: {'Idempotency-Key': 'contract-1'}),
      data: {
        'hotelId': '3',
        'roomId': 'r0',
        'offerId': 'o0',
        'checkIn': '2026-11-20',
        'checkOut': '2026-11-21',
        'adults': 1,
        'guests': [
          {'lastName': 'Иванов', 'firstName': 'Иван'},
        ],
        'contact': {'email': 'ivan.ivanov@example.com', 'phone': '79001234567'},
        'payment': {'mode': 'split', 'method': 'sbp'},
        'expectedTotal': 1035,
      },
    );
    expect(created.statusCode, 201);
    expect(created.headers.value('location'), startsWith('/bookings/'));
    conform(schemas['Booking'] as Json, created.data, 'POST /bookings', bad);
    conform(
      schemas['Booking'] as Json,
      await get('/bookings/${created.data!['id']}'),
      'GET /bookings/{id}',
      bad,
    );

    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('ответы об ошибках соответствуют схеме Error', () async {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 11, 18))],
    );
    addTearDown(container.dispose);
    container
        .read(mockSettingsProvider.notifier)
        .update((_) => const MockSettings(latency: Duration.zero));
    final dio = container.read(dioProvider);
    final error = components['schemas'] as Json;

    final bad = <String>[];
    for (final path in ['/hotels/999', '/bookings/nope', '/hotels']) {
      try {
        await dio.get<Json>(path);
        fail('$path должен вернуть ошибку');
      } on DioException catch (e) {
        conform((error['Error']) as Json, e.response!.data, path, bad);
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });
}
