import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_exception.dart';
import '../../api/api_providers.dart';
import '../../core/format/formatters.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/time/today_provider.dart';
import '../../core/uuid.dart';
import '../../core/widgets/error_state.dart';
import '../../data/hotel_details.dart';
import '../../data/hotel_rooms.dart';
import '../../data/models/booking.dart';
import '../hotel/widgets/section_card.dart';
import '../rooms/booking_selection.dart';
import '../rooms/rooms_state.dart';
import '../search/search_provider.dart';
import 'checkout_pricing.dart';
import 'widgets/booking_cards.dart';
import 'widgets/checkout_sheets.dart';
import 'widgets/form_fields.dart';
import 'widgets/payment_cards.dart';

class _Spec {
  _Spec(this.validate, [String text = ''])
    : controller = TextEditingController(text: text);

  final String? Function(String) validate;
  final TextEditingController controller;
  final focus = FocusNode();

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

String? _required(String v) => v.trim().isEmpty ? 'Обязательное поле' : null;

String? _email(String v) {
  if (v.trim().isEmpty) return 'Укажите почту';
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
      ? null
      : 'Некорректная почта';
}

String? _phone(String v) {
  if (v.trim().isEmpty) return 'Укажите телефон';
  return v.replaceAll(RegExp(r'\D'), '').length >= 10
      ? null
      : 'Некорректный телефон';
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _emailSpec = _Spec(_email, 'ivan.ivanov@example.com');
  final _phoneSpec = _Spec(_phone, '79001234567');
  late final List<_Spec> _surnames;
  late final List<_Spec> _names;
  final _errors = <_Spec, String>{};

  bool _lateCheckout = false;
  PayMode _mode = PayMode.full;
  int _method = 0;
  String? _promo;
  bool _consent = true;

  bool _submitting = false;

  /// Поправка к сумме после ответа сервера `PRICE_CHANGED`.
  int _surcharge = 0;

  /// Ключ идемпотентности живёт, пока не изменилось тело запроса: повтор того
  /// же запроса после обрыва связи не создаст вторую бронь.
  String? _attemptBody;
  String? _attemptKey;

  Iterable<_Spec> get _all => [
    _emailSpec,
    _phoneSpec,
    for (var i = 0; i < _surnames.length; i++) ...[_surnames[i], _names[i]],
  ];

  @override
  void initState() {
    super.initState();
    final adults = ref.read(searchProvider).adults;
    _surnames = [
      for (var i = 0; i < adults; i++) _Spec(_required, i == 0 ? 'Иванов' : ''),
    ];
    _names = [
      for (var i = 0; i < adults; i++) _Spec(_required, i == 0 ? 'Иван' : ''),
    ];

    // Модалка один раз при входе, а не из build: иначе она вставала бы
    // заново при каждой перерисовке.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selection = ref.read(bookingSelectionProvider);
      if (!mounted || selection == null) return;
      final nights = ref.read(searchProvider).nights;
      final shown = selection.offer.price * nights;
      showPriceChangedSheet(
        context,
        oldPrice: shown,
        newPrice: priceAfterChange(shown),
      );
    });
  }

  @override
  void dispose() {
    for (final spec in _all) {
      spec.dispose();
    }
    super.dispose();
  }

  Future<void> _pay(
    BookingSelection selection,
    CheckoutPrice price,
    DateTime from,
    DateTime to,
  ) async {
    if (_submitting) return;
    final errors = <_Spec, String>{};
    for (final spec in _all) {
      final message = spec.validate(spec.controller.text);
      if (message != null) errors[spec] = message;
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) {
      errors.keys.first.focus.requestFocus();
      return;
    }

    final params = ref.read(searchProvider);
    final request = BookingRequest(
      hotelId: selection.hotel.id,
      roomId: selection.room.id,
      offerId: selection.offer.id,
      checkIn: from,
      checkOut: to,
      adults: params.adults,
      children: params.children,
      guests: [
        for (var i = 0; i < _surnames.length; i++)
          BookingGuest(
            lastName: _surnames[i].controller.text.trim(),
            firstName: _names[i].controller.text.trim(),
          ),
      ],
      email: _emailSpec.controller.text.trim(),
      phone: _phoneSpec.controller.text.trim(),
      lateCheckout: _lateCheckout,
      payMode: _mode,
      payMethod: payMethods[_method].code,
      expectedTotal: price.total,
      promoCode: _promo,
    );
    final body = jsonEncode(request.toJson());
    if (body != _attemptBody) {
      _attemptBody = body;
      _attemptKey = newUuid();
    }

    setState(() => _submitting = true);
    ApiException? failure;
    try {
      final booking = await ref
          .read(travelApiProvider)
          .createBooking(request, idempotencyKey: _attemptKey!);
      if (!mounted) return;
      context.go(Routes.confirmationPath(booking.id));
    } on ApiException catch (e) {
      failure = e;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    // Кнопка уже свободна, пока пользователь читает модалку или диалог.
    if (failure != null && mounted) {
      await _onError(failure, selection, price, from, to);
    }
  }

  /// Что делать с ответом об ошибке: у каждого кода своё состояние экрана.
  Future<void> _onError(
    ApiException e,
    BookingSelection selection,
    CheckoutPrice price,
    DateTime from,
    DateTime to,
  ) async {
    switch (e.code) {
      case ApiErrorCode.priceChanged:
        final total = e.currentTotal;
        if (total != null) {
          await showPriceChangedSheet(
            context,
            oldPrice: price.total,
            newPrice: total,
          );
          if (mounted) setState(() => _surcharge += total - price.total);
          return;
        }
      case ApiErrorCode.offerUnavailable:
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialog) => AlertDialog(
            key: const Key('offer_unavailable_dialog'),
            title: const Text('Номер уже забронирован'),
            content: const Text(
              'Этот номер только что забронировал другой гость. '
              'Выберите другой номер.',
            ),
            actions: [
              TextButton(
                key: const Key('offer_unavailable_ok'),
                onPressed: () => Navigator.pop(dialog),
                child: const Text('К номерам'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        ref.invalidate(roomsProvider(selection.hotel.id));
        if (context.canPop()) context.pop();
        return;
      case ApiErrorCode.validationFailed:
        _showFieldErrors(e);
        return;
      default:
    }

    // Нет сети, ошибка сервера и прочее: форма остаётся заполненной,
    // «Повторить» отправляет тот же запрос с тем же ключом.
    final (title, _) = describeError(e);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          key: const Key('checkout_error'),
          content: Text('$title. Заказ не оформлен'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Повторить',
            onPressed: () => _pay(selection, price, from, to),
          ),
        ),
      );
  }

  /// Ошибки полей от сервера (422) показываем под теми же полями формы.
  void _showFieldErrors(ApiException e) {
    final errors = <_Spec, String>{};
    var promoRejected = false;
    String? other;
    for (final f in e.fields) {
      final spec = _specFor(f.field);
      if (spec != null) {
        errors[spec] = f.message;
      } else if (f.field == 'promoCode') {
        promoRejected = true;
      } else {
        other = f.message;
      }
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
      if (promoRejected) _promo = null;
    });
    if (errors.isNotEmpty) errors.keys.first.focus.requestFocus();
    final note = promoRejected
        ? 'Промокод не найден'
        : (errors.isEmpty ? (other ?? e.message) : null);
    if (note != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(note), behavior: SnackBarBehavior.floating),
        );
    }
  }

  _Spec? _specFor(String field) {
    if (field == 'contact.email') return _emailSpec;
    if (field == 'contact.phone') return _phoneSpec;
    final guest = RegExp(r'^guests\[(\d+)\]\.(lastName|firstName)$');
    final m = guest.firstMatch(field);
    if (m == null) return null;
    final i = int.parse(m.group(1)!);
    if (i >= _surnames.length) return null;
    return m.group(2) == 'lastName' ? _surnames[i] : _names[i];
  }

  Future<void> _openPromo() async {
    final code = await showPromoSheet(context, initial: _promo ?? '');
    if (code != null && mounted) setState(() => _promo = code);
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(bookingSelectionProvider);
    if (selection == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Тариф не выбран', key: Key('checkout_not_found')),
        ),
      );
    }

    final hotel = selection.hotel;
    final offer = selection.offer;
    final params = ref.watch(searchProvider);
    final today = ref.watch(todayProvider);
    final (from, to) = params.stayRange(today);
    final daysUntil = DateTime.utc(
      from.year,
      from.month,
      from.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    final details = selection.details;
    final price = CheckoutPrice(
      shownTotal: offer.price * params.nights,
      discountPercent: offer.discountPercent,
      lateCheckout: _lateCheckout,
      lateCheckoutPrice: lateCheckoutPriceFor(hotel.price),
      promoPercent: _promo == null ? 0 : promoCodes[_promo]!,
      surcharge: _surcharge,
    );
    final cancelLine = cancelText(offer);
    final payTitle = _mode == PayMode.split ? price.splitPart : price.total;
    final until = daysUntil == 0
        ? 'Заезд сегодня'
        : 'До заезда ${formatDays(daysUntil)}';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          key: const Key('checkout_back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hotel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Text(
              '${formatRangeShort(from, to)}  Гостей: ${params.guests}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        key: const Key('checkout_scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Column(
          children: [
            StayCard(
              hotelName: hotel.name,
              address: '${params.displayCity}, ${hotel.street}',
              checkIn: from,
              checkOut: to,
              daysUntil: daysUntil,
              checkInTime: details.checkInTime,
              checkOutTime: details.checkOutTime,
            ),
            RoomSummaryCard(
              room: selection.room,
              offer: offer,
              cancelText: cancelLine,
            ),
            ServicesCard(
              priceLabel: 'До 23:00, ${formatPrice(price.lateCheckoutPrice)}',
              value: _lateCheckout,
              onChanged: (v) => setState(() => _lateCheckout = v),
            ),
            RulesCard(
              checkIn: details.checkInRule,
              checkOut: details.checkOutRule,
            ),
            SectionCard(
              title: 'Контакты покупателя',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Сюда отправим информацию о бронировании',
                    style: TextStyle(fontSize: 17),
                  ),
                  const SizedBox(height: 12),
                  ClearableField(
                    name: 'email',
                    label: 'Почта*',
                    controller: _emailSpec.controller,
                    focusNode: _emailSpec.focus,
                    errorText: _errors[_emailSpec],
                    keyboardType: TextInputType.emailAddress,
                    onChanged: () => setState(() => _errors.remove(_emailSpec)),
                  ),
                  const SizedBox(height: 12),
                  ClearableField(
                    name: 'phone',
                    label: 'Телефон*',
                    controller: _phoneSpec.controller,
                    focusNode: _phoneSpec.focus,
                    errorText: _errors[_phoneSpec],
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
                    ],
                    onChanged: () => setState(() => _errors.remove(_phoneSpec)),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < _surnames.length; i++)
              SectionCard(
                title: 'Гость ${i + 1}, взрослый',
                child: Column(
                  children: [
                    ClearableField(
                      name: 'surname_$i',
                      label: 'Фамилия*',
                      controller: _surnames[i].controller,
                      focusNode: _surnames[i].focus,
                      errorText: _errors[_surnames[i]],
                      onChanged: () =>
                          setState(() => _errors.remove(_surnames[i])),
                    ),
                    const SizedBox(height: 12),
                    ClearableField(
                      name: 'name_$i',
                      label: 'Имя*',
                      controller: _names[i].controller,
                      focusNode: _names[i].focus,
                      errorText: _errors[_names[i]],
                      onChanged: () =>
                          setState(() => _errors.remove(_names[i])),
                    ),
                  ],
                ),
              ),
            PaymentCard(
              mode: _mode,
              onMode: (m) => setState(() => _mode = m),
              splitPart: price.splitPart,
              method: _method,
              onMethod: (i) => setState(() => _method = i),
            ),
            PriceSummaryCard(
              price: price,
              nights: params.nights,
              promo: _promo,
              onPromo: _openPromo,
              onRemovePromo: () => setState(() => _promo = null),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                children: [
                  Text(cancelLine, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 26),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FilledButton(
                        key: const Key('checkout_pay'),
                        onPressed: _submitting
                            ? null
                            : () => _pay(selection, price, from, to),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(76),
                          padding: const EdgeInsets.only(top: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_submitting)
                              const SizedBox(
                                key: Key('checkout_submitting'),
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            else
                              Text(
                                'Оплатить ${formatPrice(payTitle)}',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Text(
                              _submitting
                                  ? 'Оформляем заказ…'
                                  : payMethods[_method].label,
                              key: const Key('checkout_pay_method'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -18,
                        right: 14,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              until,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.boltYellow,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        key: const Key('consent_checkbox'),
                        value: _consent,
                        onChanged: (v) => setState(() => _consent = v ?? false),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Я даю согласие на получение информационных и '
                            'рекламных сообщений от сервиса Travel Lab на '
                            'условиях пользовательского соглашения и '
                            'политики конфиденциальности.',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Нажимая «Оплатить», вы соглашаетесь с пользовательским '
                    'соглашением и условиями бронирования. Мы подтвердим '
                    'бронирование и спишем указанную сумму сегодня.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
