/// Машинные коды ошибок из схемы `Error` в `api/openapi.yaml`.
enum ApiErrorCode {
  invalidParameter('INVALID_PARAMETER'),
  hotelNotFound('HOTEL_NOT_FOUND'),
  offerNotFound('OFFER_NOT_FOUND'),
  bookingNotFound('BOOKING_NOT_FOUND'),
  offerUnavailable('OFFER_UNAVAILABLE'),
  priceChanged('PRICE_CHANGED'),
  validationFailed('VALIDATION_FAILED'),
  internalError('INTERNAL_ERROR'),
  unknown('');

  const ApiErrorCode(this.wire);
  final String wire;

  static ApiErrorCode parse(Object? wire) => values.firstWhere(
    (c) => c.wire == wire,
    orElse: () => ApiErrorCode.unknown,
  );
}

/// Ошибка в конкретном поле запроса (ответ `422`).
class FieldError {
  const FieldError(this.field, this.message);

  /// Путь к полю: `contact.email`, `guests[0].lastName`, `promoCode`.
  final String field;
  final String message;
}

/// Всё, что может пойти не так при обращении к серверу.
///
/// [status] равен null, если ответа нет вовсе (нет сети, обрыв): это
/// состояние клиента, а не ответ сервера.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.fields = const [],
    this.currentTotal,
  });

  const ApiException.network()
    : status = null,
      code = ApiErrorCode.unknown,
      message = 'Нет соединения с сервером',
      fields = const [],
      currentTotal = null;

  const ApiException.malformed()
    : status = 200,
      code = ApiErrorCode.unknown,
      message = 'Сервер вернул непонятный ответ',
      fields = const [],
      currentTotal = null;

  factory ApiException.fromResponse(int status, Object? body) {
    if (body is! Map<String, dynamic>) {
      return ApiException(
        status: status,
        code: ApiErrorCode.unknown,
        message: 'Ошибка сервера ($status)',
      );
    }
    return ApiException(
      status: status,
      code: ApiErrorCode.parse(body['code']),
      message: body['message'] as String? ?? 'Ошибка сервера ($status)',
      fields: [
        for (final f in (body['fields'] as List? ?? const []))
          FieldError(
            (f as Map<String, dynamic>)['field'] as String,
            f['message'] as String,
          ),
      ],
      currentTotal: body['currentTotal'] as int?,
    );
  }

  final int? status;
  final ApiErrorCode code;
  final String message;
  final List<FieldError> fields;

  /// Для `PRICE_CHANGED`: новая итоговая сумма.
  final int? currentTotal;

  bool get isNetwork => status == null;
  bool get isNotFound => status == 404;

  @override
  String toString() => 'ApiException($status, ${code.wire}, $message)';
}
