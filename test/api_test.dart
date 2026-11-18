import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_lab/api/api_exception.dart';
import 'package:travel_lab/api/api_providers.dart';
import 'package:travel_lab/api/mock/mock_settings.dart';
import 'package:travel_lab/api/travel_api.dart';
import 'package:travel_lab/core/time/today_provider.dart';
import 'package:travel_lab/data/hotel_details.dart';
import 'package:travel_lab/data/hotels_catalog.dart';
import 'package:travel_lab/data/models/booking.dart';
import 'package:travel_lab/features/search/search_params.dart';

void main() {
  final checkIn = DateTime(2026, 11, 20);
  final checkOut = DateTime(2026, 11, 21);
  const instant = MockSettings(latency: Duration.zero);

  TravelApi apiWith([MockSettings settings = instant]) {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 11, 18))],
    );
    addTearDown(container.dispose);
    container.read(mockSettingsProvider.notifier).update((_) => settings);
    return container.read(travelApiProvider);
  }

  /// Ожидаем ApiException с заданным статусом и кодом.
  Matcher apiError(int? status, ApiErrorCode code) => throwsA(
    isA<ApiException>()
        .having((e) => e.status, 'status', status)
        .having((e) => e.code, 'code', code),
  );

  /// Бронь отеля №3, номер r0, тариф o0 (1 089 ₽ за ночь, после пересчёта 1 035 ₽).
  BookingRequest request({
    int total = 1035,
    String email = 'ivan.ivanov@example.com',
    String phone = '79001234567',
    List<BookingGuest>? guests,
    int adults = 1,
    String? promo,
    PayMode mode = PayMode.full,
    bool lateCheckout = false,
  }) {
    return BookingRequest(
      hotelId: '3',
      roomId: 'r0',
      offerId: 'o0',
      checkIn: checkIn,
      checkOut: checkOut,
      adults: adults,
      children: 0,
      guests:
          guests ?? const [BookingGuest(lastName: 'Иванов', firstName: 'Иван')],
      email: email,
      phone: phone,
      lateCheckout: lateCheckout,
      payMode: mode,
      payMethod: 'mastercard',
      expectedTotal: total,
      promoCode: promo,
    );
  }

  group('GET /hotels', () {
    test('отдаёт весь каталог с координатами и ценой за ночь', () async {
      final hotels = await apiWith().searchHotels(
        SearchParams(city: 'Москва', checkIn: checkIn, checkOut: checkOut),
      );
      expect(hotels.map((h) => h.id), hotelsCatalog.map((h) => h.id));
      final loft = hotels.firstWhere((h) => h.id == '2');
      expect(loft.name, 'The Loft');
      expect(loft.price, 2079);
      expect(loft.stars, 4);
      expect(loft.location, isNotNull);
      expect(hotels.firstWhere((h) => h.id == '3').oldPrice, 1210);
    });

    test('тип размещения «квартиры» оставляет только апартаменты', () async {
      final hotels = await apiWith().searchHotels(
        const SearchParams(city: 'Москва', type: AccommodationType.apartments),
      );
      expect(hotels, isNotEmpty);
      expect(hotels.every((h) => h.isApartment), isTrue);
    });

    test('пустая выдача это 200 с пустым списком, а не ошибка', () async {
      expect(
        await apiWith(instant.copyWith(noResults: true))
            .searchHotels(const SearchParams(city: 'Москва')),
        isEmpty,
      );
      expect(
        await apiWith().searchHotels(const SearchParams(city: 'Нигде')),
        isEmpty,
      );
    });

    test('выезд не позже заезда: 400', () async {
      await expectLater(
        apiWith().searchHotels(
          SearchParams(city: 'Москва', checkIn: checkIn, checkOut: checkIn),
        ),
        apiError(400, ApiErrorCode.invalidParameter),
      );
    });
  });

  group('GET /hotels/{hotelId}', () {
    test('возвращает отель, подробности и отзывы', () async {
      final page = await apiWith().getHotel('3');
      final expected = detailsFor(hotelsCatalog.firstWhere((h) => h.id == '3'));
      expect(page.hotel.name, 'Автор на Павелецкой');
      expect(page.details.description, expected.description);
      expect(page.details.checkIn, 'С 14:00\nдо 00:00');
      expect(page.details.metro, 'Центр, 945 м');
      expect(page.details.facts.map((f) => f.$1), [
        'Хостел',
        '2006',
        '2019',
        '47',
      ]);
      expect(page.details.scores.first, ('Цена/качество', 94));
      expect(page.reviews, hasLength(6));
      expect(page.reviews.first.author, 'Дмитрий');
      expect(page.reviews.first.stay, 'июль 2026 · 1 ночь');
      expect(page.reviews.first.reply, isNotNull);
    });

    test('неизвестный отель: 404', () async {
      await expectLater(
        apiWith().getHotel('999'),
        apiError(404, ApiErrorCode.hotelNotFound),
      );
    });
  });

  group('GET /hotels/{hotelId}/rooms', () {
    Future<void> rooms(TravelApi api, {String id = '3', DateTime? out}) =>
        api.getRooms(
          id,
          checkIn: checkIn,
          checkOut: out ?? checkOut,
          adults: 1,
          children: 0,
        );

    test('номера и тарифы, срок отмены считает сервер', () async {
      final result = await apiWith().getRooms(
        '3',
        checkIn: checkIn,
        checkOut: checkOut,
        adults: 1,
        children: 0,
      );
      expect(result, hasLength(3));
      final offers = result.first.offers;
      expect(offers.first.price, 1089);
      expect(offers.first.refundable, isFalse);
      expect(offers.first.freeCancellationUntil, isNull);
      expect(offers.last.refundable, isTrue);
      expect(offers.last.freeCancellationUntil, DateTime(2026, 11, 19));
    });

    test('нет свободных номеров: 200 и пустой список', () async {
      final result = await apiWith(instant.copyWith(noRooms: true)).getRooms(
        '3',
        checkIn: checkIn,
        checkOut: checkOut,
        adults: 1,
        children: 0,
      );
      expect(result, isEmpty);
    });

    test('неверные даты: 400, неизвестный отель: 404', () async {
      await expectLater(
        rooms(apiWith(), out: checkIn),
        apiError(400, ApiErrorCode.invalidParameter),
      );
      await expectLater(
        rooms(apiWith(), id: '999'),
        apiError(404, ApiErrorCode.hotelNotFound),
      );
    });
  });

  group('POST /bookings и GET /bookings/{bookingId}', () {
    test('оформление: бронь создаётся и читается по id', () async {
      final api = apiWith();
      final booking = await api.createBooking(
        request(),
        idempotencyKey: 'key-1',
      );
      expect(booking.number, startsWith('TL-'));
      expect(booking.hotelName, 'Автор на Павелецкой');
      expect(booking.total, 1035);
      expect(booking.paidNow, 1035);
      expect(booking.guests.single.fullName, 'Иванов Иван');

      final loaded = await api.getBooking(booking.id);
      expect(loaded.number, booking.number);
      expect(loaded.roomTitle, booking.roomTitle);
    });

    test('Сплит списывает четверть, промокод уменьшает сумму', () async {
      final booking = await apiWith().createBooking(
        request(total: 931, promo: 'lab10', mode: PayMode.split),
        idempotencyKey: 'key-2',
      );
      expect(booking.total, 931);
      expect(booking.paidNow, 233);
      expect(booking.remaining, 698);
    });

    test('поздний выезд входит в сумму', () async {
      final booking = await apiWith().createBooking(
        request(total: 1035 + 1200, lateCheckout: true),
        idempotencyKey: 'key-3',
      );
      expect(booking.total, 2235);
      expect(booking.lateCheckout, isTrue);
    });

    test('сумма не сошлась: 409 PRICE_CHANGED с новой суммой', () async {
      await expectLater(
        apiWith().createBooking(request(total: 1000), idempotencyKey: 'k'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.code, 'code', ApiErrorCode.priceChanged)
              .having((e) => e.currentTotal, 'currentTotal', 1035),
        ),
      );
    });

    test(
      'сервер подорожал: после согласия с новой суммой бронь создаётся',
      () async {
        final api = apiWith(instant.copyWith(priceChanged: true));
        ApiException? error;
        try {
          await api.createBooking(request(), idempotencyKey: 'k1');
        } on ApiException catch (e) {
          error = e;
        }
        expect(error?.code, ApiErrorCode.priceChanged);
        expect(error?.currentTotal, 1076);

        final booking = await api.createBooking(
          request(total: error!.currentTotal!),
          idempotencyKey: 'k2',
        );
        expect(booking.total, 1076);
      },
    );

    test('тариф раскуплен: 409 OFFER_UNAVAILABLE', () async {
      await expectLater(
        apiWith(instant.copyWith(soldOut: true))
            .createBooking(request(), idempotencyKey: 'k'),
        apiError(409, ApiErrorCode.offerUnavailable),
      );
    });

    test('поля не прошли проверку: 422 со списком полей', () async {
      ApiException? error;
      try {
        await apiWith().createBooking(
          request(
            email: 'не-почта',
            phone: '123',
            promo: 'NOPE',
            guests: const [BookingGuest(lastName: ' ', firstName: 'Иван')],
          ),
          idempotencyKey: 'k',
        );
      } on ApiException catch (e) {
        error = e;
      }
      expect(error?.status, 422);
      expect(error?.code, ApiErrorCode.validationFailed);
      expect(error!.fields.map((f) => f.field), [
        'contact.email',
        'contact.phone',
        'guests[0].lastName',
        'promoCode',
      ]);
    });

    test('гостей меньше, чем взрослых: 422 по полю guests', () async {
      ApiException? error;
      try {
        await apiWith().createBooking(request(adults: 2), idempotencyKey: 'k');
      } on ApiException catch (e) {
        error = e;
      }
      expect(error?.fields.map((f) => f.field), ['guests']);
    });

    test('повтор с тем же ключом возвращает ту же бронь', () async {
      final api = apiWith();
      final first = await api.createBooking(request(), idempotencyKey: 'same');
      final again = await api.createBooking(request(), idempotencyKey: 'same');
      expect(again.id, first.id);
      expect(again.number, first.number);
      final other = await api.createBooking(request(), idempotencyKey: 'new');
      expect(other.id, isNot(first.id));
    });

    test('тот же ключ с другим телом: 400', () async {
      final api = apiWith();
      await api.createBooking(request(), idempotencyKey: 'same');
      await expectLater(
        api.createBooking(
          request(total: 931, promo: 'LAB10'),
          idempotencyKey: 'same',
        ),
        apiError(400, ApiErrorCode.invalidParameter),
      );
    });

    test('неизвестная бронь: 404', () async {
      await expectLater(
        apiWith().getBooking('bk_nope'),
        apiError(404, ApiErrorCode.bookingNotFound),
      );
    });
  });

  group('сбои', () {
    test('нет сети: исключение без статуса', () async {
      final api = apiWith(instant.copyWith(offline: true));
      await expectLater(
        api.getHotel('3'),
        throwsA(
          isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', true),
        ),
      );
    });

    test('ошибка сервера: 500 на любом запросе', () async {
      final api = apiWith(instant.copyWith(serverError: true));
      await expectLater(
        api.searchHotels(const SearchParams(city: 'Москва')),
        apiError(500, ApiErrorCode.internalError),
      );
      await expectLater(
        api.getBooking('x'),
        apiError(500, ApiErrorCode.internalError),
      );
    });
  });
}
