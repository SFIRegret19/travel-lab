import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/formatters.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/time/today_provider.dart';
import '../../data/hotel_details.dart';
import '../../data/hotel_rooms.dart';
import '../hotel/widgets/section_card.dart';
import '../rooms/booking_selection.dart';
import '../search/search_provider.dart';
import 'checkout_pricing.dart';
import 'order.dart';
import 'widgets/booking_cards.dart';
import 'widgets/checkout_sheets.dart';
import 'widgets/form_fields.dart';
import 'widgets/payment_cards.dart';

/// Поле формы вместе с контроллером, фокусом и правилом проверки.
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

  void _pay(
    BookingSelection selection,
    CheckoutPrice price,
    DateTime from,
    DateTime to,
  ) {
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

    ref
        .read(orderProvider.notifier)
        .place(
          Order(
            selection: selection,
            checkIn: from,
            checkOut: to,
            guestNames: [
              for (var i = 0; i < _surnames.length; i++)
                '${_surnames[i].controller.text.trim()} '
                    '${_names[i].controller.text.trim()}',
            ],
            email: _emailSpec.controller.text.trim(),
            phone: _phoneSpec.controller.text.trim(),
            total: price.total,
            paidNow: _mode == PayMode.split ? price.splitPart : price.total,
            payMethod: payMethods[_method].label,
            lateCheckout: _lateCheckout,
            number:
                'TL-${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}',
          ),
        );
    context.go(Routes.confirmation);
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
    final details = detailsFor(hotel);
    final price = CheckoutPrice(
      shownTotal: offer.price * params.nights,
      discountPercent: offer.discountPercent,
      lateCheckout: _lateCheckout,
      lateCheckoutPrice: (hotel.price * 1.1 / 10).round() * 10,
      promoPercent: _promo == null ? 0 : promoCodes[_promo]!,
    );
    final cancelText = offer.refundable
        ? 'Бесплатная отмена до '
              '${formatDayMonth(freeCancelUntil(params.checkIn, today))}'
        : 'Оплата не возвращается';
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
              hotel: hotel,
              address: '${params.displayCity}, ${hotel.street}',
              checkIn: from,
              checkOut: to,
              daysUntil: daysUntil,
              checkInTime: details.checkIn
                  .replaceAll('С ', '')
                  .replaceAll('\nдо ', ' - '),
              checkOutTime: details.checkOut
                  .replaceAll('С ', '')
                  .replaceAll('\nдо ', ' - '),
            ),
            RoomSummaryCard(
              room: selection.room,
              offer: offer,
              cancelText: cancelText,
            ),
            ServicesCard(
              priceLabel: 'До 23:00, ${formatPrice(price.lateCheckoutPrice)}',
              value: _lateCheckout,
              onChanged: (v) => setState(() => _lateCheckout = v),
            ),
            RulesCard(
              checkIn:
                  'Заезд ${details.checkIn.replaceAll('\n', ' ').replaceFirst('С', 'с')}',
              checkOut:
                  'Выезд ${details.checkOut.replaceAll('\n', ' ').replaceFirst('С', 'с')}',
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
                  Text(cancelText, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 26),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FilledButton(
                        key: const Key('checkout_pay'),
                        onPressed: () => _pay(selection, price, from, to),
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
                            Text(
                              'Оплатить ${formatPrice(payTitle)}',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              payMethods[_method].label,
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
