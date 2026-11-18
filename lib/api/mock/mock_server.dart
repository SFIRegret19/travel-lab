import 'dart:convert';

import 'package:dio/dio.dart';

import '../../data/geo.dart';
import '../../data/hotel_rooms.dart';
import '../../data/hotels_catalog.dart';
import '../../data/mock_data.dart';
import '../../data/models/booking.dart';
import '../../data/models/hotel.dart';
import '../../features/checkout/checkout_pricing.dart';
import '../api_exception.dart';
import '../parsers.dart';
import 'mock_serializers.dart';
import 'mock_settings.dart';

/// Ответ сервера с ошибкой: статус и тело в формате схемы `Error`.
class _HttpError implements Exception {
  _HttpError(
    this.status,
    this.code,
    this.message, {
    this.fields = const [],
    this.currentTotal,
  });

  final int status;
  final ApiErrorCode code;
  final String message;
  final List<FieldError> fields;
  final int? currentTotal;

  Json toJson() => {
    'code': code.wire,
    'message': message,
    if (fields.isNotEmpty)
      'fields': [
        for (final f in fields) {'field': f.field, 'message': f.message},
      ],
    'currentTotal': ?currentTotal,
  };
}

_HttpError _bad(String message) =>
    _HttpError(400, ApiErrorCode.invalidParameter, message);

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Заглушка сервера: отвечает на пять запросов из `api/openapi.yaml` теми же
/// кодами и телами, что и настоящий сервер. Данные берёт из каталога.
class MockServer {
  MockServer({required this.settings, required this.today});

  final MockSettings Function() settings;
  final DateTime Function() today;

  final _bookings = <String, Json>{};
  final _replays = <String, ({String body, String bookingId})>{};
  int _sequence = 0;

  Future<ResponseBody> handle(RequestOptions options) async {
    final s = settings();
    if (s.latency > Duration.zero) await Future<void>.delayed(s.latency);
    if (s.offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Нет сети',
      );
    }
    try {
      if (s.serverError) {
        throw _HttpError(
          500,
          ApiErrorCode.internalError,
          'Что-то пошло не так. Попробуйте ещё раз',
        );
      }
      return _route(options, s);
    } on _HttpError catch (e) {
      return _response(e.status, e.toJson());
    } on TypeError {
      return _response(400, _bad('Некорректное тело запроса').toJson());
    } on FormatException {
      return _response(400, _bad('Некорректное значение в запросе').toJson());
    }
  }

  ResponseBody _route(RequestOptions o, MockSettings s) {
    final path = o.path;
    if (o.method == 'GET' && path == '/hotels') {
      return _response(200, _searchHotels(o.queryParameters, s));
    }
    if (o.method == 'GET') {
      final hotel = RegExp(r'^/hotels/([^/]+)$').firstMatch(path);
      if (hotel != null) {
        return _response(200, hotelPageJson(_hotel(hotel.group(1)!)));
      }
      final rooms = RegExp(r'^/hotels/([^/]+)/rooms$').firstMatch(path);
      if (rooms != null) {
        return _response(
          200,
          _rooms(_hotel(rooms.group(1)!), o.queryParameters, s),
        );
      }
      final booking = RegExp(r'^/bookings/([^/]+)$').firstMatch(path);
      if (booking != null) {
        final found = _bookings[booking.group(1)!];
        if (found == null) {
          throw _HttpError(
            404,
            ApiErrorCode.bookingNotFound,
            'Бронь не найдена',
          );
        }
        return _response(200, found);
      }
    }
    if (o.method == 'POST' && path == '/bookings') return _createBooking(o, s);
    throw _HttpError(404, ApiErrorCode.invalidParameter, 'Неизвестный адрес');
  }

  Hotel _hotel(String id) =>
      hotelById(id) ??
      (throw _HttpError(404, ApiErrorCode.hotelNotFound, 'Отель не найден'));

  Json _searchHotels(Map<String, dynamic> q, MockSettings s) {
    final city = q['city']?.toString().trim() ?? '';
    if (city.isEmpty) throw _bad('Не указан город');
    final from = _date(q['checkIn']);
    final to = _date(q['checkOut']);
    if ((from == null) != (to == null)) throw _bad('Укажите обе даты');
    if (from != null && !to!.isAfter(from)) {
      throw _bad('Дата выезда должна быть позже даты заезда');
    }
    final adults = _int(q['adults'], 1, 10, 1, 'adults');
    _int(q['children'], 0, 6, 0, 'children');
    _int(q['rooms'], 1, adults, 1, 'rooms');
    final type = q['type']?.toString() ?? 'any';
    if (!const ['any', 'hotels', 'apartments'].contains(type)) {
      throw _bad('Неизвестный тип размещения');
    }

    // Отели вымышленные: по любому известному городу отдаём весь каталог.
    final hotels = !mockCities.contains(city) || s.noResults
        ? const <Hotel>[]
        : [
            for (final h in hotelsCatalog)
              if (type == 'any' || (type == 'apartments') == h.isApartment) h,
          ];
    return {
      'items': [
        for (final h in hotels) hotelSummaryJson(h, hotelPosition(h, city)),
      ],
    };
  }

  Json _rooms(Hotel hotel, Map<String, dynamic> q, MockSettings s) {
    final from = _date(q['checkIn']);
    final to = _date(q['checkOut']);
    if (from == null || to == null) throw _bad('Укажите даты заезда и выезда');
    if (!to.isAfter(from)) {
      throw _bad('Дата выезда должна быть позже даты заезда');
    }
    _int(q['adults'], 1, 10, 1, 'adults');
    _int(q['children'], 0, 6, 0, 'children');
    if (s.noRooms) return {'rooms': <Json>[]};
    final until = freeCancelUntil(from, today());
    return {
      'rooms': [for (final r in roomsFor(hotel)) roomJson(r, until)],
    };
  }

  ResponseBody _createBooking(RequestOptions o, MockSettings s) {
    final key = o.headers['Idempotency-Key']?.toString();
    if (key == null || key.isEmpty) {
      throw _bad('Не передан заголовок Idempotency-Key');
    }
    final raw = o.data;
    if (raw is! Map) throw _bad('Тело запроса должно быть JSON-объектом');
    final body = Json.from(raw);
    final encoded = jsonEncode(body);

    final replay = _replays[key];
    if (replay != null) {
      if (replay.body != encoded) {
        throw _bad('Этот ключ уже использован с другим запросом');
      }
      return _response(200, _bookings[replay.bookingId]!);
    }

    final hotel = _hotel(body['hotelId'] as String);
    final room = roomsFor(hotel).where((r) => r.id == body['roomId']);
    if (room.isEmpty) {
      throw _HttpError(404, ApiErrorCode.offerNotFound, 'Номер не найден');
    }
    final offer = room.first.offers.where((x) => x.id == body['offerId']);
    if (offer.isEmpty) {
      throw _HttpError(404, ApiErrorCode.offerNotFound, 'Тариф не найден');
    }

    final checkIn = parseIsoDate(body['checkIn'] as String);
    final checkOut = parseIsoDate(body['checkOut'] as String);
    if (!checkOut.isAfter(checkIn)) {
      throw _bad('Дата выезда должна быть позже даты заезда');
    }

    final promo = (body['promoCode'] as String?)?.trim() ?? '';
    final fields = _validate(body, promo, s);
    if (fields.isNotEmpty) {
      throw _HttpError(
        422,
        ApiErrorCode.validationFailed,
        'Проверьте введённые данные',
        fields: fields,
      );
    }
    if (s.soldOut) {
      throw _HttpError(
        409,
        ApiErrorCode.offerUnavailable,
        'Этот номер уже забронирован',
      );
    }

    final nights = DateTime.utc(
      checkOut.year,
      checkOut.month,
      checkOut.day,
    ).difference(DateTime.utc(checkIn.year, checkIn.month, checkIn.day)).inDays;
    final price = CheckoutPrice(
      shownTotal: offer.first.price * nights,
      discountPercent: offer.first.discountPercent,
      lateCheckout: body['lateCheckout'] as bool? ?? false,
      lateCheckoutPrice: lateCheckoutPriceFor(hotel.price),
      promoPercent: promoPercentFor(promo) ?? 0,
    );
    var total = price.total;
    if (s.priceChanged) total += (total * 0.04).round();
    if (body['expectedTotal'] as int != total) {
      throw _HttpError(
        409,
        ApiErrorCode.priceChanged,
        'Цена изменилась',
        currentTotal: total,
      );
    }

    final split = (body['payment'] as Json)['mode'] == PayMode.split.name;
    _sequence++;
    final id = 'bk_${(0x5e8d2a + _sequence).toRadixString(16)}';
    final booking = bookingJson(
      id: id,
      number: 'TL-${482915 + _sequence}',
      hotel: hotel,
      room: room.first,
      offer: offer.first,
      cancelUntil: freeCancelUntil(checkIn, today()),
      request: body,
      total: total,
      paidNow: split ? (total / 4).ceil() : total,
    );
    _bookings[id] = booking;
    _replays[key] = (body: encoded, bookingId: id);
    return _response(
      201,
      booking,
      headers: {
        'location': ['/bookings/$id'],
      },
    );
  }

  /// Проверка полей тела; пустой список, если всё в порядке.
  List<FieldError> _validate(Json body, String promo, MockSettings s) {
    final fields = <FieldError>[];
    final contact = body['contact'] as Json;
    final email = (contact['email'] as String).trim();
    final phone = contact['phone'] as String;
    if (s.validationError || !_email.hasMatch(email)) {
      fields.add(const FieldError('contact.email', 'Некорректная почта'));
    }
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      fields.add(const FieldError('contact.phone', 'Некорректный телефон'));
    }
    final guests = body['guests'] as List;
    if (guests.length != body['adults']) {
      fields.add(
        const FieldError('guests', 'Нужно указать всех взрослых гостей'),
      );
    }
    for (var i = 0; i < guests.length; i++) {
      final g = guests[i] as Json;
      if ((g['lastName'] as String).trim().isEmpty) {
        fields.add(FieldError('guests[$i].lastName', 'Обязательное поле'));
      }
      if ((g['firstName'] as String).trim().isEmpty) {
        fields.add(FieldError('guests[$i].firstName', 'Обязательное поле'));
      }
    }
    if (promo.isNotEmpty && promoPercentFor(promo) == null) {
      fields.add(const FieldError('promoCode', 'Промокод не найден'));
    }
    return fields;
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    final date = DateTime.tryParse(value.toString());
    if (date == null) throw _bad('Дата должна быть в формате yyyy-MM-dd');
    return date;
  }

  int _int(Object? value, int min, int max, int fallback, String name) {
    if (value == null) return fallback;
    final n = int.tryParse(value.toString());
    if (n == null || n < min || n > max) {
      throw _bad('Параметр $name должен быть от $min до $max');
    }
    return n;
  }

  ResponseBody _response(
    int status,
    Json body, {
    Map<String, List<String>> headers = const {},
  }) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );
  }
}
