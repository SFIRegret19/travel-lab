import 'package:dio/dio.dart';

import '../data/hotel_details.dart';
import '../data/hotel_rooms.dart';
import '../data/models/booking.dart';
import '../data/models/hotel.dart';
import '../features/search/search_params.dart';
import 'api_exception.dart';
import 'parsers.dart';

/// Адрес сервера из `api/openapi.yaml`. В приложении запросы по нему
/// обслуживает заглушка (`MockAdapter`), настоящего сервера нет.
const apiBaseUrl = 'https://api.travel-lab.example/v1';

/// Клиент пяти запросов основного сценария. Возвращает модели приложения,
/// а любую неудачу превращает в [ApiException].
class TravelApi {
  TravelApi(this._dio);

  final Dio _dio;

  /// `GET /hotels`: выдача на экране «Результаты» и на карте.
  Future<List<Hotel>> searchHotels(SearchParams p) async {
    final json = await _request(
      'GET',
      '/hotels',
      query: {
        'city': p.displayCity,
        if (p.hasFullRange) ...{
          'checkIn': isoDate(p.checkIn!),
          'checkOut': isoDate(p.checkOut!),
        },
        'adults': p.adults,
        'children': p.children,
        'rooms': p.rooms,
        'type': p.type.name,
      },
    );
    return _parse(() => hotelsFromJson(json));
  }

  /// `GET /hotels/{hotelId}`: карточка отеля, подробности и отзывы.
  Future<HotelPage> getHotel(String hotelId) async {
    final json = await _request('GET', '/hotels/$hotelId');
    return _parse(() => hotelPageFromJson(json));
  }

  /// `GET /hotels/{hotelId}/rooms`: номера и тарифы на даты. Пустой список
  /// означает «нет свободных номеров», это не ошибка.
  Future<List<Room>> getRooms(
    String hotelId, {
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
  }) async {
    final json = await _request(
      'GET',
      '/hotels/$hotelId/rooms',
      query: {
        'checkIn': isoDate(checkIn),
        'checkOut': isoDate(checkOut),
        'adults': adults,
        'children': children,
      },
    );
    return _parse(() => roomsFromJson(json));
  }

  /// `POST /bookings`. [idempotencyKey] один на попытку оформления:
  /// повтор с тем же ключом не создаёт вторую бронь.
  Future<Booking> createBooking(
    BookingRequest request, {
    required String idempotencyKey,
  }) async {
    final json = await _request(
      'POST',
      '/bookings',
      body: request.toJson(),
      headers: {'Idempotency-Key': idempotencyKey},
    );
    return _parse(() => bookingFromJson(json));
  }

  /// `GET /bookings/{bookingId}`: данные экрана «Подтверждение».
  Future<Booking> getBooking(String bookingId) async {
    final json = await _request('GET', '/bookings/$bookingId');
    return _parse(() => bookingFromJson(json));
  }

  Future<Json> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.request<Json>(
        path,
        queryParameters: query,
        data: body,
        options: Options(method: method, headers: headers),
      );
      final data = response.data;
      if (data == null) throw const ApiException.malformed();
      return data;
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) throw const ApiException.network();
      throw ApiException.fromResponse(response.statusCode ?? 0, response.data);
    }
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on TypeError {
      throw const ApiException.malformed();
    } on FormatException {
      throw const ApiException.malformed();
    } on ArgumentError {
      throw const ApiException.malformed();
    }
  }
}
